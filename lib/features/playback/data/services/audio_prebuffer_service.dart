import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import 'prebuffer_metadata.dart';

/// Service responsible for proactively prebuffering a bounded prefix of audio bytes
/// (default 768 KiB / ~19s of audio) for predicted next tracks into temporary storage.
class AudioPrebufferService {
  AudioPrebufferService({
    required this.dioClient,
    this.targetBytes = defaultPrebufferBytes,
    Directory? customStorageDirectory,
  }) : _customStorageDir = customStorageDirectory;

  /// Default target size for audio prebuffering: 768 KiB (786,432 bytes).
  static const int defaultPrebufferBytes = 768 * 1024;

  /// Maximum number of completed prebuffered tracks retained on disk.
  static const int maxRetainedPrebuffers = 2;

  final DioClient dioClient;
  final int targetBytes;
  final Directory? _customStorageDir;

  final Map<String, PrebufferMetadata> _metadataCache = {};
  final Map<String, CancelToken> _activeDownloads = {};
  Directory? _storageDir;

  /// Resolves the storage directory for prebuffered audio files.
  Future<Directory> get storageDirectory async {
    final custom = _customStorageDir;
    if (custom != null) return custom;
    final cached = _storageDir;
    if (cached != null) return cached;

    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/audifi_prebuffer');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _storageDir = dir;
    return dir;
  }

