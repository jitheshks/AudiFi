import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/device/device_info_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/permissions/permission_providers.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../data/datasources/download_local_data_source.dart';
import '../../data/datasources/download_remote_data_source.dart';
import '../../domain/entities/download_progress.dart';
import '../../domain/entities/downloaded_track.dart';
import '../../domain/entities/track_download_permission.dart';

export '../../domain/entities/track_download_permission.dart';

/// Provider exposing the list of currently downloaded tracks.
final downloadedTracksProvider =
    NotifierProvider<DownloadedTracksNotifier, List<DownloadedTrack>>(
      DownloadedTracksNotifier.new,
    );

class DownloadedTracksNotifier extends Notifier<List<DownloadedTrack>> {
  @override
  List<DownloadedTrack> build() {
    final local = ref.watch(downloadLocalDataSourceProvider);
    local.init().then((_) {
      state = local.getDownloadedTracks();
    });
    return local.getDownloadedTracks();
  }

  void refresh() {
    final local = ref.read(downloadLocalDataSourceProvider);
    state = local.getDownloadedTracks();
  }
}

/// Provider checking whether a specific track is downloaded.
final isTrackDownloadedProvider = Provider.family<bool, String>((ref, trackId) {
  final downloaded = ref.watch(downloadedTracksProvider);
  return downloaded.any((dt) => dt.track.id == trackId);
});

/// Provider returning active download progress for [trackId].
final downloadProgressProvider = Provider.family<DownloadProgress?, String>((
  ref,
  trackId,
) {
  final progressMap = ref.watch(downloadControllerProvider);
  return progressMap[trackId];
});

/// Provider determining creator download permission for a given [Track].
final trackDownloadPermissionProvider = FutureProvider.autoDispose
    .family<TrackDownloadPermission, Track>((ref, track) async {
      if (track.isDownloadGated) {
        return TrackDownloadPermission.gated;
      }
      if (track.isDownloadable != null) {
        return track.isDownloadable!
            ? TrackDownloadPermission.authorized
            : TrackDownloadPermission.disabled;
      }
      // Permission unknown/missing: verify through supported official API
      final remote = ref.watch(downloadRemoteDataSourceProvider);
      return remote.verifyDownloadPermission(track.id);
    });

/// Provider returning total storage size used by downloads in formatted string.
final downloadStorageSizeProvider = FutureProvider<String>((ref) async {
  // Watch downloadedTracksProvider to re-calculate whenever downloads change
  ref.watch(downloadedTracksProvider);
  final local = ref.watch(downloadLocalDataSourceProvider);
  final bytes = await local.getTotalStorageBytes();
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
});

/// Controller managing track downloads, concurrency queue, progress notifications,
/// cancellations, and disk persistence.
class DownloadController extends Notifier<Map<String, DownloadProgress>> {
  final Map<String, CancelToken> _cancelTokens = {};
  final List<Track> _downloadQueue = [];
  static const int _maxConcurrentDownloads = 2;
  int _activeDownloadsCount = 0;

  @override
  Map<String, DownloadProgress> build() {
    ref.onDispose(() {
      for (final token in _cancelTokens.values) {
        token.cancel('Controller disposed');
      }
      _cancelTokens.clear();
      _downloadQueue.clear();
    });
    return {};
  }

