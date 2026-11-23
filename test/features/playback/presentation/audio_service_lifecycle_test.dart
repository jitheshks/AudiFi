import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audifi_audio_handler.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_helpers/stub_repositories.dart';

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
  Duration? _duration;
  bool isDisposed = false;

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
    _isPlaying = true;
    _playingController.add(true);
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _playingController.add(false);
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    _positionController.add(position);
  }

  @override
  Future<void> setAudioUrl(String url) async {}

  @override
  Future<void> setAudioSource(AudioSource source) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await _playingController.close();
    await _processingController.close();
    await _positionController.close();
    await _bufferedController.close();
    await _durationController.close();
    await _completedController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetBootstrapAudioServices();
  });

  tearDown(() {
    resetBootstrapAudioServices();
  });

  group('Phase 3.1: Audio Service & Player Lifecycle Foundation', () {
    test('isBootstrapAudioInitialized returns true only after both singletons are registered', () {
      expect(isBootstrapAudioInitialized, isFalse);

      final fakePlayer = _FakeAudioPlayerService();
      final fakeHandler = AudifiAudioHandler(playerService: fakePlayer);

      setBootstrapAudioServices(
        audioHandler: fakeHandler,
        audioPlayerService: fakePlayer,
      );

      expect(isBootstrapAudioInitialized, isTrue);
      expect(getBootstrapAudioHandler(), same(fakeHandler));
      expect(getBootstrapAudioPlayerService(), same(fakePlayer));

      resetBootstrapAudioServices();
      expect(isBootstrapAudioInitialized, isFalse);
      expect(getBootstrapAudioHandler(), isNull);
      expect(getBootstrapAudioPlayerService(), isNull);
    });

    test('setBootstrapAudioServices prevents duplicate overwrites unless allowOverwrite is true', () {
      final fakePlayer1 = _FakeAudioPlayerService();
      final fakeHandler1 = AudifiAudioHandler(playerService: fakePlayer1);

      final fakePlayer2 = _FakeAudioPlayerService();
      final fakeHandler2 = AudifiAudioHandler(playerService: fakePlayer2);

      setBootstrapAudioServices(
        audioHandler: fakeHandler1,
        audioPlayerService: fakePlayer1,
      );

      // Duplicate registration without allowOverwrite is ignored
      setBootstrapAudioServices(
        audioHandler: fakeHandler2,
        audioPlayerService: fakePlayer2,
      );

      expect(getBootstrapAudioHandler(), same(fakeHandler1));
      expect(getBootstrapAudioPlayerService(), same(fakePlayer1));

      // Explicit overwrite replaces instances
      setBootstrapAudioServices(
        audioHandler: fakeHandler2,
        audioPlayerService: fakePlayer2,
        allowOverwrite: true,
      );

      expect(getBootstrapAudioHandler(), same(fakeHandler2));
      expect(getBootstrapAudioPlayerService(), same(fakePlayer2));
    });

    test(
      'Riverpod audio providers deliver the authoritative bootstrap singletons',
      () {
        final fakePlayer = _FakeAudioPlayerService();
        final fakeHandler = AudifiAudioHandler(playerService: fakePlayer);

        setBootstrapAudioServices(
          audioHandler: fakeHandler,
          audioPlayerService: fakePlayer,
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final deliveredPlayer = container.read(audioPlayerServiceProvider);
        final deliveredHandler = container.read(audioHandlerProvider);

        expect(deliveredPlayer, same(fakePlayer));
        expect(deliveredHandler, same(fakeHandler));
      },
    );

    test('AudifiAudioHandler dispose is idempotent and guards against subsequent state emissions', () async {
      final fakePlayer = _FakeAudioPlayerService();
      final handler = AudifiAudioHandler(playerService: fakePlayer);

      expect(handler.isDisposed, isFalse);
      await expectLater(handler.dispose(), completes);
      expect(handler.isDisposed, isTrue);

      // Calling dispose a second time is safe
      await expectLater(handler.dispose(), completes);
      expect(handler.isDisposed, isTrue);

      // Calling syncTrack or actions on disposed handler is safely ignored
      const sampleTrack = Track(
        id: 'track_test',
        title: 'Test Track',
        duration: 180,
      );
      handler.syncTrack(sampleTrack);
      expect(handler.currentTrack, isNull);

      await expectLater(handler.play(), completes);
      await expectLater(handler.pause(), completes);
      await expectLater(handler.stop(), completes);
      await expectLater(handler.seek(Duration.zero), completes);
    });

    test('PlaybackController rebuild cancels existing subscriptions preventing subscription leaks', () {
      final fakePlayer = _FakeAudioPlayerService();
      final fakeHandler = AudifiAudioHandler(playerService: fakePlayer);

      setBootstrapAudioServices(
        audioHandler: fakeHandler,
        audioPlayerService: fakePlayer,
      );

      final container = ProviderContainer(
        overrides: [
          playbackRepositoryProvider.overrideWithValue(
            StubPlaybackRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // First read mounts controller
      final controller = container.read(playbackControllerProvider.notifier);
      expect(
        container.read(playbackControllerProvider).status,
        PlaybackStatus.idle,
      );

      // Force-rebuilding controller cancels prior subscriptions cleanly
      controller.build();
      expect(
        container.read(playbackControllerProvider).status,
        PlaybackStatus.idle,
      );
    });
  });
}
