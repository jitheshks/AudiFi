import 'package:dio/dio.dart';

import '../../../tracks/domain/entities/track.dart';

/// Pure domain repository contract abstracting stream resolution, next-track prediction,
/// and queue persistence.
abstract interface class PlaybackRepository {
  /// Resolves direct streamable audio URL for an Audius track.
  /// Uses cached next-track prediction if available, or fetches from remote network.
  Future<String> resolveStreamUrl(String trackId, {CancelToken? cancelToken});

  /// Asynchronously pre-resolves and caches the stream URL for the predicted next track.
  Future<void> prefetchStreamUrl(String trackId, {CancelToken? cancelToken});

  /// Returns the track ID of the current prediction in cache, if any.
  String? get currentPredictedTrackId;

  /// Invalidates any stored next-track prediction (e.g. when queue or repeat mode changes).
  void invalidatePrediction({String reason = 'invalidated'});

  /// Checks whether a valid pre-resolved URL is currently cached for [trackId].
  bool hasPrediction(String trackId);

  /// Persists current queue track state (track IDs and lightweight metadata)
  /// and active index across application sessions.
  Future<void> saveQueue({
    required List<Track> tracks,
    required int currentIndex,
  });

  /// Restores persisted queue state on application startup.
  Future<({List<Track> tracks, int currentIndex})?> restoreQueue();

  /// Clears persisted queue state from local storage.
  Future<void> clearSavedQueue();
}
