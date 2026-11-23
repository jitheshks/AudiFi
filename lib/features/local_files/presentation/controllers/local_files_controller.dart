import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../data/datasources/local_files_local_data_source.dart';
import '../../domain/entities/local_audio_track.dart';

/// Notifier managing user-imported local audio files.
class LocalFilesController extends Notifier<List<LocalAudioTrack>> {
  LocalFilesLocalDataSource get _dataSource =>
      ref.read(localFilesLocalDataSourceProvider);

  @override
  List<LocalAudioTrack> build() {
    unawaited(_loadTracks());
    return const [];
  }

  Future<void> _loadTracks() async {
    await _dataSource.init();
    state = _dataSource.getLocalTracks();
  }

  /// Opens the system file picker allowing the user to select one or more
  /// audio files (`mp3`, `m4a`, `flac`, `wav`, `aac`, `ogg`) to import into Audifi.
  ///
  /// Returns the number of files successfully imported.
  Future<int> pickAndImportAudioFiles() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'm4a', 'flac', 'wav', 'aac', 'ogg'],
      );

      if (files.isEmpty) {
        return 0;
      }

      int importedCount = 0;
      for (final file in files) {
        if (file.path != null && file.path!.isNotEmpty) {
          try {
            final size = file.lengthSync() ?? (await file.length()) ?? 0;
            await _dataSource.importAudioFile(
              sourcePath: file.path!,
              originalName: file.name,
              sizeBytes: size,
            );
            importedCount++;
          } catch (e) {
            AppLogger.warning(
              'Failed to import local file ${file.name}: $e',
              tag: 'LocalFiles',
            );
          }
        }
      }

      // Refresh state
      state = _dataSource.getLocalTracks();
      return importedCount;
    } catch (e) {
      AppLogger.error('FilePicker error: $e', tag: 'LocalFiles');
      return 0;
    }
  }

  /// Removes [trackId] from Audifi's managed collection.
  /// The original source file on device storage is preserved.
  Future<void> removeTrack(String trackId) async {
    await _dataSource.removeLocalTrack(trackId);
    state = _dataSource.getLocalTracks();
  }

  /// Clears all imported local tracks from Audifi.
  Future<void> clearAll() async {
    await _dataSource.clearAll();
    state = const [];
  }

  /// Refreshes the local tracks list from disk.
  Future<void> refresh() async {
    await _loadTracks();
  }
}

/// Provider for [LocalFilesController].
final localFilesControllerProvider =
    NotifierProvider<LocalFilesController, List<LocalAudioTrack>>(
      LocalFilesController.new,
    );

/// Convenience provider exposing the list of underlying domain [Track]s
/// representing all imported local files.
final localTracksProvider = Provider<List<Track>>((ref) {
  final localTracks = ref.watch(localFilesControllerProvider);
  return localTracks.map((lt) => lt.track).toList();
});

/// Computes the total on-disk storage size occupied by Audifi's local audio file copies.
final localFilesStorageBytesProvider = FutureProvider<int>((ref) async {
  ref.watch(localFilesControllerProvider);
  final ds = ref.watch(localFilesLocalDataSourceProvider);
  return ds.getTotalStorageBytes();
});
