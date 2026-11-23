import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:audio_service/audio_service.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audifi_audio_handler.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
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
    _position = Duration.zero;
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
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() async {
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

  void emitProcessingState(EngineProcessingState state) {
    _processingController.add(state);
  }

  void emitCompleted() {
    _completedController.add(null);
  }
}

class _StubPlaybackRepository implements PlaybackRepository {
  Completer<String>? pendingResolutionCompleter;
  int resolutionCallCount = 0;
  bool shouldFailResolution = false;

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

  late ProviderContainer container;
  late _FakeAudioPlayerService fakePlayer;
  late _StubPlaybackRepository stubRepo;
  late AudifiAudioHandler handler;

  const track1 = Track(
    id: 'track_1',
    title: 'Track One',
    duration: 180,
    genre: 'Synthwave',
    artwork: Artwork(medium: 'https://audius.co/art/1.jpg'),
    user: User(id: 'u1', name: 'Artist 1', handle: 'artist1'),
  );

  const track2 = Track(
    id: 'track_2',
    title: 'Track Two',
    duration: 200,
    genre: 'Chillstep',
    artwork: Artwork(medium: 'https://audius.co/art/2.jpg'),
    user: User(id: 'u2', name: 'Artist 2', handle: 'artist2'),
  );

  const track3 = Track(
    id: 'track_3',
    title: 'Track Three',
    duration: 220,
    genre: 'Electronic',
    artwork: Artwork(medium: 'https://audius.co/art/3.jpg'),
    user: User(id: 'u3', name: 'Artist 3', handle: 'artist3'),
  );

  final testQueue = [track1, track2, track3];

  setUp(() {
    fakePlayer = _FakeAudioPlayerService();
    stubRepo = _StubPlaybackRepository();
    handler = AudifiAudioHandler(playerService: fakePlayer);

    container = ProviderContainer(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(fakePlayer),
        playbackRepositoryProvider.overrideWithValue(stubRepo),
        audioHandlerProvider.overrideWithValue(handler),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await handler.dispose();
    await fakePlayer.dispose();
  });

  group('Phase 3.3: MediaSession Configuration & Capability Advertising', () {
    test(
      'declares comprehensive systemActions for all Android media clients',
      () {
        final state = handler.playbackState.value;

        expect(state.systemActions.contains(MediaAction.play), isTrue);
        expect(state.systemActions.contains(MediaAction.pause), isTrue);
        expect(state.systemActions.contains(MediaAction.playPause), isTrue);
        expect(state.systemActions.contains(MediaAction.stop), isTrue);
        expect(state.systemActions.contains(MediaAction.seek), isTrue);
        expect(state.systemActions.contains(MediaAction.skipToNext), isTrue);
        expect(
          state.systemActions.contains(MediaAction.skipToPrevious),
          isTrue,
        );
        expect(
          state.systemActions.contains(MediaAction.skipToQueueItem),
          isTrue,
        );
        expect(state.systemActions.contains(MediaAction.setRepeatMode), isTrue);
        expect(
          state.systemActions.contains(MediaAction.setShuffleMode),
          isTrue,
        );
      },
    );

    test(
      'androidCompactActionIndices maintains previous, play/pause, next layout',
      () {
        final state = handler.playbackState.value;
        expect(state.androidCompactActionIndices, equals([0, 1, 2]));
        expect(state.controls[0].action, equals(MediaAction.skipToPrevious));
        expect(state.controls[1].action, equals(MediaAction.play));
        expect(state.controls[2].action, equals(MediaAction.skipToNext));
      },
    );
  });

  group('Phase 3.3: Play/Pause Edge Cases & Concurrency', () {
    test(
      'handler.play and handler.pause maintain accurate playback state',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(track1, contextTracks: testQueue);

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.playing),
        );
        expect(handler.playbackState.value.playing, isTrue);

        await handler.pause();
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.paused),
        );
        expect(handler.playbackState.value.playing, isFalse);

