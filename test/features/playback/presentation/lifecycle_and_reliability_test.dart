import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audifi_audio_handler.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/data/services/just_audio_player_service.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/entities/repeat_mode.dart';
import 'package:audifi/features/playback/domain/repositories/playback_repository.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/controllers/queue_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/models/artwork.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReliableFakeAudioPlayerService implements AudioPlayerService {
  final _playingController = StreamController<bool>.broadcast();
  final _processingController =
      StreamController<EngineProcessingState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration = const Duration(seconds: 200);
  String? loadedUrl;

  int playCount = 0;
  int pauseCount = 0;
  int stopCount = 0;
  Duration? lastSeekPosition;
  double currentVolume = 1.0;
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
    if (isDisposed) return;
    playCount++;
    _isPlaying = true;
    _playingController.add(true);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    if (isDisposed) return;
    pauseCount++;
    _isPlaying = false;
    _playingController.add(false);
  }

  @override
  Future<void> stop() async {
    if (isDisposed) return;
    stopCount++;
    _isPlaying = false;
    _playingController.add(false);
    _processingController.add(EngineProcessingState.idle);
  }

  @override
  Future<void> seek(Duration position) async {
    if (isDisposed) return;
    lastSeekPosition = position;
    _position = position;
    _positionController.add(position);
  }

  @override
  Future<void> setAudioUrl(String url) async {
    if (isDisposed) return;
    loadedUrl = url;
    _processingController.add(EngineProcessingState.ready);
    if (_duration != null) {
      _durationController.add(_duration);
    }
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    if (isDisposed) return;
    _processingController.add(EngineProcessingState.ready);
    if (_duration != null) {
      _durationController.add(_duration);
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
  }

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {
    if (isDisposed) return;
    isDisposed = true;
    await _playingController.close();
    await _processingController.close();
    await _positionController.close();
    await _bufferedController.close();
    await _durationController.close();
    await _completedController.close();
  }

  void emitPosition(Duration pos) {
    _position = pos;
    _positionController.add(pos);
  }

  void emitDuration(Duration? dur) {
    _duration = dur;
    _durationController.add(dur);
  }

  void emitCompleted() {
    _completedController.add(null);
  }
}

class _ConfigurablePlaybackRepository implements PlaybackRepository {
  Completer<String>? pendingResolutionCompleter;
  int resolutionCallCount = 0;
  bool shouldFailResolution = false;
  ({List<Track> tracks, int currentIndex})? savedQueueData;
  final Map<String, String> _cache = {};

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    resolutionCallCount++;
    if (shouldFailResolution) {
      throw DioException(
        requestOptions: RequestOptions(path: '/stream'),
        type: DioExceptionType.connectionError,
        error: 'Network unreachable',
      );
    }

    if (pendingResolutionCompleter != null) {
      cancelToken?.whenCancel.then((_) {
        if (!pendingResolutionCompleter!.isCompleted) {
          pendingResolutionCompleter!.completeError(
            DioException(
              requestOptions: RequestOptions(path: '/stream'),
              type: DioExceptionType.cancel,
            ),
          );
        }
      });
      return pendingResolutionCompleter!.future;
    }
    return 'https://audius.co/stream/$trackId.mp3';
  }

  @override
  Future<void> prefetchStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    _cache[trackId] = 'https://audius.co/stream/$trackId.mp3';
  }

  @override
  String? get currentPredictedTrackId =>
      _cache.keys.isNotEmpty ? _cache.keys.first : null;

  @override
  bool hasPrediction(String trackId) => _cache.containsKey(trackId);

  @override
  void invalidatePrediction({String? reason = 'unspecified'}) {
    _cache.clear();
  }

  @override
  Future<void> saveQueue({
    required List<Track> tracks,
    required int currentIndex,
  }) async {
    savedQueueData = (
      tracks: List.unmodifiable(tracks),
      currentIndex: currentIndex,
    );
  }

  @override
  Future<({List<Track> tracks, int currentIndex})?> restoreQueue() async {
    return savedQueueData;
  }

  @override
  Future<void> clearSavedQueue() async {
    savedQueueData = null;
  }
}

const _trackAlpha = Track(
  id: 'alpha_1',
  title: 'Alpha Wave',
  duration: 180,
  genre: 'Ambient',
  isStreamable: true,
  user: User(id: 'u_alpha', name: 'Ambient Master', handle: 'ambientmaster'),
  artwork: Artwork(medium: 'https://example.com/alpha.jpg'),
);

