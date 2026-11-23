import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/data/services/audifi_audio_handler.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/domain/entities/repeat_mode.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/models/artwork.dart';

class FakeAudioPlayerService implements AudioPlayerService {
  final _processingController =
      StreamController<EngineProcessingState>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  bool isPlayingValue = false;
  Duration currentPositionValue = Duration.zero;
  Duration? currentDurationValue = const Duration(seconds: 180);
  double speedValue = 1.0;
  double volumeValue = 1.0;
  String? urlValue;

  bool playCalled = false;
  bool pauseCalled = false;
  bool stopCalled = false;
  Duration? seekCalledWith;

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
    urlValue = url;
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> play() async {
    playCalled = true;
    isPlayingValue = true;
    _playingController.add(true);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    isPlayingValue = false;
    _playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalledWith = position;
    currentPositionValue = position;
    _positionController.add(position);
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    isPlayingValue = false;
    currentPositionValue = Duration.zero;
    _playingController.add(false);
    _processingController.add(EngineProcessingState.idle);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumeValue = volume;
  }

  @override
  Future<void> setSpeed(double speed) async {
    speedValue = speed;
  }

  @override
  Future<void> dispose() async {
    await _processingController.close();
    await _playingController.close();
    await _positionController.close();
    await _bufferedController.close();
    await _durationController.close();
    await _completedController.close();
  }

  void emitProcessingState(EngineProcessingState state) =>
      _processingController.add(state);
  void emitPlaying(bool playing) {
    isPlayingValue = playing;
    _playingController.add(playing);
  }

  void emitPosition(Duration pos) {
    currentPositionValue = pos;
    _positionController.add(pos);
  }

  void emitBuffered(Duration buf) => _bufferedController.add(buf);
  void emitDuration(Duration? dur) => _durationController.add(dur);
  void emitCompleted() => _completedController.add(null);
}

class FakePlaybackActions implements AudioHandlerPlaybackActions {
  bool isPlayingOrLoading = false;
  bool playCalled = false;
  bool pauseCalled = false;
  bool togglePlayPauseCalled = false;
  bool stopCalled = false;
  Duration? seekCalledWith;
  bool skipToNextCalled = false;
  bool skipToPreviousCalled = false;
  int? skipToQueueItemCalledWith;
  RepeatMode? setRepeatModeCalledWith;
  bool? setShuffleModeCalledWith;

  @override
  bool get isActivelyPlayingOrLoading => isPlayingOrLoading;

  @override
  Future<void> play() async => playCalled = true;

  @override
  Future<void> pause() async => pauseCalled = true;

  @override
  Future<void> togglePlayPause() async => togglePlayPauseCalled = true;

  @override
  Future<void> stop() async => stopCalled = true;

  @override
  Future<void> seek(Duration position) async => seekCalledWith = position;

  @override
  Future<void> skipToNext() async => skipToNextCalled = true;

  @override
  Future<void> skipToPrevious() async => skipToPreviousCalled = true;

  @override
  Future<void> skipToQueueItem(int index) async =>
      skipToQueueItemCalledWith = index;

  @override
  Future<void> setRepeatMode(RepeatMode repeatMode) async =>
      setRepeatModeCalledWith = repeatMode;

  @override
  Future<void> setShuffleMode(bool enabled) async =>
      setShuffleModeCalledWith = enabled;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioPlayerService playerService;
  late AudifiAudioHandler handler;

  setUp(() {
    playerService = FakeAudioPlayerService();
    handler = AudifiAudioHandler(playerService: playerService);
  });

  tearDown(() async {
    await handler.dispose();
    await playerService.dispose();
  });

  const testTrack = Track(
    id: 'track_123',
    title: 'Neon Odyssey',
    duration: 215,
    genre: 'Synthwave',
    artwork: Artwork(
      small: 'https://audius.co/art/small.jpg',
      medium: 'https://audius.co/art/medium.jpg',
      large: 'https://audius.co/art/large.jpg',
    ),
    user: User(id: 'artist_1', name: 'Cyber Voyager', handle: 'cybervoyager'),
  );

  group('AudifiAudioHandler Initialization', () {
    test('initializes with default playback state and compact controls', () {
      final state = handler.playbackState.value;

      expect(state.playing, isFalse);
      expect(state.processingState, equals(AudioProcessingState.idle));
      expect(state.speed, equals(1.0));
      expect(state.androidCompactActionIndices, equals([0, 1, 2]));
      expect(state.controls.length, equals(3));
      expect(state.controls[1].action, equals(MediaAction.play));
    });

    test('initial media item and queue are null and empty', () {
      expect(handler.mediaItem.value, isNull);
      expect(handler.queue.value, isEmpty);
    });
  });

