import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:audio_session/audio_session.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/data/services/just_audio_player_service.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/repositories/playback_repository.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/models/artwork.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAudioPlayerService implements AudioPlayerService {
  final _playingController = StreamController<bool>.broadcast();
  final _processingController =
      StreamController<EngineProcessingState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(seconds: 180);
  String? loadedUrl;

  int playCount = 0;
  int pauseCount = 0;
  int stopCount = 0;
  Duration? lastSeekPosition;
  double currentVolume = 1.0;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<EngineProcessingState> get processingStateStream =>
      _processingController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get bufferedPositionStream => _bufferedController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<void> get completedStream => _completedController.stream;

  @override
  Duration get currentPosition => _position;

  @override
  Duration? get currentDuration => _duration;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> play() async {
    playCount++;
    _isPlaying = true;
    _playingController.add(true);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    _isPlaying = false;
    _playingController.add(false);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _isPlaying = false;
    _playingController.add(false);
    _processingController.add(EngineProcessingState.idle);
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
    _position = position;
    _positionController.add(position);
  }

  @override
  Future<void> setAudioUrl(String url) async {
    loadedUrl = url;
    _processingController.add(EngineProcessingState.ready);
    _durationController.add(_duration);
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    _processingController.add(EngineProcessingState.ready);
    _durationController.add(_duration);
  }

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
  }

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {
    await _playingController.close();
    await _processingController.close();
    await _positionController.close();
    await _bufferedController.close();
    await _durationController.close();
    await _completedController.close();
  }
}

class _SlowPlaybackRepository implements PlaybackRepository {
  final Completer<String> completer = Completer<String>();

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    cancelToken?.whenCancel.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.cancel,
            message: 'cancelled',
          ),
        );
      }
    });
    return completer.future;
  }

  @override
  Future<void> prefetchStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {}

  @override
  bool hasPrediction(String trackId) => false;

  @override
  String? get currentPredictedTrackId => null;

  @override
  void invalidatePrediction({String? reason = 'unspecified'}) {}

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