        await handler.play();
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.playing),
        );
        expect(handler.playbackState.value.playing, isTrue);
      },
    );

    test(
      'click(MediaButton.media) toggles between playing and paused',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(track1, contextTracks: testQueue);

        expect(fakePlayer.isPlaying, isTrue);

        // Hardware media key click when playing -> pause
        await handler.click(MediaButton.media);
        expect(fakePlayer.isPlaying, isFalse);
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.paused),
        );

        // Hardware media key click when paused -> play
        await handler.click(MediaButton.media);
        expect(fakePlayer.isPlaying, isTrue);
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.playing),
        );
      },
    );

    test(
      'pause while loading cancels stream resolution and keeps player paused',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        stubRepo.pendingResolutionCompleter = Completer<String>();

        // Initiate playTrack (which will await pending stream resolution)
        final playFuture = controller.playTrack(
          track1,
          contextTracks: testQueue,
        );
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.loading),
        );

        // External pause arrives while track is still resolving URL
        await handler.pause();

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.paused),
        );
        expect(fakePlayer.isPlaying, isFalse);

        // Complete pending resolution safely if not already completed by cancelToken
        if (!stubRepo.pendingResolutionCompleter!.isCompleted) {
          stubRepo.pendingResolutionCompleter!.complete(
            'https://audius.co/stream/track_1.mp3',
          );
        }
        await playFuture;

        // Player must remain paused and must NOT have invoked play()
        expect(fakePlayer.isPlaying, isFalse);
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.paused),
        );
      },
    );

    test(
      'play after playback error re-attempts URL resolution and playback',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);

        // Simulate network failure on initial play
        stubRepo.shouldFailResolution = true;
        await controller.playTrack(track1, contextTracks: testQueue);

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.error),
        );

        // Recover network and invoke play() from external control
        stubRepo.shouldFailResolution = false;
        await handler.play();

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.playing),
        );
        expect(
          container.read(playbackControllerProvider).currentTrack?.id,
          equals('track_1'),
        );
        expect(fakePlayer.isPlaying, isTrue);
      },
    );

    test(
      'completed track restart via external play() seeks to Duration.zero',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(track1, contextTracks: testQueue);

        // Simulate track completion
        fakePlayer.emitPosition(const Duration(seconds: 180));
        controller.state = controller.state.copyWith(
          status: PlaybackStatus.completed,
          position: const Duration(seconds: 180),
        );

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.completed),
        );

        // External Play command
        await handler.play();

        expect(fakePlayer.lastSeekPosition, equals(Duration.zero));
        expect(fakePlayer.currentPosition, equals(Duration.zero));
        expect(fakePlayer.isPlaying, isTrue);
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.playing),
        );
      },
    );

    test(
      'empty queue external commands complete safely without exception',
      () async {
        // Empty queue state
        await handler.play();
        await handler.pause();
        await handler.click(MediaButton.media);
        await handler.skipToNext();
        await handler.skipToPrevious();
        await handler.seek(const Duration(seconds: 30));

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.idle),
        );
        expect(handler.mediaItem.value, isNull);
      },
    );
  });

  group('Phase 3.3: Authoritative Queue Traversal & Shuffle Navigation', () {
    test('skipToNext and skipToPrevious follow sequential order when shuffle is disabled', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(track1, contextTracks: testQueue);

      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_1'),
      );

      await handler.skipToNext();
      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_2'),
      );
      expect(handler.mediaItem.value?.id, equals('track_2'));

      await handler.skipToNext();
      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_3'),
      );

      // 3-second restart rule: > 3s rewinds current track
      fakePlayer.emitPosition(const Duration(seconds: 10));
      await pumpEventQueue();
      await handler.skipToPrevious();
      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_3'),
      );
      expect(fakePlayer.lastSeekPosition, equals(Duration.zero));

      // <= 3s steps to previous track
      fakePlayer.emitPosition(const Duration(seconds: 1));
      await pumpEventQueue();
      await handler.skipToPrevious();
      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_2'),
      );
    });

    test(
      'skipToNext in shuffle mode respects authoritative shuffledIndices',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(track1, contextTracks: testQueue);

        // Enable shuffle mode
        controller.toggleShuffle();
        final q = container.read(queueControllerProvider);
        expect(q.isShuffleEnabled, isTrue);
        expect(handler.isShuffle, isTrue);
        expect(handler.shuffledIndices, equals(q.shuffledIndices));

        // Predict next track based on shuffle sequence
        final expectedNextTrack = q.getNextTrack();
        expect(expectedNextTrack, isNotNull);

        // Invoke external skipToNext
        await handler.skipToNext();

        expect(
          container.read(playbackControllerProvider).currentTrack?.id,
          equals(expectedNextTrack!.id),
        );
        expect(handler.mediaItem.value?.id, equals(expectedNextTrack.id));
      },
    );

    test('autonomous handler preserves authoritative shuffle order without UI attached', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(track1, contextTracks: testQueue);
      controller.toggleShuffle();

      final activeShuffled = container
          .read(queueControllerProvider)
          .shuffledIndices;
      expect(handler.shuffledIndices, equals(activeShuffled));

      // Detach UI actions to simulate autonomous background state
      handler.detachPlaybackActions();

      String? autonomousResolvedId;
      handler.setStreamResolver((id) async {
        autonomousResolvedId = id;
        return 'https://stream/$id';
      });

      // Find which track comes next in activeShuffled
      final currentPos = activeShuffled.indexOf(handler.currentIndex);
      final expectedIdx = activeShuffled[currentPos + 1];
      final expectedTrack = testQueue[expectedIdx];

      await handler.skipToNext();

      expect(handler.currentIndex, equals(expectedIdx));
      expect(handler.currentTrack?.id, equals(expectedTrack.id));
      expect(autonomousResolvedId, equals(expectedTrack.id));
      expect(handler.mediaItem.value?.id, equals(expectedTrack.id));
    });

    test('rehydrating QueueController from AudioHandler preserves exact shuffle permutation', () {
      handler.syncQueue(
        testQueue,
        currentIndex: 1,
        isShuffle: true,
        shuffledIndices: const [1, 2, 0],
      );

      final newContainer = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(fakePlayer),
          playbackRepositoryProvider.overrideWithValue(stubRepo),
          audioHandlerProvider.overrideWithValue(handler),
        ],
      );
      addTearDown(newContainer.dispose);

      final rehydratedQueue = newContainer.read(queueControllerProvider);
      expect(rehydratedQueue.isShuffleEnabled, isTrue);
      expect(rehydratedQueue.currentIndex, equals(1));
      expect(rehydratedQueue.shuffledIndices, equals([1, 2, 0]));
      expect(rehydratedQueue.currentTrack?.id, equals('track_2'));
    });

    test('rapid skips cancel in-flight URL resolutions and settle on latest command', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(track1, contextTracks: testQueue);

      // Dispatch rapid external skipToNext calls without awaiting each
      final f1 = handler.skipToNext();
      final f2 = handler.skipToNext();
      await Future.wait([f1, f2]);

      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_3'),
      );
      expect(handler.mediaItem.value?.id, equals('track_3'));
      expect(fakePlayer.isPlaying, isTrue);
    });

    test(
      'repeat modes: repeat One replays current track, repeat All wraps around',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(track3, contextTracks: testQueue);

        // Repeat One
        await handler.setRepeatMode(AudioServiceRepeatMode.one);
        expect(
          container.read(playbackControllerProvider).repeatMode,
          equals(RepeatMode.one),
        );

        await handler.skipToNext();
        // Must replay current track from zero
        expect(
          container.read(playbackControllerProvider).currentTrack?.id,
          equals('track_3'),
        );
        expect(fakePlayer.lastSeekPosition, equals(Duration.zero));

        // Repeat All at end of queue wraps to first track
        await handler.setRepeatMode(AudioServiceRepeatMode.all);
        expect(
          container.read(playbackControllerProvider).repeatMode,
          equals(RepeatMode.all),
        );

        await handler.skipToNext();
        expect(
          container.read(playbackControllerProvider).currentTrack?.id,
          equals('track_1'),
        );

        // Repeat Off at end of queue stops playback
        await handler.setRepeatMode(AudioServiceRepeatMode.none);
        await controller.skipToQueueItem(2); // track3
        await handler.skipToNext();

        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.completed),
        );
        expect(fakePlayer.isPlaying, isFalse);
      },
    );
  });

  group('Phase 3.3: External Seek Synchronization & Bounds Protection', () {
    test('seek synchronizes position to player and media session', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(track1, contextTracks: testQueue);

      const targetPos = Duration(seconds: 45);
      await handler.seek(targetPos);

      expect(fakePlayer.currentPosition, equals(targetPos));
      expect(
        container.read(playbackControllerProvider).position,
        equals(targetPos),
      );
      expect(handler.playbackState.value.updatePosition, equals(targetPos));
    });

    test(
      'negative seek positions clamp defensively to Duration.zero',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(track1, contextTracks: testQueue);

        await handler.seek(const Duration(seconds: -15));

        expect(fakePlayer.currentPosition, equals(Duration.zero));
        expect(
          container.read(playbackControllerProvider).position,
          equals(Duration.zero),
        );
        expect(
          handler.playbackState.value.updatePosition,
          equals(Duration.zero),
        );
      },
    );

    test('seek while paused preserves paused playback status', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(track1, contextTracks: testQueue);
      await handler.pause();

      expect(fakePlayer.isPlaying, isFalse);

      await handler.seek(const Duration(seconds: 60));

      expect(fakePlayer.isPlaying, isFalse);
      expect(fakePlayer.currentPosition, equals(const Duration(seconds: 60)));
      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.paused),
      );
    });
  });
}