  group('AudifiAudioHandler Delegation without Attached Actions', () {
    test('play, pause, stop delegate directly to playerService', () async {
      await handler.play();
      expect(playerService.playCalled, isTrue);

      await handler.pause();
      expect(playerService.pauseCalled, isTrue);

      await handler.stop();
      expect(playerService.stopCalled, isTrue);
    });

    test('seek delegates to playerService and forces state update', () async {
      const targetPos = Duration(seconds: 45);
      await handler.seek(targetPos);

      expect(playerService.seekCalledWith, equals(targetPos));
      expect(handler.playbackState.value.updatePosition, equals(targetPos));
    });

    test('setSpeed adjusts speed on engine and updates state', () async {
      await handler.setSpeed(1.5);

      expect(playerService.speedValue, equals(1.5));
      expect(handler.playbackState.value.speed, equals(1.5));
    });

    test(
      'click dispatches play/pause on playerService when actions null',
      () async {
        playerService.isPlayingValue = false;
        await handler.click(MediaButton.media);
        expect(playerService.playCalled, isTrue);

        playerService.isPlayingValue = true;
        await handler.click(MediaButton.media);
        expect(playerService.pauseCalled, isTrue);
      },
    );

    test(
      'autonomous skipToNext advances queue and loads resolved stream URL',
      () async {
        const track2 = Track(
          id: 'track_456',
          title: 'Future Echoes',
          duration: 180,
        );
        handler.syncQueue(
          [testTrack, track2],
          currentIndex: 0,
          isShuffle: false,
        );
        handler.syncTrack(testTrack);

        String? resolvedId;
        handler.setStreamResolver((id) async {
          resolvedId = id;
          return 'https://audius.co/stream/$id.mp3';
        });

        await handler.skipToNext();

        expect(resolvedId, equals('track_456'));
        expect(
          playerService.urlValue,
          equals('https://audius.co/stream/track_456.mp3'),
        );
        expect(playerService.playCalled, isTrue);
        expect(handler.mediaItem.value?.id, equals('track_456'));
        expect(handler.playbackState.value.queueIndex, equals(1));
        expect(handler.currentIndex, equals(1));
      },
    );

    test(
      'autonomous skipToPrevious steps back or restarts track based on 3s rule',
      () async {
        const track2 = Track(
          id: 'track_456',
          title: 'Future Echoes',
          duration: 180,
        );
        handler.syncQueue(
          [testTrack, track2],
          currentIndex: 1,
          isShuffle: false,
        );
        handler.syncTrack(track2);

        String? resolvedId;
        handler.setStreamResolver((id) async {
          resolvedId = id;
          return 'https://audius.co/stream/$id.mp3';
        });

        // > 3s: seeks to zero
        playerService.currentPositionValue = const Duration(seconds: 10);
        await handler.skipToPrevious();
        expect(playerService.seekCalledWith, equals(Duration.zero));
        expect(handler.currentIndex, equals(1));

        // <= 3s: steps to previous track
        playerService.currentPositionValue = const Duration(seconds: 1);
        await handler.skipToPrevious();
        expect(resolvedId, equals('track_123'));
        expect(
          playerService.urlValue,
          equals('https://audius.co/stream/track_123.mp3'),
        );
        expect(handler.mediaItem.value?.id, equals('track_123'));
        expect(handler.currentIndex, equals(0));
      },
    );

    test(
      'autonomous skipToQueueItem jumps to target index and streams',
      () async {
        const track2 = Track(id: 't2', title: 'Two');
        const track3 = Track(id: 't3', title: 'Three');
        handler.syncQueue(
          [testTrack, track2, track3],
          currentIndex: 0,
          isShuffle: false,
        );
        handler.syncTrack(testTrack);

        handler.setStreamResolver((id) async => 'https://stream/$id');

        await handler.skipToQueueItem(2);
        expect(handler.currentIndex, equals(2));
        expect(playerService.urlValue, equals('https://stream/t3'));
        expect(playerService.playCalled, isTrue);
        expect(handler.mediaItem.value?.id, equals('t3'));
      },
    );

    test('autonomous track completion advances to next track when repeatMode is all', () async {
      const track2 = Track(id: 't2', title: 'Two');
      handler.syncQueue([testTrack, track2], currentIndex: 0, isShuffle: false);
      handler.syncTrack(testTrack);
      await handler.setRepeatMode(AudioServiceRepeatMode.all);

      handler.setStreamResolver((id) async => 'https://stream/$id');

      playerService.emitCompleted();
      await pumpEventQueue();

      expect(handler.currentIndex, equals(1));
      expect(playerService.urlValue, equals('https://stream/t2'));
      expect(playerService.playCalled, isTrue);
    });

    test(
      'autonomous track completion repeats same track when repeatMode is one',
      () async {
        handler.syncQueue([testTrack], currentIndex: 0, isShuffle: false);
        handler.syncTrack(testTrack);
        await handler.setRepeatMode(AudioServiceRepeatMode.one);

        playerService.emitCompleted();
        await pumpEventQueue();

        expect(playerService.seekCalledWith, equals(Duration.zero));
        expect(playerService.playCalled, isTrue);
      },
    );

    test('click routes MediaButton.next and MediaButton.previous', () async {
      const track2 = Track(id: 't2', title: 'Two');
      handler.syncQueue([testTrack, track2], currentIndex: 0, isShuffle: false);
      handler.syncTrack(testTrack);
      handler.setStreamResolver((id) async => 'https://stream/$id');

      await handler.click(MediaButton.next);
      expect(handler.currentIndex, equals(1));

      playerService.currentPositionValue = const Duration(seconds: 1);
      await handler.click(MediaButton.previous);
      expect(handler.currentIndex, equals(0));
    });
  });

