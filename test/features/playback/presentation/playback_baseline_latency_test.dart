import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:audifi/core/errors/app_exception.dart';
import 'package:dio/dio.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/entities/repeat_mode.dart';
import 'package:audifi/features/playback/domain/repositories/playback_repository.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class LatencySimulatingPlayerService implements AudioPlayerService {
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
  Duration? currentDurationValue = const Duration(seconds: 180);

  int setUrlDelayMs = 0;
  int playDelayMs = 0;

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
    _processingController.add(EngineProcessingState.loading);
    if (setUrlDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: setUrlDelayMs));
    }
    loadedUrl = url;
    _processingController.add(EngineProcessingState.buffering);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    _processingController.add(EngineProcessingState.loading);
    if (setUrlDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: setUrlDelayMs));
    }
    _processingController.add(EngineProcessingState.buffering);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> play() async {
    if (playDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: playDelayMs));
    }
    isPlayingState = true;
    _playingController.add(true);
    _processingController.add(EngineProcessingState.ready);
    // Simulate initial audio progression (T10)
    scheduleMicrotask(() {
      currentPositionValue = const Duration(milliseconds: 100);
      _positionController.add(const Duration(milliseconds: 100));
    });
  }

  @override
  Future<void> pause() async {
    isPlayingState = false;
    _playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
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
}

class LatencySimulatingRepo implements PlaybackRepository {
  int resolutionDelayMs = 0;
  bool shouldFail = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    if (resolutionDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: resolutionDelayMs));
    }
    if (cancelToken?.isCancelled == true) {
      throw const CancellationException();
    }
    if (shouldFail) {
      throw const NetworkException(
        message: 'Simulated stream resolution failure',
      );
    }
    return 'https://creatornode.audius.co/tracks/$trackId.mp3';
  }

  @override
  Future<void> prefetchStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {}

  @override
  String? get currentPredictedTrackId => null;

  @override
  bool hasPrediction(String trackId) => false;

  @override
  void invalidatePrediction({String? reason}) {}

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

  group('Playback Transition Latency Baseline Tests', () {
    late ProviderContainer container;
    late LatencySimulatingPlayerService player;
    late LatencySimulatingRepo repo;

    const track1 = Track(id: 'track_1', title: 'Track 1', duration: 180);
    const track2 = Track(id: 'track_2', title: 'Track 2', duration: 210);
    const track3 = Track(id: 'track_3', title: 'Track 3', duration: 240);

    setUp(() {
      player = LatencySimulatingPlayerService();
      repo = LatencySimulatingRepo();
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

    test(
      'Scenario A — Normal Next: captures complete T0 through T10 timeline',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        // Seed queue with tracks
        await controller.playTrack(
          track1,
          contextTracks: [track1, track2, track3],
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Set realistic simulated delays based on empirical Audius measurements
        repo.resolutionDelayMs = 15; // Simulated stream URL resolution
        player.setUrlDelayMs = 20; // Simulated ExoPlayer source buffer/prepare
        player.playDelayMs = 5; // Simulated AudioTrack sink write

        await controller.skipToNext();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final tracer = PlaybackController.lastCompletedTracer;
        expect(tracer, isNotNull);
        expect(tracer!.trigger, equals('next'));
        expect(tracer.targetTrackId, equals('track_2'));

        final timings = tracer.timings;
        expect(timings.containsKey('t0_user_triggered'), isTrue);
        expect(timings.containsKey('t1_queue_advanced'), isTrue);
        expect(timings.containsKey('t2_ui_track_updated'), isTrue);
        expect(timings.containsKey('t3_stream_resolution_started'), isTrue);
        expect(timings.containsKey('t4_stream_resolution_completed'), isTrue);
        expect(timings.containsKey('t5_source_load_started'), isTrue);
        expect(timings.containsKey('t6_player_buffering'), isTrue);
        expect(timings.containsKey('t7_player_ready'), isTrue);
        expect(timings.containsKey('t8_play_command_issued'), isTrue);
        expect(timings.containsKey('t9_player_playing'), isTrue);
        expect(timings.containsKey('t10_first_audio_progression'), isTrue);

        // Verify chronology: T0 <= T1 <= T2 <= T3 <= T4 <= T5 <= T7 <= T8 <= T9 <= T10
        expect(
          timings['t0_user_triggered']!,
          lessThanOrEqualTo(timings['t1_queue_advanced']!),
        );
        expect(
          timings['t1_queue_advanced']!,
          lessThanOrEqualTo(timings['t2_ui_track_updated']!),
        );
        expect(
          timings['t2_ui_track_updated']!,
          lessThanOrEqualTo(timings['t3_stream_resolution_started']!),
        );
        expect(
          timings['t3_stream_resolution_started']!,
          lessThanOrEqualTo(timings['t4_stream_resolution_completed']!),
        );
        expect(
          timings['t4_stream_resolution_completed']!,
          lessThanOrEqualTo(timings['t5_source_load_started']!),
        );
        expect(
          timings['t5_source_load_started']!,
          lessThanOrEqualTo(timings['t7_player_ready']!),
        );
        expect(
          timings['t7_player_ready']!,
          lessThanOrEqualTo(timings['t8_play_command_issued']!),
        );
        expect(
          timings['t8_play_command_issued']!,
          lessThanOrEqualTo(timings['t9_player_playing']!),
        );
        expect(
          timings['t9_player_playing']!,
          lessThanOrEqualTo(timings['t10_first_audio_progression']!),
        );

        // Active state reflects track_2
        expect(
          container.read(playbackControllerProvider).currentTrack?.id,
          equals('track_2'),
        );
      },
    );

    test('Scenario B — Repeated Next: rapid skipping aborts superseded operations without race conditions', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track1,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Add long resolution delay to simulate pending network requests
      repo.resolutionDelayMs = 60;
      player.setUrlDelayMs = 40;

      // Rapidly fire Next -> Next
      final skip1 = controller.skipToNext();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final skip2 = controller.skipToNext();

      await Future.wait([skip1, skip2]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Final state must reflect the final track (track_3)
      final state = container.read(playbackControllerProvider);
      expect(state.currentTrack?.id, equals('track_3'));
      expect(player.loadedUrl, contains('track_3'));
    });

    test('Scenario C — Previous track transition', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        track2,
        contextTracks: [track1, track2, track3],
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Set position to zero so it steps to previous track (rather than seeking to 0)
      player.currentPositionValue = Duration.zero;

      await controller.skipToPrevious();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(playbackControllerProvider);
      expect(state.currentTrack?.id, equals('track_1'));
    });

    test('Scenario D — Cold playback: initial track launch', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(track1);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(playbackControllerProvider);
      expect(state.currentTrack?.id, equals('track_1'));
      expect(state.status, equals(PlaybackStatus.playing));
    });

    test('Scenario E — Repeat Mode One replay behavior', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(track1, contextTracks: [track1, track2]);
      await controller.setRepeatMode(RepeatMode.one);

      await controller.skipToNext();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Under repeat one, skipping to next replays the current track from 0
      final state = container.read(playbackControllerProvider);
      expect(state.currentTrack?.id, equals('track_1'));
    });

    test('Scenario F — Stream resolution network failure cleanly aborts transition trace', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(track1, contextTracks: [track1, track2]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      repo.shouldFail = true;
      await controller.skipToNext();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(playbackControllerProvider);
      expect(state.status, equals(PlaybackStatus.error));
      expect(state.error, isNotNull);
    });
  });
}
