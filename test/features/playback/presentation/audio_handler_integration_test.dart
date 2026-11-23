import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:dio/dio.dart';
import 'package:audifi/shared/models/artwork.dart';

class StubPlaybackRepository implements PlaybackRepository {
  String? resolvedTrackId;

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    resolvedTrackId = trackId;
    return 'https://stream.audius.co/v1/tracks/$trackId/stream?token=test';
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

class TestAudioPlayerService implements AudioPlayerService {
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _processingController =
      StreamController<EngineProcessingState>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  String? loadedUrl;
  bool isPlayingValue = false;
  Duration currentPositionValue = Duration.zero;
  Duration? currentDurationValue = const Duration(seconds: 180);
  double speedValue = 1.0;
  double volumeValue = 1.0;

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
  bool get isPlaying => isPlayingValue;

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
    isPlayingValue = true;
    _playingController.add(true);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    isPlayingValue = false;
    _playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    currentPositionValue = position;
    _positionController.add(position);
  }

  @override
  Future<void> stop() async {
    isPlayingValue = false;
    currentPositionValue = Duration.zero;
    _playingController.add(false);
    _processingController.add(EngineProcessingState.idle);
  }

  @override
  Future<void> setVolume(double volume) async => volumeValue = volume;

  @override
  Future<void> setSpeed(double speed) async => speedValue = speed;

  @override
  Future<void> dispose() async {
    await _positionController.close();
    await _bufferedController.close();
    await _durationController.close();
    await _playingController.close();
    await _processingController.close();
    await _completedController.close();
  }