  /// Initiates downloading [track] for offline playback.
  Future<void> downloadTrack(Track track) async {
    final local = ref.read(downloadLocalDataSourceProvider);
    if (local.isTrackDownloaded(track.id)) {
      AppLogger.debug(
        'Track ${track.title} is already downloaded',
        tag: 'Downloads',
      );
      return;
    }

    final currentProgress = state[track.id];
    if (currentProgress != null &&
        (currentProgress.isDownloading || currentProgress.isQueued)) {
      return;
    }

    // Pre-flight check: reject gated tracks immediately without unnecessary network calls
    if (track.isDownloadGated) {
      AppLogger.warning(
        'Download rejected: Track "${track.title}" is gated behind access/purchase.',
        tag: 'Downloads',
      );
      _updateProgress(
        track.id,
        DownloadProgress(
          trackId: track.id,
          status: DownloadStatus.failed,
          errorMessage: 'This download requires creator access.',
        ),
      );
      return;
    }

    // Pre-flight check: reject creator-disabled tracks immediately
    if (track.isDownloadable == false) {
      AppLogger.warning(
        'Download rejected: Track "${track.title}" is not downloadable by creator settings.',
        tag: 'Downloads',
      );
      _updateProgress(
        track.id,
        DownloadProgress(
          trackId: track.id,
          status: DownloadStatus.failed,
          errorMessage: "Downloads aren't available for this track.",
        ),
      );
      return;
    }

    // Pre-flight check: reject if device has no connection
    final networkState = ref.read(networkStateProvider);
    if (networkState.status == NetworkStatus.none ||
        networkState.status == NetworkStatus.connectedWithoutInternet) {
      AppLogger.warning(
        'Download rejected: Device is offline.',
        tag: 'Downloads',
      );
      _updateProgress(
        track.id,
        DownloadProgress(
          trackId: track.id,
          status: DownloadStatus.failed,
          errorMessage: 'No internet connection. Please check your network and try again.',
        ),
      );
      return;
    }

    // Verify platform permissions (e.g. notifications on Android 13+)
    await _ensureDevicePermissions();

    if (_activeDownloadsCount >= _maxConcurrentDownloads) {
      _downloadQueue.add(track);
      _updateProgress(
        track.id,
        DownloadProgress(trackId: track.id, status: DownloadStatus.queued),
      );
      AppLogger.info(
        'Queued download for: ${track.title} (Queue size: ${_downloadQueue.length})',
        tag: 'Downloads',
      );
      return;
    }

    await _executeDownload(track);
  }

  Future<void> _executeDownload(Track track) async {
    _activeDownloadsCount++;
    final cancelToken = CancelToken();
    _cancelTokens[track.id] = cancelToken;

    _updateProgress(
      track.id,
      DownloadProgress(trackId: track.id, status: DownloadStatus.downloading),
    );

    final local = ref.read(downloadLocalDataSourceProvider);
    final tempPath = await local.getTempFilePath(track.id);
    final finalPath = await local.getTargetFilePath(track.id);

    try {
      AppLogger.info(
        'Resolving official creator-authorized download URL for: ${track.title}',
        tag: 'Downloads',
      );
      final downloadRemote = ref.read(downloadRemoteDataSourceProvider);
      final downloadUrl = await downloadRemote.getDownloadUrl(
        track.id,
        cancelToken: cancelToken,
      );

      AppLogger.info(
        'Starting authorized byte transfer for: ${track.title}',
        tag: 'Downloads',
      );
      final dio = downloadRemote.client.rawDio;

      await dio.download(
        downloadUrl,
        tempPath,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            _updateProgress(
              track.id,
              DownloadProgress(
                trackId: track.id,
                status: DownloadStatus.downloading,
                progress: progress,
                receivedBytes: received,
                totalBytes: total,
              ),
            );
          }
        },
      );

      // Verify temp file exists and has content
      final tempFile = File(tempPath);
      if (!await tempFile.exists() || tempFile.lengthSync() == 0) {
        throw Exception('Downloaded file is empty or missing');
      }

      // Atomic rename from .tmp to .mp3
      final finalFile = await tempFile.rename(finalPath);
      final fileSize = await finalFile.length();

      final downloadedTrack = DownloadedTrack(
        track: track,
        localFilePath: finalPath,
        fileSizeBytes: fileSize,
        downloadedAt: DateTime.now(),
      );

      await local.saveDownloadedTrack(downloadedTrack);
      ref.read(downloadedTracksProvider.notifier).refresh();

      _updateProgress(
        track.id,
        DownloadProgress(
          trackId: track.id,
          status: DownloadStatus.completed,
          progress: 1.0,
          receivedBytes: fileSize,
          totalBytes: fileSize,
        ),
      );