  group('AudifiAudioHandler Delegation with Attached Actions', () {
    late FakePlaybackActions actions;

    setUp(() {
      actions = FakePlaybackActions();
      handler.attachPlaybackActions(actions);
    });

    test('play and pause delegate to attached actions', () async {
      await handler.play();
      expect(actions.playCalled, isTrue);

      await handler.pause();
      expect(actions.pauseCalled, isTrue);
    });

    test('stop delegates to attached actions', () async {
      await handler.stop();
      expect(actions.stopCalled, isTrue);
    });

    test(
      'seek delegates to attached actions and broadcasts position',
      () async {
        const seekTarget = Duration(seconds: 70);
        await handler.seek(seekTarget);

        expect(actions.seekCalledWith, equals(seekTarget));
        expect(handler.playbackState.value.updatePosition, equals(seekTarget));
      },
    );

    test(
      'skipToNext and skipToPrevious delegate to attached actions',
      () async {
        await handler.skipToNext();
        expect(actions.skipToNextCalled, isTrue);

        await handler.skipToPrevious();
        expect(actions.skipToPreviousCalled, isTrue);
      },
    );

    test('skipToQueueItem delegates to attached actions', () async {
      await handler.skipToQueueItem(3);
      expect(actions.skipToQueueItemCalledWith, equals(3));
    });

    test('setRepeatMode maps AudioServiceRepeatMode to RepeatMode', () async {
      await handler.setRepeatMode(AudioServiceRepeatMode.one);
      expect(actions.setRepeatModeCalledWith, equals(RepeatMode.one));
      expect(
        handler.playbackState.value.repeatMode,
        equals(AudioServiceRepeatMode.one),
      );

      await handler.setRepeatMode(AudioServiceRepeatMode.all);
      expect(actions.setRepeatModeCalledWith, equals(RepeatMode.all));
      expect(
        handler.playbackState.value.repeatMode,
        equals(AudioServiceRepeatMode.all),
      );

      await handler.setRepeatMode(AudioServiceRepeatMode.none);
      expect(actions.setRepeatModeCalledWith, equals(RepeatMode.off));
      expect(
        handler.playbackState.value.repeatMode,
        equals(AudioServiceRepeatMode.none),
      );
    });

    test('setShuffleMode maps AudioServiceShuffleMode to boolean', () async {
      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      expect(actions.setShuffleModeCalledWith, isTrue);
      expect(
        handler.playbackState.value.shuffleMode,
        equals(AudioServiceShuffleMode.all),
      );

      await handler.setShuffleMode(AudioServiceShuffleMode.none);
      expect(actions.setShuffleModeCalledWith, isFalse);
      expect(
        handler.playbackState.value.shuffleMode,
        equals(AudioServiceShuffleMode.none),
      );
    });

    test('click handles media, next, and previous button events', () async {
      await handler.click(MediaButton.media);
      expect(actions.togglePlayPauseCalled, isTrue);

      await handler.click(MediaButton.next);
      expect(actions.skipToNextCalled, isTrue);

      await handler.click(MediaButton.previous);
      expect(actions.skipToPreviousCalled, isTrue);
    });

    test('detachPlaybackActions removes attached actions cleanly', () async {
      handler.detachPlaybackActions();

      await handler.play();
      // Should now delegate to playerService instead of actions
      expect(playerService.playCalled, isTrue);
    });
  });