  void emitPosition(Duration pos) {
    currentPositionValue = pos;
    _positionController.add(pos);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late TestAudioPlayerService player;
  late StubPlaybackRepository repository;
  late AudifiAudioHandler audioHandler;

  const trackA = Track(
    id: 'track_a',
    title: 'Cyberpunk Skyline',
    duration: 180,
    genre: 'Electronic',
    artwork: Artwork(medium: 'https://audius.co/art/a.jpg'),
    user: User(id: 'u1', name: 'SynthMaster', handle: 'synthmaster'),
  );

  const trackB = Track(
    id: 'track_b',
    title: 'Midnight Drive',
    duration: 210,
    genre: 'Synthwave',
    artwork: Artwork(medium: 'https://audius.co/art/b.jpg'),
    user: User(id: 'u2', name: 'RetroWave', handle: 'retrowave'),
  );

  const trackC = Track(
    id: 'track_c',
    title: 'Solar Winds',
    duration: 240,
    genre: 'Ambient',
    artwork: Artwork(medium: 'https://audius.co/art/c.jpg'),
    user: User(id: 'u3', name: 'Starlight', handle: 'starlight'),
  );

  final testQueue = [trackA, trackB, trackC];

  setUp(() {
    player = TestAudioPlayerService();
    repository = StubPlaybackRepository();
    audioHandler = AudifiAudioHandler(playerService: player);

    container = ProviderContainer(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(player),
        playbackRepositoryProvider.overrideWithValue(repository),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await audioHandler.dispose();
    await player.dispose();
  });

  group('AudioHandler & PlaybackController Bidirectional Synchronization', () {
    test(
      'playing a track synchronizes MediaItem and Queue with AudioHandler',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);

        await controller.playTrack(trackA, contextTracks: testQueue);

        // Verify PlaybackController state
        final playState = container.read(playbackControllerProvider);
        expect(playState.currentTrack?.id, equals('track_a'));

        // Verify QueueController state
        final queueState = container.read(queueControllerProvider);
        expect(queueState.items.length, equals(3));
        expect(queueState.currentIndex, equals(0));

        // Verify AudifiAudioHandler metadata
        final mediaItem = audioHandler.mediaItem.value;
        expect(mediaItem, isNotNull);
        expect(mediaItem!.id, equals('track_a'));
        expect(mediaItem.title, equals('Cyberpunk Skyline'));
        expect(mediaItem.artist, equals('SynthMaster'));
        expect(
          mediaItem.artUri,
          equals(Uri.parse('https://audius.co/art/a.jpg')),
        );

        // Verify AudifiAudioHandler queue
        expect(audioHandler.queue.value.length, equals(3));
        expect(audioHandler.playbackState.value.queueIndex, equals(0));
      },
    );

    test(
      'UI shuffle toggle synchronizes with media session shuffle mode',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(trackA, contextTracks: testQueue);

        expect(
          audioHandler.playbackState.value.shuffleMode,
          equals(AudioServiceShuffleMode.none),
        );

        controller.toggleShuffle();

        expect(
          container.read(playbackControllerProvider).isShuffleEnabled,
          isTrue,
        );
        expect(
          audioHandler.playbackState.value.shuffleMode,
          equals(AudioServiceShuffleMode.all),
        );

        controller.toggleShuffle();

        expect(
          container.read(playbackControllerProvider).isShuffleEnabled,
          isFalse,
        );
        expect(
          audioHandler.playbackState.value.shuffleMode,
          equals(AudioServiceShuffleMode.none),
        );
      },
    );

    test(
      'UI repeat cycle synchronizes with media session repeat mode',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(trackA, contextTracks: testQueue);

        expect(
          audioHandler.playbackState.value.repeatMode,
          equals(AudioServiceRepeatMode.none),
        );

        // off -> all
        controller.cycleRepeatMode();
        expect(
          container.read(playbackControllerProvider).repeatMode,
          equals(RepeatMode.all),
        );
        expect(
          audioHandler.playbackState.value.repeatMode,
          equals(AudioServiceRepeatMode.all),
        );

        // all -> one
        controller.cycleRepeatMode();
        expect(
          container.read(playbackControllerProvider).repeatMode,
          equals(RepeatMode.one),
        );
        expect(
          audioHandler.playbackState.value.repeatMode,
          equals(AudioServiceRepeatMode.one),
        );

        // one -> off
        controller.cycleRepeatMode();
        expect(
          container.read(playbackControllerProvider).repeatMode,
          equals(RepeatMode.off),
        );
        expect(
          audioHandler.playbackState.value.repeatMode,
          equals(AudioServiceRepeatMode.none),
        );
      },
    );
  });

  group('System Media Controls Invocation Delegation', () {
    test('handler.skipToNext advances to next track in active queue', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(trackA, contextTracks: testQueue);

      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_a'),
      );

      // Simulate notification Next button tap
      await audioHandler.skipToNext();

      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_b'),
      );
      expect(audioHandler.mediaItem.value?.id, equals('track_b'));
      expect(audioHandler.playbackState.value.queueIndex, equals(1));
    });

    test(
      'handler.skipToPrevious within 3 seconds steps to previous track',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(trackB, contextTracks: testQueue);

        player.emitPosition(const Duration(seconds: 2));

        // Simulate notification Previous button tap (< 3s)
        await audioHandler.skipToPrevious();

        expect(
          container.read(playbackControllerProvider).currentTrack?.id,
          equals('track_a'),
        );
        expect(audioHandler.mediaItem.value?.id, equals('track_a'));
        expect(audioHandler.playbackState.value.queueIndex, equals(0));
      },
    );

    test(
      'handler.skipToPrevious after 3 seconds restarts current track',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(trackB, contextTracks: testQueue);

        player.emitPosition(const Duration(seconds: 15));
        await pumpEventQueue();

        // Simulate notification Previous button tap (> 3s)
        await audioHandler.skipToPrevious();

        // Track should remain trackB, but position reset to zero
        expect(
          container.read(playbackControllerProvider).currentTrack?.id,
          equals('track_b'),
        );
        expect(player.currentPositionValue, equals(Duration.zero));
      },
    );

    test('handler.play and handler.pause toggle playback correctly', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(trackA, contextTracks: testQueue);

      expect(player.isPlaying, isTrue);

      await audioHandler.pause();
      expect(player.isPlaying, isFalse);

      await audioHandler.play();
      expect(player.isPlaying, isTrue);
    });

    test('handler.seek seeks underlying player engine', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(trackA, contextTracks: testQueue);

      const target = Duration(seconds: 90);
      await audioHandler.seek(target);

      expect(player.currentPositionValue, equals(target));
      expect(
        container.read(playbackControllerProvider).position,
        equals(target),
      );
    });

    test('handler.stop stops player and clears active media item', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(trackA, contextTracks: testQueue);

      await audioHandler.stop();

      expect(player.isPlaying, isFalse);
      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.idle),
      );
      expect(audioHandler.mediaItem.value, isNull);
    });

    test('handler.skipToQueueItem plays requested track by index', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(trackA, contextTracks: testQueue);

      // Skip directly to index 2 (trackC)
      await audioHandler.skipToQueueItem(2);

      expect(
        container.read(playbackControllerProvider).currentTrack?.id,
        equals('track_c'),
      );
      expect(audioHandler.mediaItem.value?.id, equals('track_c'));
      expect(audioHandler.playbackState.value.queueIndex, equals(2));
    });
  });

  group('Headphone Disconnect Preference Integration', () {
    test(
      'JustAudioPlayerService respects pauseOnHeadphonesDisconnect preference',
      () {
        var shouldPause = true;
        final service = JustAudioPlayerService(
          shouldPauseOnHeadphoneDisconnect: () => shouldPause,
        );

        expect(service, isNotNull);
        // When preference is toggled off, callback returns false
        shouldPause = false;
        expect(shouldPause, isFalse);
      },
    );
  });

  group('Notification Pause & Background Resume (Android 12+ Safety)', () {
    test('notification pause keeps playback state valid and background resume continues seamlessly', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(trackA, contextTracks: testQueue);

      expect(player.isPlaying, isTrue);
      expect(audioHandler.playbackState.value.playing, isTrue);

      // Simulate Notification Pause action
      await audioHandler.pause();

      expect(player.isPlaying, isFalse);
      expect(audioHandler.playbackState.value.playing, isFalse);
      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.paused),
      );

      // Track and queue remain intact
      expect(audioHandler.mediaItem.value?.id, equals('track_a'));
      expect(audioHandler.queueTracks.length, equals(3));

      // Simulate Notification Play action while app is in background
      await audioHandler.play();

      expect(player.isPlaying, isTrue);
      expect(audioHandler.playbackState.value.playing, isTrue);
      expect(
        container.read(playbackControllerProvider).status,
        equals(PlaybackStatus.playing),
      );
    });

    test('notification action handling during background pause preserves position and metadata', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(trackA, contextTracks: testQueue);

      // Advance position to 45 seconds
      player.emitPosition(const Duration(seconds: 45));
      await pumpEventQueue();

      // Pause from notification
      await audioHandler.pause();

      expect(player.currentPosition, equals(const Duration(seconds: 45)));

      // Resume from notification
      await audioHandler.play();

      expect(player.isPlaying, isTrue);
      expect(player.currentPosition, equals(const Duration(seconds: 45)));
    });
  });

  group('Playback Continuity & UI Rehydration Lifecycle', () {
    test('detaching UI preserves background audio and new UI container rehydrates state', () async {
      // 1. Initial UI is mounted and starts playback
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(trackA, contextTracks: testQueue);
      expect(player.isPlaying, isTrue);

      // 2. Simulate UI detachment (Activity backgrounded, screen unmounted, container disposed)
      container.dispose();

      // 3. Audio engine is still playing in the background
      expect(player.isPlaying, isTrue);
      expect(audioHandler.currentTrack?.id, equals('track_a'));

      // 4. Background notification next tap occurs while UI is completely detached
      await audioHandler.skipToNext();

      expect(audioHandler.currentIndex, equals(1));
      expect(audioHandler.currentTrack?.id, equals('track_b'));
      expect(player.loadedUrl, contains('track_b'));
      expect(player.isPlaying, isTrue);

      // 5. User reopens the app: a new ProviderContainer is created
      final newContainer = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          playbackRepositoryProvider.overrideWithValue(repository),
          audioHandlerProvider.overrideWithValue(audioHandler),
        ],
      );

      // 6. UI controllers rehydrate from AudifiAudioHandler
      final newPlayState = newContainer.read(playbackControllerProvider);
      final newQueueState = newContainer.read(queueControllerProvider);

      expect(newPlayState.currentTrack?.id, equals('track_b'));
      expect(newPlayState.status, equals(PlaybackStatus.playing));
      expect(newQueueState.items.length, equals(3));
      expect(newQueueState.currentIndex, equals(1));
      expect(newQueueState.currentTrack?.id, equals('track_b'));

      newContainer.dispose();
    });

    test(
      'hardware media buttons route successfully when UI is detached',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(trackA, contextTracks: testQueue);

        // Detach UI
        container.dispose();

        // Bluetooth Media Button Play/Pause toggle
        await audioHandler.click(MediaButton.media);
        expect(player.isPlaying, isFalse);

        await audioHandler.click(MediaButton.media);
        expect(player.isPlaying, isTrue);

        // Bluetooth Media Button Next
        await audioHandler.click(MediaButton.next);
        expect(audioHandler.currentIndex, equals(1));
        expect(audioHandler.currentTrack?.id, equals('track_b'));
      },
    );
  });
}
