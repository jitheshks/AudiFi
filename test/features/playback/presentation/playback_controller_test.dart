import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:audifi/core/errors/app_exception.dart';
import 'package:audifi/core/errors/failure.dart';
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

class MockAudioPlayerService implements AudioPlayerService {
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
  Duration? currentDurationValue = const Duration(seconds: 200);

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
    loadedUrl = url;
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> play() async {
    isPlayingState = true;
    _playingController.add(true);
    _processingController.add(EngineProcessingState.ready);
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

  void emitPosition(Duration pos) => _positionController.add(pos);
  void emitBuffered(Duration buf) => _bufferedController.add(buf);
  void emitCompletion() => _completedController.add(null);
}

class MockPlaybackRepo implements PlaybackRepository {
  bool shouldFail = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) {
      throw const CancellationException();
    }
    if (shouldFail) {
      throw const NetworkException(message: 'Stream unavailable');
    }
    return 'https://audius.co/stream/$trackId.mp3';
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
  group('PlaybackController', () {
    late ProviderContainer container;
    late MockAudioPlayerService player;
    late MockPlaybackRepo repo;

    setUp(() {
      player = MockAudioPlayerService();
      repo = MockPlaybackRepo();
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

    const testTrack = Track(
      id: 'track_1',
      title: 'Sound of Audius',
      duration: 180,
    );

    test('initial state is idle without active track', () {
      final state = container.read(playbackControllerProvider);
      expect(state.status, equals(PlaybackStatus.idle));
      expect(state.currentTrack, isNull);
      expect(state.isPlaying, isFalse);
    });

    test('playTrack resolves URL and starts audio playback', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(testTrack);

      final state = container.read(playbackControllerProvider);
      expect(state.currentTrack?.id, equals('track_1'));
      expect(state.isPlaying, isTrue);
      expect(player.loadedUrl, equals('https://audius.co/stream/track_1.mp3'));
      expect(player.isPlaying, isTrue);
    });

    test('playTrack failure sets state error to Failure', () async {
      repo.shouldFail = true;
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(testTrack);

      final state = container.read(playbackControllerProvider);
      expect(state.status, equals(PlaybackStatus.error));
      expect(state.error, isA<Failure>());
    });

    test(
      'togglePlayPause pauses playing track and resumes paused track',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(testTrack);

        await controller.togglePlayPause();
        expect(container.read(playbackControllerProvider).isPlaying, isFalse);

        await controller.togglePlayPause();
        expect(container.read(playbackControllerProvider).isPlaying, isTrue);
      },
    );

    test('seek clamps position between zero and duration', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(testTrack);

      await controller.seek(const Duration(seconds: 45));
      expect(
        container.read(playbackControllerProvider).position.inSeconds,
        equals(45),
      );

      // Seeking past duration clamps to duration
      await controller.seek(const Duration(seconds: 500));
      expect(
        container.read(playbackControllerProvider).position.inSeconds,
        equals(180),
      );
    });

    test('cycleRepeatMode cycles through off -> all -> one -> off', () {
      final controller = container.read(playbackControllerProvider.notifier);
      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.off),
      );

      controller.cycleRepeatMode();
      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.all),
      );

      controller.cycleRepeatMode();
      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.one),
      );

      controller.cycleRepeatMode();
      expect(
        container.read(playbackControllerProvider).repeatMode,
        equals(RepeatMode.off),
      );
    });

    test(
      'updates state position and buffered position from player streams',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(testTrack);

        player.emitPosition(const Duration(seconds: 30));
        player.emitBuffered(const Duration(seconds: 60));
        await Future<void>.delayed(Duration.zero);

        final state = container.read(playbackControllerProvider);
        expect(state.position.inSeconds, equals(30));
        expect(state.bufferedPosition.inSeconds, equals(60));
        expect(state.formattedPosition, equals('0:30'));
      },
    );

    test('skipToPrevious seeks to zero when position > 3 seconds', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(testTrack);
      await controller.seek(const Duration(seconds: 10));

      await controller.skipToPrevious();
      expect(
        container.read(playbackControllerProvider).position,
        equals(Duration.zero),
      );
    });
  });
}
