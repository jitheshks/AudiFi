import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../domain/entities/downloaded_track.dart';

/// Local data source managing persistent MP3 audio files on device storage
/// and metadata persistence in [SharedPreferences].
class DownloadLocalDataSource {
  DownloadLocalDataSource({required this.prefsAsync, this.customDownloadDir});

  final Future<SharedPreferences> prefsAsync;
  final String? customDownloadDir;

  static const String _keyDownloadedTracks = 'audifi_downloaded_tracks_v1';
  static const String _downloadsFolderName = 'audifi_downloads';

  Directory? _directory;
  final Map<String, DownloadedTrack> _cache = {};
  Future<void>? _initFuture;

  /// Resolves the dedicated directory for storing downloaded audio files.
  Future<Directory> get _downloadDir async {
    if (_directory != null) return _directory!;
    if (customDownloadDir != null) {
      _directory = Directory(customDownloadDir!);
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      _directory = Directory('${appDocDir.path}/$_downloadsFolderName');
    }
    if (!await _directory!.exists()) {
      await _directory!.create(recursive: true);
    }
    return _directory!;
  }

  /// Initializes the local storage: cleans up partial/orphaned `.tmp` files,
  /// loads saved tracks into the in-memory cache, and reconciles metadata with disk.
  Future<void> init() async {
    if (_initFuture != null) return _initFuture!;
    _initFuture = _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      final dir = await _downloadDir;
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.tmp')) {
            try {
              entity.deleteSync();
              AppLogger.debug(
                'Deleted orphaned temp file: ${entity.path}',
                tag: 'Downloads',
              );
            } catch (_) {}
          }
        }
      }

      final prefs = await prefsAsync;
      final raw = prefs.getString(_keyDownloadedTracks);
      _cache.clear();

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final validTracks = <DownloadedTrack>[];

        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            try {
              final track = DownloadedTrack.fromJson(item);
              final file = File(track.localFilePath);
              if (file.existsSync() && file.lengthSync() > 0) {
                _cache[track.track.id] = track;
                validTracks.add(track);
              } else {
                AppLogger.warning(
                  'Reconciled missing track on disk: ${track.track.title} (${track.localFilePath})',
                  tag: 'Downloads',
                );
              }
            } catch (_) {}
          }
        }

        if (validTracks.length != decoded.length) {
          await _persistTrackList(validTracks);
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Download storage initialization warning: $e',
        tag: 'Downloads',
      );
    }
  }

  /// Gets all successfully downloaded tracks stored on the device.
  List<DownloadedTrack> getDownloadedTracks() {
    return _cache.values
        .where((dt) => File(dt.localFilePath).existsSync())
        .toList();
  }

  /// Returns the downloaded track by [trackId], or null if not downloaded.
  DownloadedTrack? getDownloadedTrack(String trackId) {
    final dt = _cache[trackId];
    if (dt != null && File(dt.localFilePath).existsSync()) {
      return dt;
    }
    return null;
  }

  /// Whether track with [trackId] is fully downloaded and physical file exists.
  bool isTrackDownloaded(String trackId) {
    final dt = _cache[trackId];
    if (dt == null) return false;
    final file = File(dt.localFilePath);
    return file.existsSync() && file.lengthSync() > 0;
  }

  /// Saves a successfully completed download to persistent metadata and cache.
  Future<void> saveDownloadedTrack(DownloadedTrack downloadedTrack) async {
    await init();
    _cache[downloadedTrack.track.id] = downloadedTrack;
    await _persistTrackList(_cache.values.toList());
  }

  /// Deletes the local MP3 file for [trackId] and removes it from metadata and cache.
  Future<void> removeDownloadedTrack(String trackId) async {
    await init();
    final target = _cache.remove(trackId);
    if (target != null) {
      try {
        final file = File(target.localFilePath);
        if (await file.exists()) {
          await file.delete();
          AppLogger.info(
            'Deleted local audio file for track: ${target.track.title}',
            tag: 'Downloads',
          );
        }
      } catch (e) {
        AppLogger.warning(
          'Failed to delete audio file: ${target.localFilePath} ($e)',
          tag: 'Downloads',
        );
      }
      await _persistTrackList(_cache.values.toList());
    }
  }

  /// Clears all downloaded tracks, deleting all local files and metadata.
  Future<void> clearAll() async {
    await init();
    try {
      final dir = await _downloadDir;
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Failed deleting download files: $e', tag: 'Downloads');
    }
    _cache.clear();
    final prefs = await prefsAsync;
    await prefs.remove(_keyDownloadedTracks);
    AppLogger.info(
      'Cleared all downloaded tracks and metadata',
      tag: 'Downloads',
    );
  }

  /// Computes total storage size in bytes used by all downloaded audio files.
  Future<int> getTotalStorageBytes() async {
    try {
      final dir = await _downloadDir;
      if (!await dir.exists()) return 0;
      int total = 0;
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          total += entity.lengthSync();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Resolves the intended persistent path for [trackId].
  Future<String> getTargetFilePath(String trackId) async {
    final dir = await _downloadDir;
    return '${dir.path}/$trackId.mp3';
  }

  /// Resolves the temporary path used during download for atomic writing.
  Future<String> getTempFilePath(String trackId) async {
    final dir = await _downloadDir;
    return '${dir.path}/$trackId.tmp';
  }

  Future<void> _persistTrackList(List<DownloadedTrack> tracks) async {
    final prefs = await prefsAsync;
    final list = tracks.map((t) => t.toJson()).toList();
    await prefs.setString(_keyDownloadedTracks, jsonEncode(list));
  }
}

/// Provider for [DownloadLocalDataSource].
final downloadLocalDataSourceProvider = Provider<DownloadLocalDataSource>((
  ref,
) {
  final prefsAsync = ref.watch(sharedPreferencesAsyncProvider);
  final ds = DownloadLocalDataSource(prefsAsync: prefsAsync);
  // Non-blocking initialization
  ds.init();
  return ds;
});
