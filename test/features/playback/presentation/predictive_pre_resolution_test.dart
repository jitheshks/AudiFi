import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:audifi/core/errors/app_exception.dart';
import 'package:audifi/features/playback/data/datasources/next_track_url_cache.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/entities/repeat_mode.dart';
import 'package:audifi/features/playback/domain/repositories/playback_repository.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/controllers/queue_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class PredictiveTestPlayerService implements AudioPlayerService {
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _processingController =
      StreamController<EngineProcessingState>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  String? loadedUrl;
  bool isPlayingState = false;
  Duration currentPositionValue = Duration.zero;
  Duration? currentDurationValue = const Duration(seconds: 100);

  bool failNextSetAudioUrl = false;
  int setUrlCallCount = 0;
  final List<String> loadedUrls = [];

  @override
  Stream<EngineProcessingState> get processingStateStream =>
      _processingController.stream;
  @override
  Stream<bool> get playingStream => _playingController.stream;
  @override
  Stream<Duration> get positionStream => _positionController.stream;
  @override
  Stream<Duration> get bufferedPositionStream => _bufferedController.stream;
  @override
  Stream<Duration?> get durationStream => _durationController.stream;
  @override
  Stream<void> get completedStream => _completedController.stream;

  @override
  Duration get currentPosition => currentPositionValue;
  @override
  Duration? get currentDuration => currentDurationValue;
  @override
  bool get isPlaying => isPlayingState;

  @override
  Future<void> setAudioUrl(String url) async {
    setUrlCallCount++;
    loadedUrls.add(url);
    if (failNextSetAudioUrl) {
      failNextSetAudioUrl = false;
      throw const PlaybackException(message: 'Failed to open stream source');
    }
    loadedUrl = url;
    _processingController.add(EngineProcessingState.buffering);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    setUrlCallCount++;
    if (failNextSetAudioUrl) {
      failNextSetAudioUrl = false;
      throw const PlaybackException(message: 'Failed to open stream source');
    }
    _processingController.add(EngineProcessingState.buffering);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> play() async {
    isPlayingState = true;
    _playingController.add(true);
    _processingController.add(EngineProcessingState.ready);
    currentPositionValue = const Duration(milliseconds: 100);
    _positionController.add(const Duration(milliseconds: 100));
  }

  @override
  Future<void> pause() async {
    isPlayingState = false;
    _playingController.add(false);
  }

  Duration? lastSeekPosition;

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
    currentPositionValue = position;
    _positionController.add(position);
  }

  @override
  Future<void> stop() async {
    isPlayingState = false;
    currentPositionValue = Duration.zero;
    _playingController.add(false);
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {
    await _positionController.close();
    await _bufferedController.close();
    await _durationController.close();
    await _playingController.close();
    await _processingController.close();
    await _completedController.close();
  }

  void emitPosition(Duration position) {
    currentPositionValue = position;
    _positionController.add(position);
  }

  void emitDuration(Duration duration) {
    currentDurationValue = duration;
    _durationController.add(duration);
  }
}

