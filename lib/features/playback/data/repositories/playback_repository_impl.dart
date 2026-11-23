import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../downloads/data/datasources/download_local_data_source.dart';
import '../../../local_files/data/datasources/local_files_local_data_source.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../domain/repositories/playback_repository.dart';
import '../datasources/next_track_url_cache.dart';
import '../datasources/queue_local_data_source.dart';
import '../datasources/stream_remote_data_source.dart';

/// Concrete implementation of [PlaybackRepository] coordinating network resolution,
/// predictive next-track caching, offline download lookup, and local queue persistence.
class PlaybackRepositoryImpl implements PlaybackRepository {
  PlaybackRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.downloadLocalDataSource,
    this.localFilesLocalDataSource,
    NextTrackUrlCache? predictionCache,
  }) : _predictionCache = predictionCache ?? NextTrackUrlCache();

  final StreamRemoteDataSource remoteDataSource;
  final QueueLocalDataSource localDataSource;
  final DownloadLocalDataSource? downloadLocalDataSource;
  final LocalFilesLocalDataSource? localFilesLocalDataSource;
  final NextTrackUrlCache _predictionCache;

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    // 1. Check if track is downloaded locally on device
    if (downloadLocalDataSource != null &&
        downloadLocalDataSource!.isTrackDownloaded(trackId)) {
      final dt = downloadLocalDataSource!.getDownloadedTrack(trackId);
      if (dt != null) {
        final file = File(dt.localFilePath);
        if (file.existsSync() && file.lengthSync() > 0) {
          AppLogger.info(
            'Resolved audio source from local offline download: ${dt.localFilePath}',
            tag: 'Playback',
          );
          return dt.localFilePath;
        }
      }
    }

    // 1b. Check if track is an imported local audio file
    if (localFilesLocalDataSource != null &&
        localFilesLocalDataSource!.isLocalFile(trackId)) {
      final lt = localFilesLocalDataSource!.getLocalTrack(trackId);
      if (lt != null) {
        final file = File(lt.localFilePath);
        if (file.existsSync() && file.lengthSync() > 0) {
          AppLogger.info(
            'Resolved audio source from local imported file: ${lt.localFilePath}',
            tag: 'Playback',
          );
          return lt.localFilePath;
        }
      }
    }

    // 2. Check predictive cache
    final cachedUrl = _predictionCache.consume(trackId);
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      AppLogger.info(
        'Next track stream URL cache hit: $trackId',
        tag: 'Playback',
      );
      return cachedUrl;
    }

    // 2b. Check historical LRU stream cache (replays, previous tracks, recent tracks)
    final historicalUrl = _predictionCache.getHistoricalUrl(trackId);
    if (historicalUrl != null && historicalUrl.isNotEmpty) {
      AppLogger.info(
        'Stream URL historical cache hit: $trackId',
        tag: 'Playback',
      );
      return historicalUrl;
    }

    AppLogger.debug(
      'Next track stream URL cache miss: $trackId (falling back to normal resolution)',
      tag: 'Playback',
    );
    final resolvedUrl = await remoteDataSource.getStreamUrl(
      trackId,
      cancelToken: cancelToken,
    );
    _predictionCache.putHistoricalUrl(trackId, resolvedUrl);
    return resolvedUrl;
  }

  @override
  Future<void> prefetchStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    // If track is already downloaded locally or is a local file, skip network prefetch
    if (downloadLocalDataSource != null &&
        downloadLocalDataSource!.isTrackDownloaded(trackId)) {
      AppLogger.debug(
        'Prefetch skipped; track is already downloaded: $trackId',
        tag: 'Playback',
      );
      return;
    }
    if (localFilesLocalDataSource != null &&
        localFilesLocalDataSource!.isLocalFile(trackId)) {
      AppLogger.debug(
        'Prefetch skipped; track is a local imported file: $trackId',
        tag: 'Playback',
      );
      return;
    }
    if (_predictionCache.has(trackId)) {
      AppLogger.debug(
        'Duplicate prediction skipped; track already cached: $trackId',
        tag: 'Playback',
      );
      return;
    }

    try {
      AppLogger.debug(
        'Prediction stream resolution started for: $trackId',
        tag: 'Playback',
      );
      final streamUrl = await remoteDataSource.getStreamUrl(
        trackId,
        cancelToken: cancelToken,
      );
      _predictionCache.put(trackId, streamUrl);
      AppLogger.debug(
        'Prediction stream resolution completed for: $trackId',
        tag: 'Playback',
      );
    } catch (e) {
      AppLogger.debug(
        'Prediction stream resolution failed for: $trackId ($e)',
        tag: 'Playback',
      );
    }
  }

  @override
  String? get currentPredictedTrackId => _predictionCache.currentTrackId;

  @override
  void invalidatePrediction({String reason = 'invalidated'}) {
    _predictionCache.clear(reason: reason);
  }

  @override
  bool hasPrediction(String trackId) => _predictionCache.has(trackId);

  @override
  Future<void> saveQueue({
    required List<Track> tracks,
    required int currentIndex,
  }) {
    return localDataSource.saveQueue(
      tracks: tracks,
      currentIndex: currentIndex,
    );
  }

  @override
  Future<({List<Track> tracks, int currentIndex})?> restoreQueue() {
    return localDataSource.restoreQueue();
  }

  @override
  Future<void> clearSavedQueue() {
    return localDataSource.clearQueue();
  }
}

/// Riverpod provider for [PlaybackRepository].
final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  final remote = ref.watch(streamRemoteDataSourceProvider);
  final local = ref.watch(queueLocalDataSourceProvider);
  final cache = ref.watch(nextTrackUrlCacheProvider);
  final downloads = ref.watch(downloadLocalDataSourceProvider);
  final localFiles = ref.watch(localFilesLocalDataSourceProvider);
  return PlaybackRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    downloadLocalDataSource: downloads,
    localFilesLocalDataSource: localFiles,
    predictionCache: cache,
  );
});