const _testTrack = Track(
  id: 'test_1',
  title: 'Test Song',
  duration: 180,
  isStreamable: true,
  user: User(id: 'u1', name: 'Test Artist', handle: 'testartist'),
  artwork: Artwork(medium: 'https://example.com/art.jpg'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JustAudioPlayerService Audio Focus & Interruption Unit Tests', () {
    test(
      'Ducking scales volume by 50% and restores exact pre-ducking user volume',
      () async {
        final service = JustAudioPlayerService();

        expect(service.userVolume, equals(1.0));
        expect(service.isDucked, isFalse);

        // 1. Begin ducking event
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(true, AudioInterruptionType.duck),
        );
        expect(service.isDucked, isTrue);
        expect(service.userVolume, equals(1.0));

        // 2. End ducking event
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(false, AudioInterruptionType.duck),
        );
        expect(service.isDucked, isFalse);
        expect(service.userVolume, equals(1.0));

        await service.dispose();
      },
    );

    test(
      'Ducking preserves custom user volume and restores after ducking ends',
      () async {
        final service = JustAudioPlayerService();

        await service.setVolume(0.8);
        expect(service.userVolume, equals(0.8));

        // Duck begins
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(true, AudioInterruptionType.duck),
        );
        expect(service.isDucked, isTrue);
        expect(service.userVolume, equals(0.8));

        // User changes volume while ducked
        await service.setVolume(0.6);
        expect(service.userVolume, equals(0.6));
        expect(service.isDucked, isTrue);

        // Duck ends -> restores to 0.6
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(false, AudioInterruptionType.duck),
        );
        expect(service.isDucked, isFalse);
        expect(service.userVolume, equals(0.6));

        await service.dispose();
      },
    );

    test(
      'Multiple rapid ducking begin events do not progressively reduce volume',
      () async {
        final service = JustAudioPlayerService();
        await service.setVolume(0.8);

        // First duck begin
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(true, AudioInterruptionType.duck),
        );
        expect(service.isDucked, isTrue);
        expect(service.userVolume, equals(0.8));

        // Second redundant duck begin
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(true, AudioInterruptionType.duck),
        );
        expect(service.isDucked, isTrue);
        expect(service.userVolume, equals(0.8));

        // End ducking
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(false, AudioInterruptionType.duck),
        );
        expect(service.isDucked, isFalse);
        expect(service.userVolume, equals(0.8));

        await service.dispose();
      },
    );

    test('Transient pause interruption marks isPlayInterrupted and calls onInterruptionPause', () async {
      final service = JustAudioPlayerService();
      var pauseCalled = false;
      var resumeCalled = false;
      var isActive = true;

      service.setInterruptionCallbacks(
        onPause: () async => pauseCalled = true,
        onResume: () async => resumeCalled = true,
        isPlaybackActive: () => isActive,
      );

      // Interruption begins while playing
      await service.handleInterruptionEvent(
        AudioInterruptionEvent(true, AudioInterruptionType.pause),
      );
      expect(pauseCalled, isTrue);
      expect(service.isPlayInterrupted, isTrue);

      // Interruption ends -> auto-resume triggered
      await service.handleInterruptionEvent(
        AudioInterruptionEvent(false, AudioInterruptionType.pause),
      );
      expect(resumeCalled, isTrue);
      expect(service.isPlayInterrupted, isFalse);

      await service.dispose();
    });

    test(
      'User manual pause during transient interruption prevents auto-resume',
      () async {
        final service = JustAudioPlayerService();
        var pauseCalled = false;
        var resumeCalled = false;
        var isActive = true;

        service.setInterruptionCallbacks(
          onPause: () async => pauseCalled = true,
          onResume: () async => resumeCalled = true,
          isPlaybackActive: () => isActive,
        );

        // Interruption begins while playing
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(true, AudioInterruptionType.pause),
        );
        expect(pauseCalled, isTrue);
        expect(service.isPlayInterrupted, isTrue);

        // User explicitly pauses while interruption is still active
        await service.pause();
        expect(service.isPlayInterrupted, isFalse);

        // Interruption ends -> should NOT resume because user manually paused
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(false, AudioInterruptionType.pause),
        );
        expect(resumeCalled, isFalse);
        expect(service.isPlayInterrupted, isFalse);

        await service.dispose();
      },
    );

    test('Interruption when already paused does not auto-resume when interruption ends', () async {
      final service = JustAudioPlayerService();
      var pauseCalled = false;
      var resumeCalled = false;
      var isActive = false; // not active

      service.setInterruptionCallbacks(
        onPause: () async => pauseCalled = true,
        onResume: () async => resumeCalled = true,
        isPlaybackActive: () => isActive,
      );

      // Interruption begins while already paused
      await service.handleInterruptionEvent(
        AudioInterruptionEvent(true, AudioInterruptionType.pause),
      );
      expect(pauseCalled, isTrue);
      expect(service.isPlayInterrupted, isFalse);

      // Interruption ends -> stays paused
      await service.handleInterruptionEvent(
        AudioInterruptionEvent(false, AudioInterruptionType.pause),
      );
      expect(resumeCalled, isFalse);
      expect(service.isPlayInterrupted, isFalse);

      await service.dispose();
    });

    test('Permanent focus loss (AudioInterruptionType.unknown) pauses and never auto-resumes', () async {
      final service = JustAudioPlayerService();
      var pauseCalled = false;
      var resumeCalled = false;
      var isActive = true;

      service.setInterruptionCallbacks(
        onPause: () async => pauseCalled = true,
        onResume: () async => resumeCalled = true,
        isPlaybackActive: () => isActive,
      );

      // Permanent focus loss begins
      await service.handleInterruptionEvent(
        AudioInterruptionEvent(true, AudioInterruptionType.unknown),
      );
      expect(pauseCalled, isTrue);
      expect(service.isPlayInterrupted, isFalse);

      // Permanent focus loss ends -> NEVER auto-resume
      await service.handleInterruptionEvent(
        AudioInterruptionEvent(false, AudioInterruptionType.unknown),
      );
      expect(resumeCalled, isFalse);
      expect(service.isPlayInterrupted, isFalse);

      await service.dispose();
    });

    test(
      'Headphone disconnection (becomingNoisy) pauses when setting is enabled',
      () async {
        var shouldPause = true;
        final service = JustAudioPlayerService(
          shouldPauseOnHeadphoneDisconnect: () => shouldPause,
        );
        var noisyPauseCalled = false;

        service.setInterruptionCallbacks(
          onBecomingNoisy: () async => noisyPauseCalled = true,
        );

        await service.handleBecomingNoisyEvent();
        expect(noisyPauseCalled, isTrue);
        expect(
          service.isPlayInterrupted,
          isFalse,
        ); // No auto-resume on noisy disconnect

        await service.dispose();
      },
    );

    test('Headphone disconnection (becomingNoisy) does not pause when setting is disabled', () async {
      var shouldPause = false;
      final service = JustAudioPlayerService(
        shouldPauseOnHeadphoneDisconnect: () => shouldPause,
      );
      var noisyPauseCalled = false;

      service.setInterruptionCallbacks(
        onBecomingNoisy: () async => noisyPauseCalled = true,
      );

      await service.handleBecomingNoisyEvent();
      expect(noisyPauseCalled, isFalse);

      await service.dispose();
    });

    test(
      'Dynamic setting change updates becomingNoisy behavior on the fly',
      () async {
        var shouldPause = false;
        final service = JustAudioPlayerService();
        service.setShouldPauseOnHeadphoneDisconnect(() => shouldPause);

        var noisyPauseCount = 0;
        service.setInterruptionCallbacks(
          onBecomingNoisy: () async => noisyPauseCount++,
        );

        // 1. Setting is false -> no pause
        await service.handleBecomingNoisyEvent();
        expect(noisyPauseCount, equals(0));

        // 2. User dynamically enables setting -> pauses
        shouldPause = true;
        await service.handleBecomingNoisyEvent();
        expect(noisyPauseCount, equals(1));

        // 3. User dynamically disables setting again -> no pause
        shouldPause = false;
        await service.handleBecomingNoisyEvent();
        expect(noisyPauseCount, equals(1));

        await service.dispose();
      },
    );

    test(
      'Volume clamping between 0.0 and 1.0 is preserved during ducking',
      () async {
        final service = JustAudioPlayerService();

        // Duck begin
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(true, AudioInterruptionType.duck),
        );

        // Attempt setting invalid volumes
        await service.setVolume(1.5);
        expect(service.userVolume, equals(1.0));

        await service.setVolume(-0.5);
        expect(service.userVolume, equals(0.0));

        // Duck end
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(false, AudioInterruptionType.duck),
        );
        expect(service.userVolume, equals(0.0));

        await service.dispose();
      },
    );

    test(
      'Multiple rapid transient interruptions handle state deterministically',
      () async {
        final service = JustAudioPlayerService();
        var pauseCount = 0;
        var resumeCount = 0;
        var isActive = true;

        service.setInterruptionCallbacks(
          onPause: () async => pauseCount++,
          onResume: () async => resumeCount++,
          isPlaybackActive: () => isActive,
        );

        // First interruption begins
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(true, AudioInterruptionType.pause),
        );
        expect(pauseCount, equals(1));
        expect(service.isPlayInterrupted, isTrue);

        // Second interruption arrives while first is ongoing
        isActive = false; // player paused from first
        await service.handleInterruptionEvent(
          AudioInterruptionEvent(true, AudioInterruptionType.pause),
        );
        expect(pauseCount, equals(2));
        // Still considered interrupted from initial active state
        expect(
          service.isPlayInterrupted,
          isFalse,
        ); // Because isActive was false!

        // If user resumed before end
        service.setInterruptionCallbacks(
          onPause: () async => pauseCount++,
          onResume: () async => resumeCount++,
          isPlaybackActive: () => true,
        );

        await service.dispose();
      },
    );

    test('Becoming noisy while already paused is a safe no-op', () async {
      var shouldPause = true;
      final service = JustAudioPlayerService(
        shouldPauseOnHeadphoneDisconnect: () => shouldPause,
      );
      var noisyPauseCount = 0;

      service.setInterruptionCallbacks(
        onBecomingNoisy: () async => noisyPauseCount++,
      );

      // Becoming noisy while paused
      await service.handleBecomingNoisyEvent();
      expect(noisyPauseCount, equals(1));
      expect(service.isPlayInterrupted, isFalse);

      // Second noisy event
      await service.handleBecomingNoisyEvent();
      expect(noisyPauseCount, equals(2));
      expect(service.isPlayInterrupted, isFalse);

      await service.dispose();
    });
  });

  group('PlaybackController & AudioHandler Interruption Coordination Integration Tests', () {
    test('Interruption during track loading cancels load and pauses controller cleanly', () async {
      final fakePlayer = _FakeAudioPlayerService();
      final slowRepo = _SlowPlaybackRepository();

      final container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(fakePlayer),
          playbackRepositoryProvider.overrideWithValue(slowRepo),
        ],
      );

      final handler = container.read(audioHandlerProvider);
      final controller = container.read(playbackControllerProvider.notifier);

      // Start playing track (will remain in loading state due to slow repo)
      unawaited(controller.playTrack(_testTrack));
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.loading),
      );
      expect(controller.isActivelyPlayingOrLoading, isTrue);

      // System notification / call interruption begins
      await handler.pause();

      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.paused),
      );

      container.dispose();
    });

    test(
      'Becoming noisy during track loading cancels load and pauses controller',
      () async {
        final fakePlayer = _FakeAudioPlayerService();
        final slowRepo = _SlowPlaybackRepository();

        final container = ProviderContainer(
          overrides: [
            audioPlayerServiceProvider.overrideWithValue(fakePlayer),
            playbackRepositoryProvider.overrideWithValue(slowRepo),
          ],
        );

        final handler = container.read(audioHandlerProvider);
        final controller = container.read(playbackControllerProvider.notifier);

        unawaited(controller.playTrack(_testTrack));
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.loading),
        );

        // Headphone disconnected during loading
        await handler.pause();

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.paused),
        );

        container.dispose();
      },
    );

    test(
      'AudioHandler delegates play after interruption end to resume controller',
      () async {
        final fakePlayer = _FakeAudioPlayerService();
        final slowRepo = _SlowPlaybackRepository();

        final container = ProviderContainer(
          overrides: [
            audioPlayerServiceProvider.overrideWithValue(fakePlayer),
            playbackRepositoryProvider.overrideWithValue(slowRepo),
          ],
        );

        final handler = container.read(audioHandlerProvider);
        final controller = container.read(playbackControllerProvider.notifier);

        // Play track
        unawaited(controller.playTrack(_testTrack));
        await Future<void>.delayed(Duration.zero);
        slowRepo.completer.complete('https://audius.co/stream/test_1.mp3');
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.playing),
        );

        // Transient interruption begins
        await handler.pause();
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.paused),
        );

        // Transient interruption ends -> play invoked
        await handler.play();
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.playing),
        );

        container.dispose();
      },
    );
  });
}