  /// Proactively downloads up to [targetBytes] of audio for [trackId] from [streamUrl].
  /// Writes chunks into `<trackId>.part` and atomically promotes to `<trackId>.buf` on completion.
  Future<PrebufferMetadata?> prebufferTrack(
    String trackId,
    String streamUrl, {
    CancelToken? cancelToken,
  }) async {
    if (trackId.isEmpty || streamUrl.isEmpty) return null;

    // 1. If already prebuffered and valid, return existing metadata
    final existing = getPrebuffer(trackId);
    if (existing != null && existing.isValid) {
      AppLogger.debug(
        'AudioPrebufferService: prebuffer already exists and is valid for $trackId (${existing.bufferedBytes} bytes)',
        tag: 'Playback',
      );
      return existing;
    }

    // 2. Cancel any existing download for this track
    cancelPrebuffer(trackId, reason: 'superseded_by_new_request');

    // 3. Prepare task cancel token
    final taskCancelToken = cancelToken ?? CancelToken();
    _activeDownloads[trackId] = taskCancelToken;

    final dir = await storageDirectory;
    final sanitizedId = _sanitizeTrackId(trackId);
    final partFile = File('${dir.path}/$sanitizedId.part');
    final bufFile = File('${dir.path}/$sanitizedId.buf');

    // Clean up any stale partial or completed files before starting fresh
    if (partFile.existsSync()) {
      try {
        partFile.deleteSync();
      } catch (_) {}
    }

    IOSink? sink;
    try {
      AppLogger.info(
        'AudioPrebufferService: starting prebuffer for $trackId (target: $targetBytes bytes) from $streamUrl',
        tag: 'Playback',
      );

      final response = await dioClient.rawDio.get<ResponseBody>(
        streamUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Range': 'bytes=0-${targetBytes - 1}', 'Accept': '*/*'},
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status != null && status < 400,
        ),
        cancelToken: taskCancelToken,
      );

      final statusCode = response.statusCode ?? 200;
      final headers = response.headers;
      final contentRange = headers.value('content-range');
      final contentLengthHeader = headers.value('content-length');
      final contentType = headers.value('content-type') ?? 'audio/mpeg';

      int? totalContentLength;
      if (contentRange != null && contentRange.contains('/')) {
        final totalStr = contentRange.split('/').last.trim();
        totalContentLength = int.tryParse(totalStr);
      } else if (contentLengthHeader != null && statusCode == 200) {
        totalContentLength = int.tryParse(contentLengthHeader);
      }

      AppLogger.debug(
        'AudioPrebufferService: HTTP $statusCode response for $trackId (Content-Range: $contentRange, total: $totalContentLength)',
        tag: 'Playback',
      );

      sink = partFile.openWrite(mode: FileMode.writeOnly);
      int bytesWritten = 0;

      await for (final chunk in response.data!.stream) {
        if (taskCancelToken.isCancelled) {
          throw const CancellationException();
        }

        final remaining = targetBytes - bytesWritten;
        if (remaining <= 0) break;

        if (chunk.length > remaining) {
          // Strictly enforce maximum byte limit: never exceed targetBytes
          sink.add(chunk.sublist(0, remaining));
          bytesWritten += remaining;
          break;
        } else {
          sink.add(chunk);
          bytesWritten += chunk.length;
        }

        if (bytesWritten >= targetBytes) {
          break;
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (taskCancelToken.isCancelled) {
        throw const CancellationException();
      }

      if (bytesWritten == 0) {
        if (partFile.existsSync()) partFile.deleteSync();
        return null;
      }

      // Promote .part to .buf atomically
      if (bufFile.existsSync()) {
        bufFile.deleteSync();
      }
      await partFile.rename(bufFile.path);

      final metadata = PrebufferMetadata(
        trackId: trackId,
        filePath: bufFile.path,
        bufferedBytes: bytesWritten,
        totalBytes: totalContentLength,
        streamUrl: streamUrl,
        createdAt: DateTime.now(),
        contentType: contentType,
        isComplete: bytesWritten >= targetBytes,
      );

      _metadataCache[trackId] = metadata;
      await _enforceCacheRetentionLimit();

      AppLogger.info(
        'AudioPrebufferService: successfully prebuffered $bytesWritten bytes for $trackId -> ${bufFile.path}',
        tag: 'Playback',
      );

      return metadata;
    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (partFile.existsSync()) {
        try {
          partFile.deleteSync();
        } catch (_) {}
      }

      if (taskCancelToken.isCancelled || e is CancellationException) {
        AppLogger.debug(
          'AudioPrebufferService: prebuffering cancelled for $trackId',
          tag: 'Playback',
        );
      } else {
        AppLogger.warning(
          'AudioPrebufferService: prebuffering failed for $trackId ($e)',
          tag: 'Playback',
        );
      }
      return null;
    } finally {
      _activeDownloads.remove(trackId);
    }
  }

  /// Returns cached [PrebufferMetadata] for [trackId] if valid and not expired.
  PrebufferMetadata? getPrebuffer(String trackId) {
    final meta = _metadataCache[trackId];
    if (meta == null) {
      // Check disk directly in case metadata was evicted from memory
      return _loadFromDisk(trackId);
    }
    if (!meta.isValid || meta.isExpired()) {
      evict(trackId);
      return null;
    }
    return meta;
  }

  /// Whether a valid, complete prebuffer exists for [trackId].
  bool hasPrebuffer(String trackId) => getPrebuffer(trackId) != null;

  /// Returns the prebuffered audio [File] for [trackId], if available.
  File? getPrebufferFile(String trackId) => getPrebuffer(trackId)?.file;

  /// Cancels any active in-flight prebuffer download for [trackId].
  void cancelPrebuffer(String trackId, {String reason = 'cancelled'}) {
    final token = _activeDownloads.remove(trackId);
    if (token != null && !token.isCancelled) {
      token.cancel(reason);
      AppLogger.debug(
        'AudioPrebufferService: cancelled download for $trackId (reason: $reason)',
        tag: 'Playback',
      );
    }
  }

  /// Cancels all active in-flight downloads.
  void cancelAll({String reason = 'cancelled'}) {
    for (final entry in _activeDownloads.entries) {
      if (!entry.value.isCancelled) {
        entry.value.cancel(reason);
      }
    }
    _activeDownloads.clear();
    AppLogger.debug(
      'AudioPrebufferService: cancelled all active downloads (reason: $reason)',
      tag: 'Playback',
    );
  }

  /// Evicts prebuffered files and metadata for [trackId].
  Future<void> evict(String trackId) async {
    cancelPrebuffer(trackId, reason: 'evicted');
    _metadataCache.remove(trackId);

    try {
      final dir = await storageDirectory;
      final sanitizedId = _sanitizeTrackId(trackId);
      final buf = File('${dir.path}/$sanitizedId.buf');
      final part = File('${dir.path}/$sanitizedId.part');
      if (buf.existsSync()) buf.deleteSync();
      if (part.existsSync()) part.deleteSync();
    } catch (_) {}
  }

  /// Clears all stored prebuffers and deletes temporary cache files.
  Future<void> clearAll() async {
    cancelAll(reason: 'cleared');
    _metadataCache.clear();

    try {
      final dir = await storageDirectory;
      if (dir.existsSync()) {
        final files = dir.listSync();
        for (final file in files) {
          if (file is File) {
            file.deleteSync();
          }
        }
      }
    } catch (_) {}
  }

  /// Removes any stale orphaned `.part` files left by interrupted downloads.
  Future<void> cleanOrphanedParts() async {
    try {
      final dir = await storageDirectory;
      if (dir.existsSync()) {
        final entries = dir.listSync();
        for (final entry in entries) {
          if (entry is File && entry.path.endsWith('.part')) {
            entry.deleteSync();
          }
        }
      }
    } catch (_) {}
  }

  PrebufferMetadata? _loadFromDisk(String trackId) {
    if (_storageDir == null && _customStorageDir == null) return null;
    final dir = _customStorageDir ?? _storageDir!;
    final sanitizedId = _sanitizeTrackId(trackId);
    final buf = File('${dir.path}/$sanitizedId.buf');
    if (buf.existsSync() && buf.lengthSync() > 0) {
      final meta = PrebufferMetadata(
        trackId: trackId,
        filePath: buf.path,
        bufferedBytes: buf.lengthSync(),
        streamUrl: '',
        createdAt: buf.lastModifiedSync(),
      );
      _metadataCache[trackId] = meta;
      return meta;
    }
    return null;
  }

  Future<void> _enforceCacheRetentionLimit() async {
    if (_metadataCache.length <= maxRetainedPrebuffers) return;

    // Evict oldest entries
    final sortedKeys = _metadataCache.keys.toList()
      ..sort(
        (a, b) => _metadataCache[a]!.createdAt.compareTo(
          _metadataCache[b]!.createdAt,
        ),
      );

    while (sortedKeys.length > maxRetainedPrebuffers) {
      final oldestTrackId = sortedKeys.removeAt(0);
      await evict(oldestTrackId);
    }
  }

  String _sanitizeTrackId(String id) {
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }
}

/// Riverpod provider for [AudioPrebufferService].
final audioPrebufferServiceProvider = Provider<AudioPrebufferService>((ref) {
  final client = ref.watch(dioClientProvider);
  final service = AudioPrebufferService(dioClient: client);
  ref.onDispose(() => service.cancelAll(reason: 'provider_disposed'));
  return service;
});