  group('AudifiAudioHandler Metadata & Queue Synchronization', () {
    test('syncTrack populates mediaItem with complete metadata and artUri', () {
      handler.syncTrack(testTrack);

      final item = handler.mediaItem.value;
      expect(item, isNotNull);
      expect(item!.id, equals('track_123'));
      expect(item.title, equals('Neon Odyssey'));
      expect(item.artist, equals('Cyber Voyager'));
      expect(item.album, equals('AudiFi'));
      expect(item.duration, equals(const Duration(seconds: 215)));
      expect(
        item.artUri,
        equals(Uri.parse('https://audius.co/art/medium.jpg')),
      );
      expect(item.genre, equals('Synthwave'));
      expect(item.extras?['trackId'], equals('track_123'));
    });

    test('syncTrack with null track clears mediaItem safely', () {
      handler.syncTrack(testTrack);
      expect(handler.mediaItem.value, isNotNull);

      handler.syncTrack(null);
      expect(handler.mediaItem.value, isNull);
    });

    test('syncTrack handles malformed artwork URI without crashing', () {
      const trackWithInvalidArt = Track(
        id: 'bad_art_1',
        title: 'Broken Art Track',
        artwork: Artwork(medium: 'not-a-valid-uri-scheme:::'),
      );

      handler.syncTrack(trackWithInvalidArt);
      final item = handler.mediaItem.value;
      expect(item, isNotNull);
      expect(item!.artUri, isNull);
    });

    test(
      'syncQueue populates queue and updates queueIndex in playback state',
      () {
        const track2 = Track(
          id: 'track_2',
          title: 'Future Echoes',
          duration: 180,
        );
        final tracks = [testTrack, track2];

        handler.syncQueue(tracks, currentIndex: 1, isShuffle: true);

        expect(handler.queue.value.length, equals(2));
        expect(handler.queue.value[0].id, equals('track_123'));
        expect(handler.queue.value[1].id, equals('track_2'));
        expect(handler.playbackState.value.queueIndex, equals(1));
        expect(
          handler.playbackState.value.shuffleMode,
          equals(AudioServiceShuffleMode.all),
        );
      },
    );

    test('syncRepeatMode updates repeat mode in playback state', () {
      handler.syncRepeatMode(RepeatMode.one);
      expect(
        handler.playbackState.value.repeatMode,
        equals(AudioServiceRepeatMode.one),
      );

      handler.syncRepeatMode(RepeatMode.all);
      expect(
        handler.playbackState.value.repeatMode,
        equals(AudioServiceRepeatMode.all),
      );

      handler.syncRepeatMode(RepeatMode.off);
      expect(
        handler.playbackState.value.repeatMode,
        equals(AudioServiceRepeatMode.none),
      );
    });
  });

  group('AudifiAudioHandler Engine Stream Synchronization', () {
    test(
      'playingStream updates playing boolean and switches media control',
      () async {
        playerService.emitPlaying(true);
        await pumpEventQueue();

        var state = handler.playbackState.value;
        expect(state.playing, isTrue);
        expect(state.controls[1].action, equals(MediaAction.pause));

        playerService.emitPlaying(false);
        await pumpEventQueue();

        state = handler.playbackState.value;
        expect(state.playing, isFalse);
        expect(state.controls[1].action, equals(MediaAction.play));
      },
    );

    test('processingStateStream updates audio processing state', () async {
      playerService.emitProcessingState(EngineProcessingState.buffering);
      await pumpEventQueue();
      expect(
        handler.playbackState.value.processingState,
        equals(AudioProcessingState.buffering),
      );

      playerService.emitProcessingState(EngineProcessingState.ready);
      await pumpEventQueue();
      expect(
        handler.playbackState.value.processingState,
        equals(AudioProcessingState.ready),
      );

      playerService.emitProcessingState(EngineProcessingState.completed);
      await pumpEventQueue();
      expect(
        handler.playbackState.value.processingState,
        equals(AudioProcessingState.completed),
      );
    });

    test(
      'positionStream jumps greater than 2 seconds anchor updatePosition',
      () async {
        playerService.emitPosition(const Duration(seconds: 1));
        await pumpEventQueue();

        // Large jump (simulate seeking)
        playerService.emitPosition(const Duration(seconds: 60));
        await pumpEventQueue();

        expect(
          handler.playbackState.value.updatePosition,
          equals(const Duration(seconds: 60)),
        );
      },
    );
  });
}