      AppLogger.info(
        'Successfully downloaded track: ${track.title} ($fileSize bytes)',
        tag: 'Downloads',
      );
    } on TrackNotDownloadableException catch (e) {
      AppLogger.warning(
        'Creator has disabled downloads for track: ${track.title} ($e)',
        tag: 'Downloads',
      );
      _updateProgress(
        track.id,
        DownloadProgress(
          trackId: track.id,
          status: DownloadStatus.failed,
          errorMessage: "Downloads aren't available for this track.",
        ),
      );
      _cleanupTemp(tempPath);
    } on TrackDownloadGatedException catch (e) {
      AppLogger.warning(
        'Download is gated for track: ${track.title} ($e)',
        tag: 'Downloads',
      );
      _updateProgress(
        track.id,
        DownloadProgress(
          trackId: track.id,
          status: DownloadStatus.failed,
          errorMessage: 'This download requires creator access.',
        ),
      );
      _cleanupTemp(tempPath);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        AppLogger.info(
          'Download cancelled for track: ${track.title}',
          tag: 'Downloads',
        );
        _updateProgress(
          track.id,
          DownloadProgress(trackId: track.id, status: DownloadStatus.cancelled),
        );
      } else {
        AppLogger.error(
          'Failed downloading track: ${track.title} ($e)',
          tag: 'Downloads',
          error: e,
        );
        _updateProgress(
          track.id,
          DownloadProgress(
            trackId: track.id,
            status: DownloadStatus.failed,
            errorMessage: 'Network error downloading track',
          ),
        );
      }
      _cleanupTemp(tempPath);
    } catch (e) {
      final isLowStorage =
          e is FileSystemException ||
          e.toString().toLowerCase().contains('no space') ||
          e.toString().toLowerCase().contains('storage');
      AppLogger.error(
        'Unexpected error downloading track: ${track.title} ($e)',
        tag: 'Downloads',
        error: e,
      );
      _updateProgress(
        track.id,
        DownloadProgress(
          trackId: track.id,
          status: DownloadStatus.failed,
          errorMessage: isLowStorage
              ? 'Insufficient storage space on device'
              : 'Download failed',
        ),
      );
      _cleanupTemp(tempPath);
    } finally {
      _cancelTokens.remove(track.id);
      _activeDownloadsCount--;
      _processNextInQueue();
    }
  }

  Future<bool> _ensureDevicePermissions() async {
    try {
      final deviceInfo = await ref
          .read(deviceInfoServiceProvider)
          .getDeviceInfo();
      if (deviceInfo.isAndroid &&
          (deviceInfo.sdkInt == null || deviceInfo.sdkInt! >= 33)) {
        final permService = ref.read(permissionServiceProvider);
        final notifGranted = await permService.isNotificationGranted();
        if (!notifGranted) {
          await permService.requestNotificationPermission();
        }
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  void _cleanupTemp(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) {
        f.deleteSync();
      }
    } catch (_) {}
  }

  void _processNextInQueue() {
    if (_downloadQueue.isNotEmpty &&
        _activeDownloadsCount < _maxConcurrentDownloads) {
      final nextTrack = _downloadQueue.removeAt(0);
      _executeDownload(nextTrack);
    }
  }

  /// Cancels an in-progress or queued download.
  void cancelDownload(String trackId) {
    _downloadQueue.removeWhere((t) => t.id == trackId);
    final token = _cancelTokens[trackId];
    if (token != null) {
      token.cancel('User cancelled download');
    } else {
      _updateProgress(
        trackId,
        DownloadProgress(trackId: trackId, status: DownloadStatus.cancelled),
      );
    }
  }

  /// Retries a failed or cancelled download.
  Future<void> retryDownload(Track track) async {
    cancelDownload(track.id);
    await downloadTrack(track);
  }

  /// Removes an existing downloaded track from device storage and metadata.
  Future<void> removeDownload(String trackId) async {
    cancelDownload(trackId);
    final local = ref.read(downloadLocalDataSourceProvider);
    await local.removeDownloadedTrack(trackId);
    ref.read(downloadedTracksProvider.notifier).refresh();

    final updated = Map<String, DownloadProgress>.from(state)..remove(trackId);
    state = updated;
  }

  /// Clears all downloaded tracks and frees device storage.
  Future<void> clearAllDownloads() async {
    for (final token in _cancelTokens.values) {
      token.cancel('Clear all downloads');
    }
    _cancelTokens.clear();
    _downloadQueue.clear();

    final local = ref.read(downloadLocalDataSourceProvider);
    await local.clearAll();
    ref.read(downloadedTracksProvider.notifier).refresh();
    state = {};
  }

  void _updateProgress(String trackId, DownloadProgress progress) {
    final updated = Map<String, DownloadProgress>.from(state);
    updated[trackId] = progress;
    state = updated;
  }
}

/// Main Riverpod provider for [DownloadController].
final downloadControllerProvider =
    NotifierProvider<DownloadController, Map<String, DownloadProgress>>(
      DownloadController.new,
    );

/// Computes total on-disk storage size occupied by all downloaded tracks.
final downloadStorageBytesProvider = FutureProvider<int>((ref) async {
  ref.watch(downloadedTracksProvider);
  final ds = ref.watch(downloadLocalDataSourceProvider);
  return ds.getTotalStorageBytes();
});
