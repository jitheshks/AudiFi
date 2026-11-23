import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../domain/entities/local_audio_track.dart';

/// Local data source managing user-imported local audio files copied into
/// app-managed storage and metadata persisted in [SharedPreferences].
class LocalFilesLocalDataSource {
  LocalFilesLocalDataSource({required this.prefsAsync, this.customStorageDir});

  final Future<SharedPreferences> prefsAsync;
  final String? customStorageDir;

  static const String _keyLocalTracks = 'audifi_local_tracks_v1';
  static const String _folderName = 'audifi_local_files';
  static int _importSequence = 0;

  Directory? _directory;
  final Map<String, LocalAudioTrack> _cache = {};
  Future<void>? _initFuture;

  /// Resolves the dedicated directory for storing imported audio files.
  Future<Directory> get _localFilesDir async {
    if (_directory != null) return _directory!;
    if (customStorageDir != null) {
      _directory = Directory(customStorageDir!);
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      _directory = Directory('${appDocDir.path}/$_folderName');
    }
    if (!await _directory!.exists()) {
      await _directory!.create(recursive: true);
    }
    return _directory!;
  }

  /// Initializes the local storage: reconciles metadata with disk,
  /// loads saved tracks into the in-memory cache, and removes stale entries.
  Future<void> init() async {
    if (_initFuture != null) return _initFuture!;
    _initFuture = _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    try {
      final dir = await _localFilesDir;
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.tmp')) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      }

      final prefs = await prefsAsync;
      final raw = prefs.getString(_keyLocalTracks);
      _cache.clear();

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final validTracks = <LocalAudioTrack>[];

        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            try {
              final localTrack = LocalAudioTrack.fromJson(item);
              final file = File(localTrack.localFilePath);
              if (file.existsSync() && file.lengthSync() > 0) {
                _cache[localTrack.track.id] = localTrack;
                validTracks.add(localTrack);
              } else {
                AppLogger.warning(
                  'Reconciled missing local file on disk: ${localTrack.track.title} (${localTrack.localFilePath})',
                  tag: 'LocalFiles',
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
        'Local files storage initialization warning: $e',
        tag: 'LocalFiles',
      );
    }
  }

  /// Gets all successfully imported local audio tracks.
  List<LocalAudioTrack> getLocalTracks() {
    return _cache.values
        .where((lt) => File(lt.localFilePath).existsSync())
        .toList();
  }

  /// Returns the imported track by [trackId], or null if not found.
  LocalAudioTrack? getLocalTrack(String trackId) {
    final lt = _cache[trackId];
    if (lt != null && File(lt.localFilePath).existsSync()) {
      return lt;
    }
    return null;
  }

  /// Whether track with [trackId] is an imported local file.
  bool isLocalFile(String trackId) {
    final lt = _cache[trackId];
    if (lt == null) return false;
    final file = File(lt.localFilePath);
    return file.existsSync() && file.lengthSync() > 0;
  }

  /// Imports an audio file by copying it into app-managed storage,
  /// extracting metadata, and saving to persistent storage.
  ///
  /// This guarantees that:
  /// 1. SAF URI permissions cannot expire across app restarts.
  /// 2. The user's original source file is never modified or deleted.
  /// 3. Offline playback remains 100% reliable.
  Future<LocalAudioTrack> importAudioFile({
    required String sourcePath,
    required String originalName,
    int? sizeBytes,
  }) async {
    await init();
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw FileSystemException('Source audio file does not exist', sourcePath);
    }

    final realSize = sizeBytes ?? sourceFile.lengthSync();

    // Parse extension
    final dotIndex = originalName.lastIndexOf('.');
    final ext = (dotIndex != -1 && dotIndex < originalName.length - 1)
        ? originalName.substring(dotIndex + 1).toLowerCase()
        : 'mp3';

    // Parse base name
    final baseName = dotIndex != -1
        ? originalName.substring(0, dotIndex)
        : originalName;

    // Parse title and artist from "Artist - Title" pattern if present
    String title = baseName;
    String artist = 'Local Artist';
    if (baseName.contains(' - ')) {
      final parts = baseName.split(' - ');
      if (parts.length >= 2) {
        artist = parts[0].trim();
        title = parts.sublist(1).join(' - ').trim();
      }
    }

    // Clean title
    title = title.replaceAll('_', ' ').trim();
    if (title.isEmpty) title = 'Untitled Track';

    // Unique track identifier
    final trackId =
        'local_${baseName.hashCode.abs()}_${DateTime.now().microsecondsSinceEpoch}_${++_importSequence}';

    final dir = await _localFilesDir;
    final destPath = '${dir.path}/$trackId.$ext';
    final destFile = File(destPath);

    // Copy to app-managed storage
    await sourceFile.copy(destPath);

    final track = Track(
      id: trackId,
      title: title,
      duration: 0,
      user: User(id: 'user_$trackId', name: artist, handle: 'local'),
      isStreamable: true,
      isDownloadable: false,
    );

    final localAudioTrack = LocalAudioTrack(
      track: track,
      localFilePath: destPath,
      fileSizeBytes: realSize > 0 ? realSize : destFile.lengthSync(),
      importedAt: DateTime.now(),
      fileExtension: ext,
    );

    _cache[trackId] = localAudioTrack;
    await _persistTrackList(_cache.values.toList());

    AppLogger.info(
      'Imported local track "${track.title}" by "$artist" ($destPath)',
      tag: 'LocalFiles',
    );

    return localAudioTrack;
  }

  /// Removes [trackId] from Audifi's managed collection and deletes the local copy.
  /// Note: The original file on the user's device remains completely untouched!
  Future<void> removeLocalTrack(String trackId) async {
    await init();
    final target = _cache.remove(trackId);
    if (target != null) {
      try {
        final file = File(target.localFilePath);
        if (await file.exists()) {
          await file.delete();
          AppLogger.info(
            'Deleted app-managed copy of local file: ${target.track.title}',
            tag: 'LocalFiles',
          );
        }
      } catch (e) {
        AppLogger.warning(
          'Failed deleting local audio copy: ${target.localFilePath} ($e)',
          tag: 'LocalFiles',
        );
      }
      await _persistTrackList(_cache.values.toList());
    }
  }

  /// Clears all imported local tracks and deletes their app-managed copies.
  Future<void> clearAll() async {
    await init();
    try {
      final dir = await _localFilesDir;
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
      AppLogger.warning('Failed deleting local files: $e', tag: 'LocalFiles');
    }
    _cache.clear();
    final prefs = await prefsAsync;
    await prefs.remove(_keyLocalTracks);
    AppLogger.info('Cleared all local tracks from Audifi', tag: 'LocalFiles');
  }

  /// Computes total storage size in bytes used by all imported local audio files.
  Future<int> getTotalStorageBytes() async {
    try {
      final dir = await _localFilesDir;
      if (!await dir.exists()) return 0;
      int total = 0;
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          total += entity.lengthSync();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _persistTrackList(List<LocalAudioTrack> tracks) async {
    final prefs = await prefsAsync;
    final list = tracks.map((t) => t.toJson()).toList();
    await prefs.setString(_keyLocalTracks, jsonEncode(list));
  }
}

/// Provider for [LocalFilesLocalDataSource].
final localFilesLocalDataSourceProvider = Provider<LocalFilesLocalDataSource>((
  ref,
) {
  final prefsAsync = ref.watch(sharedPreferencesAsyncProvider);
  final ds = LocalFilesLocalDataSource(prefsAsync: prefsAsync);
  ds.init();
  return ds;
});