class PredictiveTestRepository implements PlaybackRepository {
  final NextTrackUrlCache cache = NextTrackUrlCache();
  final List<String> resolvedTrackIds = [];
  final List<String> prefetchedTrackIds = [];
  bool failPrefetch = false;
  int prefetchDelayMs = 0;
  int resolveDelayMs = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    if (resolveDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: resolveDelayMs));
    }
    if (cancelToken?.isCancelled == true) {
      throw const CancellationException();
    }
    final cached = cache.consume(trackId);
    if (cached != null) {
      return cached;
    }
    resolvedTrackIds.add(trackId);
    return 'https://creatornode.audius.co/tracks/$trackId.mp3';
  }

  @override
  Future<void> prefetchStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    if (prefetchDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: prefetchDelayMs));
    }
    if (cancelToken?.isCancelled == true) {
      throw const CancellationException();
    }
    if (failPrefetch) {
      throw const NetworkException(message: 'Simulated prefetch failure');
    }
    if (cache.has(trackId)) {
      return;
    }
    prefetchedTrackIds.add(trackId);
    cache.put(
      trackId,
      'https://creatornode.audius.co/tracks/$trackId.mp3?cached=true',
    );
  }

  @override
  String? get currentPredictedTrackId => cache.currentTrackId;

  @override
  bool hasPrediction(String trackId) => cache.has(trackId);

  int invalidateCount = 0;
  String? lastInvalidateReason;

  @override
  void invalidatePrediction({String? reason}) {
    invalidateCount++;
    lastInvalidateReason = reason;
    cache.clear(reason: reason ?? 'test_invalidation');
  }

  @override
  Future<void> saveQueue({
    required List<Track> tracks,
    required int currentIndex,
  }) async {}

  @override
  Future<({List<Track> tracks, int currentIndex})?> restoreQueue() async =>
      null;

  @override
  Future<void> clearSavedQueue() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2A: Predictive Next-Track Stream URL Pre-Resolution', () {
    late ProviderContainer container;
    late PredictiveTestPlayerService player;
    late PredictiveTestRepository repo;

    const track1 = Track(id: 'track_1', title: 'Track 1', duration: 100);
    const track2 = Track(id: 'track_2', title: 'Track 2', duration: 120);
    const track3 = Track(id: 'track_3', title: 'Track 3', duration: 140);

    setUp(() {
      player = PredictiveTestPlayerService();
      repo = PredictiveTestRepository();
      container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          playbackRepositoryProvider.overrideWithValue(repo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Scenario 1: Next-track URL pre-resolution triggered at 75% or 15s remaining', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repo.prefetchedTrackIds, isEmpty);

      // 70s on a 100s track: 70% elapsed, 30s remaining -> Neither condition met
      player.emitPosition(const Duration(seconds: 70));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.prefetchedTrackIds, isEmpty);

      // 75s on a 100s track: 75% elapsed -> Condition met!
      player.emitPosition(const Duration(seconds: 75));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.prefetchedTrackIds, contains('track_2'));
      expect(repo.hasPrediction('track_2'), isTrue);

      // Test 15s remaining trigger on short track
      const shortTrack = Track(
        id: 'short_track',
        title: 'Short Track',
        duration: 20,
      );
      await controller.playTrack(
        shortTrack,
        contextTracks: [shortTrack, track2],
      );
      repo.prefetchedTrackIds.clear();
      repo.invalidatePrediction();

      // At 3s: 15% elapsed, 17s remaining -> Neither
      player.emitPosition(const Duration(seconds: 3));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.prefetchedTrackIds, isEmpty);

      // At 6s: 30% elapsed (< 75%), but 14s remaining (<= 15s) -> Condition met!
      player.emitPosition(const Duration(seconds: 6));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.prefetchedTrackIds, contains('track_2'));
    });

    test('Scenario 2: Successful cache hit on Next press', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Trigger pre-resolution
      player.emitPosition(const Duration(seconds: 75));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.hasPrediction('track_2'), isTrue);

      repo.resolvedTrackIds.clear();
      await controller.skipToNext();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final tracer = PlaybackController.lastCompletedTracer;
      expect(tracer, isNotNull);
      expect(tracer!.hasMark('cache_hit'), isTrue);
      expect(tracer.hasMark('cache_miss'), isFalse);
      expect(player.loadedUrl, contains('cached=true'));
      // Remote resolveStreamUrl was bypassed due to cache hit
      expect(repo.resolvedTrackIds, isEmpty);
      // Cache was consumed (single-slot, single-use)
      expect(repo.hasPrediction('track_2'), isFalse);
    });

    test('Scenario 3: Cache miss fallback to normal resolution', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // No pre-resolution triggered; immediately press Next
      expect(repo.hasPrediction('track_2'), isFalse);

      await controller.skipToNext();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final tracer = PlaybackController.lastCompletedTracer;
      expect(tracer, isNotNull);
      expect(tracer!.hasMark('cache_miss'), isTrue);
      expect(tracer.hasMark('cache_hit'), isFalse);
      expect(repo.resolvedTrackIds, contains('track_2'));
    });

    test('Scenario 4: Background resolution failure does not affect active playback', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Enable simulated prefetch failure
      repo.failPrefetch = true;

      // Trigger pre-resolution threshold
      player.emitPosition(const Duration(seconds: 80));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Active playback must continue playing without entering error state
      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.playing),
      );
      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_1'),
      );
      expect(container.read(playbackControllerProvider).error, isNull);
    });

    test(
      'Scenario 5: Duplicate prediction prevention (single request per track)',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(
          track1,
          contextTracks: [track1, track2, track3],
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Send successive position ticks past 75%
        player.emitPosition(const Duration(seconds: 75));
        player.emitPosition(const Duration(seconds: 76));
        player.emitPosition(const Duration(seconds: 77));
        player.emitPosition(const Duration(seconds: 78));
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Only one prefetch request must have been dispatched
        expect(
          repo.prefetchedTrackIds.where((id) => id == 'track_2').length,
          equals(1),
        );
      },
    );

    test(
      'Scenario 6: Queue changes (add, remove, reorder) invalidate predictions',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(
          track1,
          contextTracks: [track1, track2, track3],
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Trigger prefetch for track2
        player.emitPosition(const Duration(seconds: 75));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(repo.hasPrediction('track_2'), isTrue);

        // Remove track2 from queue
        container.read(queueControllerProvider.notifier).removeFromQueue(1);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Stale prediction must be invalidated
        expect(repo.hasPrediction('track_2'), isFalse);
      },
    );

    test('Scenario 7: Shuffle toggle invalidates prediction', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Trigger prefetch for sequential next (track2)
      player.emitPosition(const Duration(seconds: 75));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.hasPrediction('track_2'), isTrue);

      final initialInvalidateCount = repo.invalidateCount;

      // Toggle shuffle
      controller.toggleShuffle();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Verification: Cache invalidation was triggered by shuffle change
      expect(repo.invalidateCount, greaterThan(initialInvalidateCount));
      expect(repo.lastInvalidateReason, contains('shuffle'));
    });

    test(
      'Scenario 8: Repeat One behavior (skips prediction, replays in-place)',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(
          track1,
          contextTracks: [track1, track2, track3],
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        await controller.setRepeatMode(RepeatMode.one);
        expect(controller.getPredictedNextTrack(), isNull);

        // Emit position past 75%
        player.emitPosition(const Duration(seconds: 80));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // No prefetch occurs in Repeat One
        expect(repo.prefetchedTrackIds, isEmpty);

        // Skip to next re-seeks current track to zero
        await controller.skipToNext();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          container.read(playbackControllerProvider).currentTrack?.id,
          equals('track_1'),
        );
        expect(player.lastSeekPosition, equals(Duration.zero));
      },
    );

    test(
      'Scenario 9: Repeat All behavior (correctly predicts wrap-around track)',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        // Play track3 (last item in 3-track queue)
        await controller.playTrack(
          track3,
          contextTracks: [track1, track2, track3],
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Without Repeat All, last track has no next track
        expect(controller.getPredictedNextTrack(), isNull);

        // Enable Repeat All
        await controller.setRepeatMode(RepeatMode.all);

        // Authoritative next track wraps around to track1
        final predicted = controller.getPredictedNextTrack();
        expect(predicted?.id, equals('track_1'));

        // Ticking past 75% pre-resolves wrap-around track1
        player.emitPosition(const Duration(seconds: 110));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(repo.prefetchedTrackIds, contains('track_1'));
        expect(repo.hasPrediction('track_1'), isTrue);
      },
    );

    test(
      'Scenario 10: Rapid Next operations cancel superseded in-flight requests',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(
          track1,
          contextTracks: [track1, track2, track3],
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Introduce delay to simulate slow network resolution
        repo.resolveDelayMs = 50;

        // Rapidly fire multiple skip commands
        final future1 = controller.skipToNext();
        final future2 = controller.skipToNext();

        await Future.wait([future1, future2]);
        await Future<void>.delayed(const Duration(milliseconds: 70));

        // State ends up on track 3 without throwing unhandled exceptions
        expect(
          container.read(playbackControllerProvider).currentTrack?.id,
          equals('track_3'),
        );
      },
    );

    test('Scenario 11: Stale prediction completion discarded safely', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Slow prefetch for track 2
      repo.prefetchDelayMs = 60;
      player.emitPosition(const Duration(seconds: 75));

      // While prefetch is in-flight, user directly skips to track 3
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await controller.skipToQueueItem(2); // Jump to track 3

      // Wait for original slow prefetch to finish
      await Future<void>.delayed(const Duration(milliseconds: 80));

      // Current track is track 3 and track 2 cache was invalidated
      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_3'),
      );
      expect(repo.hasPrediction('track_2'), isFalse);
    });

    test('Scenario 12: Invalid cached URL recovery (re-resolves on setAudioUrl failure)', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Preload cache with a stale/broken URL
      repo.cache.put('track_2', 'https://broken.audius.co/expired.mp3');
      expect(repo.hasPrediction('track_2'), isTrue);

      // Instruct player to fail on this setAudioUrl attempt
      player.failNextSetAudioUrl = true;

      await controller.skipToNext();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final tracer = PlaybackController.lastCompletedTracer;
      expect(tracer, isNotNull);
      expect(tracer!.hasMark('cache_hit'), isTrue);
      // Fallback mark recorded
      expect(tracer.hasMark('normal_resolution_fallback'), isTrue);
      // Player successfully recovered and loaded fresh URL
      expect(
        player.loadedUrl,
        equals('https://creatornode.audius.co/tracks/track_2.mp3'),
      );
      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.playing),
      );
    });

    test('Scenario 13: Current playback unaffected by background prediction network failures', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Set prefetch to throw
      repo.failPrefetch = true;

      // Trigger 15s remaining threshold
      player.emitPosition(const Duration(seconds: 88));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Playback state is undisturbed
      final state = container.read(playbackControllerProvider);
      expect(state.isPlaying, isTrue);
      expect(state.status, equals(PlaybackStatus.playing));
      expect(state.error, isNull);
    });

    test('Scenario 14: Existing playback behavior preserved when prediction is unavailable', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      // Cold play
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      expect(container.read(playbackControllerProvider).isPlaying, isTrue);

      // Pause
      await controller.pause();
      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.paused),
      );

      // Resume
      await controller.play();
      expect(container.read(playbackControllerProvider).isPlaying, isTrue);

      // Seek
      await controller.seek(const Duration(seconds: 30));
      expect(player.currentPosition, equals(const Duration(seconds: 30)));

      // Skip previous
      await controller.skipToNext();
      await controller.skipToPrevious();
      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_1'),
      );
    });
  });
}