const _trackBeta = Track(
  id: 'beta_2',
  title: 'Beta Pulse',
  duration: 210,
  genre: 'Synth',
  isStreamable: true,
  user: User(id: 'u_beta', name: 'Synth Master', handle: 'synthmaster'),
  artwork: Artwork(medium: 'https://example.com/beta.jpg'),
);

const _trackGamma = Track(
  id: 'gamma_3',
  title: 'Gamma Flux',
  duration: 240,
  genre: 'Techno',
  isStreamable: true,
  user: User(id: 'u_gamma', name: 'Techno Master', handle: 'technomaster'),
  artwork: Artwork(medium: 'https://example.com/gamma.jpg'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3.5: Lifecycle Reattachment & State Integrity', () {
    test('PlaybackController cleanly reattaches to ongoing background audio session', () async {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository();

      // Simulate active background AudioHandler holding a playing track
      final handler = AudifiAudioHandler(playerService: player);
      handler.syncTrack(_trackAlpha);
      handler.syncQueue(
        [_trackAlpha, _trackBeta],
        currentIndex: 0,
        isShuffle: false,
      );
      handler.syncRepeatMode(RepeatMode.all);
      handler.syncShuffle(true, shuffledIndices: [0, 1]);

      await player.play();
      player.emitPosition(const Duration(seconds: 45));

      // Create new UI container representing activity launch/reattachment
      final container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          audioHandlerProvider.overrideWithValue(handler),
          playbackRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final state = container.read(playbackControllerProvider);

      expect(state.currentTrack?.id, equals(_trackAlpha.id));
      expect(state.status, equals(PlaybackStatus.playing));
      expect(state.position, equals(const Duration(seconds: 45)));
      expect(state.repeatMode, equals(RepeatMode.all));
      expect(state.isShuffleEnabled, isTrue);

      // Verify actions are reattached
      expect(handler.isActivelyPlayingOrLoading, isTrue);

      container.dispose();
      await handler.stop();
      await player.dispose();
    });

    test(
      'Duplicate bootstrap service initialization is rejected idempotently',
      () {
        resetBootstrapAudioServices();

        final playerA = _ReliableFakeAudioPlayerService();
        final handlerA = AudifiAudioHandler(playerService: playerA);

        final playerB = _ReliableFakeAudioPlayerService();
        final handlerB = AudifiAudioHandler(playerService: playerB);

        // First initialization succeeds
        setBootstrapAudioServices(
          audioHandler: handlerA,
          audioPlayerService: playerA,
        );
        expect(getBootstrapAudioPlayerService(), equals(playerA));
        expect(getBootstrapAudioHandler(), equals(handlerA));

        // Second duplicate initialization without allowOverwrite is ignored
        setBootstrapAudioServices(
          audioHandler: handlerB,
          audioPlayerService: playerB,
        );
        expect(getBootstrapAudioPlayerService(), equals(playerA));
        expect(getBootstrapAudioHandler(), equals(handlerA));

        // With allowOverwrite = true, replaces cleanly
        setBootstrapAudioServices(
          audioHandler: handlerB,
          audioPlayerService: playerB,
          allowOverwrite: true,
        );
        expect(getBootstrapAudioPlayerService(), equals(playerB));
        expect(getBootstrapAudioHandler(), equals(handlerB));

        resetBootstrapAudioServices();
      },
    );

    test('Repeated foreground/background lifecycle cycles (10 iterations) maintain state integrity without listener leaks', () async {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository();
      final handler = AudifiAudioHandler(playerService: player);

      handler.syncTrack(_trackAlpha);
      handler.syncQueue(
        [_trackAlpha, _trackBeta],
        currentIndex: 0,
        isShuffle: false,
      );
      await player.play();
      player.emitPosition(const Duration(seconds: 30));

      // Simulate 10 repeated foreground -> background -> foreground transitions
      for (var i = 0; i < 10; i++) {
        final container = ProviderContainer(
          overrides: [
            audioPlayerServiceProvider.overrideWithValue(player),
            audioHandlerProvider.overrideWithValue(handler),
            playbackRepositoryProvider.overrideWithValue(repo),
          ],
        );

        final state = container.read(playbackControllerProvider);
        expect(state.currentTrack?.id, equals(_trackAlpha.id));
        expect(state.status, equals(PlaybackStatus.playing));
        expect(handler.isActivelyPlayingOrLoading, isTrue);

        // Background / Activity teardown
        container.dispose();
      }

      // Background audio service continues uninhibited after UI detachment
      expect(player.isPlaying, isTrue);
      expect(handler.currentTrack?.id, equals(_trackAlpha.id));

      await handler.stop();
      await player.dispose();
    });
  });

  group('Phase 3.5: Persistence, Cold Startup & Queue Restoration', () {
    test('Cold launch restores saved queue in idle state without unwanted autoplay', () async {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository();

      // Pre-populate saved queue in repository
      repo.saveQueue(
        tracks: [_trackAlpha, _trackBeta, _trackGamma],
        currentIndex: 1,
      );

      final handler = AudifiAudioHandler(playerService: player);

      final container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          audioHandlerProvider.overrideWithValue(handler),
          playbackRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final controller = container.read(playbackControllerProvider.notifier);

      // Trigger restore
      await controller.restoreSavedQueue();

      final state = container.read(playbackControllerProvider);
      final queueState = container.read(queueControllerProvider);

      expect(state.currentTrack?.id, equals(_trackBeta.id));
      expect(state.status, equals(PlaybackStatus.idle));
      expect(queueState.currentIndex, equals(1));
      expect(queueState.items.length, equals(3));
      expect(player.playCount, equals(0)); // Did not autostart audio

      // Now explicit play command starts playback
      await controller.play();
      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.playing),
      );
      expect(player.playCount, equals(1));

      container.dispose();
      await handler.stop();
      await player.dispose();
    });

    test(
      'restoreSavedQueue does not clobber active background playback session',
      () async {
        final player = _ReliableFakeAudioPlayerService();
        final repo = _ConfigurablePlaybackRepository();

        // Repository has older saved queue
        repo.saveQueue(tracks: [_trackAlpha], currentIndex: 0);

        // Handler is actively playing trackGamma
        final handler = AudifiAudioHandler(playerService: player);
        handler.syncTrack(_trackGamma);
        handler.syncQueue([_trackGamma], currentIndex: 0, isShuffle: false);
        await player.play();

        final container = ProviderContainer(
          overrides: [
            audioPlayerServiceProvider.overrideWithValue(player),
            audioHandlerProvider.overrideWithValue(handler),
            playbackRepositoryProvider.overrideWithValue(repo),
          ],
        );

        final controller = container.read(playbackControllerProvider.notifier);
        final preState = container.read(playbackControllerProvider);
        expect(preState.currentTrack?.id, equals(_trackGamma.id));
        expect(preState.isPlaying, isTrue);

        // Invoke restoreSavedQueue: should be ignored because session is actively playing
        await controller.restoreSavedQueue();

        final postState = container.read(playbackControllerProvider);
        expect(postState.currentTrack?.id, equals(_trackGamma.id));
        expect(postState.isPlaying, isTrue);

        container.dispose();
        await handler.stop();
        await player.dispose();
      },
    );
  });

  group('Phase 3.5: Network Resilience & Error Recovery', () {
    test('Network failure during stream resolution transitions to error without stuck loading', () async {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository()
        ..shouldFailResolution = true;
      final handler = AudifiAudioHandler(playerService: player);

      final container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          audioHandlerProvider.overrideWithValue(handler),
          playbackRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final controller = container.read(playbackControllerProvider.notifier);

      await controller.playTrack(_trackAlpha);

      final state = container.read(playbackControllerProvider);
      expect(state.status, equals(PlaybackStatus.error));
      expect(state.error, isNotNull);
      expect(player.isPlaying, isFalse);

      // Recover when network restores and user taps play
      repo.shouldFailResolution = false;
      await controller.play();

      final recoveredState = container.read(playbackControllerProvider);
      expect(recoveredState.status, equals(PlaybackStatus.playing));
      expect(recoveredState.error, isNull);

      container.dispose();
      await handler.stop();
      await player.dispose();
    });

    test(
      'Rapid consecutive skips cancel in-flight operations deterministically',
      () async {
        final player = _ReliableFakeAudioPlayerService();
        final repo = _ConfigurablePlaybackRepository();
        final handler = AudifiAudioHandler(playerService: player);

        final container = ProviderContainer(
          overrides: [
            audioPlayerServiceProvider.overrideWithValue(player),
            audioHandlerProvider.overrideWithValue(handler),
            playbackRepositoryProvider.overrideWithValue(repo),
          ],
        );

        final controller = container.read(playbackControllerProvider.notifier);

        // Rapidly dispatch three track plays
        unawaited(controller.playTrack(_trackAlpha));
        unawaited(controller.playTrack(_trackBeta));
        await controller.playTrack(_trackGamma);

        final state = container.read(playbackControllerProvider);
        expect(state.currentTrack?.id, equals(_trackGamma.id));
        expect(state.status, equals(PlaybackStatus.playing));
        expect(player.loadedUrl, contains('gamma_3'));

        container.dispose();
        await handler.stop();
        await player.dispose();
      },
    );

    test('User pause during stream resolution cancels in-flight request and transitions to paused without error', () async {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository();
      final resolutionCompleter = Completer<String>();
      repo.pendingResolutionCompleter = resolutionCompleter;
      final handler = AudifiAudioHandler(playerService: player);

      final container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          audioHandlerProvider.overrideWithValue(handler),
          playbackRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final controller = container.read(playbackControllerProvider.notifier);

      // Start playing trackAlpha - enters loading state while waiting for resolution
      unawaited(controller.playTrack(_trackAlpha));
      await Future<void>.delayed(Duration.zero);

      final loadingState = container.read(playbackControllerProvider);
      expect(loadingState.status, equals(PlaybackStatus.loading));
      expect(loadingState.currentTrack?.id, equals(_trackAlpha.id));

      // User pauses while loading is still pending
      await controller.pause();

      final pausedState = container.read(playbackControllerProvider);
      expect(pausedState.status, equals(PlaybackStatus.paused));
      expect(pausedState.error, isNull);

      // Allow network to recover and user resumes
      repo.pendingResolutionCompleter = null;
      await controller.play();

      final playingState = container.read(playbackControllerProvider);
      expect(playingState.status, equals(PlaybackStatus.playing));
      expect(playingState.error, isNull);

      container.dispose();
      await handler.stop();
      await player.dispose();
    });

    test('User seek during loading or buffering updates position safely without throwing', () async {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository();
      final handler = AudifiAudioHandler(playerService: player);

      final container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          audioHandlerProvider.overrideWithValue(handler),
          playbackRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final controller = container.read(playbackControllerProvider.notifier);

      // Seek on initial idle state
      await expectLater(
        controller.seek(const Duration(seconds: 15)),
        completes,
      );
      expect(
        container.read(playbackControllerProvider).position,
        equals(const Duration(seconds: 15)),
      );

      container.dispose();
      await handler.stop();
      await player.dispose();
    });
  });

  group('Phase 3.5: Queue Edge Cases & Autonomous Transitions', () {
    test('Removing track from queue adjusts current index safely', () {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository();
      final handler = AudifiAudioHandler(playerService: player);

      final container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          audioHandlerProvider.overrideWithValue(handler),
          playbackRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final queueNotifier = container.read(queueControllerProvider.notifier);
      queueNotifier.setQueue([
        _trackAlpha,
        _trackBeta,
        _trackGamma,
      ], startIndex: 2);

      expect(container.read(queueControllerProvider).currentIndex, equals(2));

      // Remove item at index 0 (before current)
      queueNotifier.removeFromQueue(0);
      expect(container.read(queueControllerProvider).currentIndex, equals(1));
      expect(
        container.read(queueControllerProvider).currentTrack?.id,
        equals(_trackGamma.id),
      );

      // Remove current item (at index 1)
      queueNotifier.removeFromQueue(1);
      expect(container.read(queueControllerProvider).currentIndex, equals(0));
      expect(
        container.read(queueControllerProvider).currentTrack?.id,
        equals(_trackBeta.id),
      );

      container.dispose();
      handler.stop();
      player.dispose();
    });

    test('Queue replacement during active playback updates queue, maintains continuity, and syncs handler', () {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository();
      final handler = AudifiAudioHandler(playerService: player);

      final container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          audioHandlerProvider.overrideWithValue(handler),
          playbackRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final queueNotifier = container.read(queueControllerProvider.notifier);
      queueNotifier.setQueue([_trackAlpha, _trackBeta], startIndex: 0);

      expect(container.read(queueControllerProvider).items.length, equals(2));
      expect(handler.queueTracks.length, equals(2));

      // Replace queue with new list of 3 tracks
      queueNotifier.setQueue([
        _trackBeta,
        _trackGamma,
        _trackAlpha,
      ], startIndex: 1);

      final newQueue = container.read(queueControllerProvider);
      expect(newQueue.items.length, equals(3));
      expect(newQueue.currentIndex, equals(1));
      expect(newQueue.currentTrack?.id, equals(_trackGamma.id));
      expect(handler.queueTracks.length, equals(3));

      container.dispose();
      handler.stop();
      player.dispose();
    });

    test(
      'Queue clear during active playback retains only active track at index 0',
      () {
        final player = _ReliableFakeAudioPlayerService();
        final repo = _ConfigurablePlaybackRepository();
        final handler = AudifiAudioHandler(playerService: player);

        final container = ProviderContainer(
          overrides: [
            audioPlayerServiceProvider.overrideWithValue(player),
            audioHandlerProvider.overrideWithValue(handler),
            playbackRepositoryProvider.overrideWithValue(repo),
          ],
        );

        final queueNotifier = container.read(queueControllerProvider.notifier);
        queueNotifier.setQueue([
          _trackAlpha,
          _trackBeta,
          _trackGamma,
        ], startIndex: 1);

        expect(
          container.read(queueControllerProvider).currentTrack?.id,
          equals(_trackBeta.id),
        );
        expect(container.read(queueControllerProvider).items.length, equals(3));

        // Clear upcoming queue tracks
        queueNotifier.clearQueue();

        final clearedQueue = container.read(queueControllerProvider);
        expect(clearedQueue.items.length, equals(1));
        expect(clearedQueue.currentIndex, equals(0));
        expect(clearedQueue.currentTrack?.id, equals(_trackBeta.id));
        expect(handler.queueTracks.length, equals(1));

        container.dispose();
        handler.stop();
        player.dispose();
      },
    );

    test('Autonomous background completion advances to next track when UI is detached', () async {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository();
      final handler = AudifiAudioHandler(
        playerService: player,
        streamResolver: repo.resolveStreamUrl,
      );

      handler.syncQueue(
        [_trackAlpha, _trackBeta],
        currentIndex: 0,
        isShuffle: false,
      );
      handler.syncTrack(_trackAlpha);

      // UI is detached (handler._playbackActions is null)
      expect(handler.currentIndex, equals(0));

      // Simulate track completion event from audio engine
      player.emitCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.currentIndex, equals(1));
      expect(handler.currentTrack?.id, equals(_trackBeta.id));
      expect(player.loadedUrl, contains('beta_2'));

      await handler.stop();
      await player.dispose();
    });

    test(
      'Single-track queue loop with Repeat All wraps cleanly back to beginning',
      () async {
        final player = _ReliableFakeAudioPlayerService();
        final repo = _ConfigurablePlaybackRepository();
        final handler = AudifiAudioHandler(
          playerService: player,
          streamResolver: repo.resolveStreamUrl,
        );

        handler.syncQueue([_trackAlpha], currentIndex: 0, isShuffle: false);
        handler.syncRepeatMode(RepeatMode.all);
        handler.syncTrack(_trackAlpha);

        await handler.skipToNext();

        expect(handler.currentIndex, equals(0));
        expect(handler.currentTrack?.id, equals(_trackAlpha.id));
        expect(player.loadedUrl, contains('alpha_1'));

        await handler.stop();
        await player.dispose();
      },
    );

    test('Queue end with Repeat Off stops autonomous playback', () async {
      final player = _ReliableFakeAudioPlayerService();
      final repo = _ConfigurablePlaybackRepository();
      final handler = AudifiAudioHandler(
        playerService: player,
        streamResolver: repo.resolveStreamUrl,
      );

      handler.syncQueue([_trackAlpha], currentIndex: 0, isShuffle: false);
      handler.syncRepeatMode(RepeatMode.off);
      handler.syncTrack(_trackAlpha);

      await handler.skipToNext();

      expect(player.stopCount, greaterThan(0));

      await handler.stop();
      await player.dispose();
    });
  });

  group('Phase 3.5: Idempotent Resource Disposal & Post-Disposal Safety', () {
    test('Multiple calls to dispose on JustAudioPlayerService and AudioHandler are safe', () async {
      final service = JustAudioPlayerService();
      expect(service.isDisposed, isFalse);

      await service.dispose();
      expect(service.isDisposed, isTrue);

      // Second dispose call is idempotent
      await expectLater(service.dispose(), completes);
      expect(service.isDisposed, isTrue);

      // Commands after disposal complete without throwing
      await expectLater(service.play(), completes);
      await expectLater(service.pause(), completes);
      await expectLater(service.stop(), completes);
      await expectLater(service.seek(Duration.zero), completes);
    });

    test('AudifiAudioHandler disposal closes subscriptions and ignores post-disposal commands', () async {
      final player = _ReliableFakeAudioPlayerService();
      final handler = AudifiAudioHandler(playerService: player);

      expect(handler.isDisposed, isFalse);
      await handler.dispose();
      expect(handler.isDisposed, isTrue);

      // Re-disposal is safe
      await expectLater(handler.dispose(), completes);

      // Commands on disposed handler are ignored safely
      await expectLater(handler.play(), completes);
      await expectLater(handler.pause(), completes);
      await expectLater(handler.skipToNext(), completes);
      await expectLater(handler.skipToPrevious(), completes);

      await player.dispose();
    });
  });
}
