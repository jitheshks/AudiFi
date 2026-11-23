import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/data/datasources/queue_local_data_source.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audifi_audio_handler.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/repositories/playback_repository.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/controllers/queue_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/models/artwork.dart';

class StubRestorationPlayerService implements AudioPlayerService {
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
  Duration? currentDurationValue;

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
    currentDurationValue = const Duration(seconds: 200);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    currentDurationValue = const Duration(seconds: 200);
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
    _processingController.add(EngineProcessingState.idle);
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

class TrackingPlaybackRepository implements PlaybackRepository {
  TrackingPlaybackRepository({required this.localDataSource});

  final QueueLocalDataSource localDataSource;
  final List<String> resolvedTrackIds = [];

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    resolvedTrackIds.add(trackId);
    return 'https://stream.audius.co/v1/tracks/$trackId/stream?token=ephemeral';
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
  }) => localDataSource.saveQueue(tracks: tracks, currentIndex: currentIndex);

  @override
  Future<({List<Track> tracks, int currentIndex})?> restoreQueue() =>
      localDataSource.restoreQueue();

  @override
  Future<void> clearSavedQueue() => localDataSource.clearQueue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StubRestorationPlayerService player;
  late TrackingPlaybackRepository repository;
  late QueueLocalDataSource localDataSource;
  late AudifiAudioHandler audioHandler;
  late ProviderContainer container;

  const track1 = Track(
    id: 'audius_track_1',
    title: 'Echoes of the Grid',
    duration: 195,
    artwork: Artwork(medium: 'https://audius.co/art/echoes.jpg'),
    user: User(id: 'artist_1', name: 'Grid Master', handle: 'gridmaster'),
  );

  const track2 = Track(
    id: 'audius_track_2',
    title: 'Neon Drift',
    duration: 220,
    artwork: Artwork(medium: 'https://audius.co/art/drift.jpg'),
    user: User(id: 'artist_2', name: 'Drifter', handle: 'drifter'),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    player = StubRestorationPlayerService();
    localDataSource = QueueLocalDataSource(
      prefsAsync: SharedPreferences.getInstance(),
    );
    repository = TrackingPlaybackRepository(localDataSource: localDataSource);
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

  group('Playback Restoration & URL Re-resolution', () {
    test('restores saved queue metadata and current track on launch', () async {
      // 1. Persist tracks to local storage (simulating previous app session)
      await localDataSource.saveQueue(
        tracks: [track1, track2],
        currentIndex: 1,
      );

      // 2. Perform queue restoration
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.restoreSavedQueue();

      // 3. Verify PlaybackController reflects restored track
      final playState = container.read(playbackControllerProvider);
      expect(playState.currentTrack?.id, equals('audius_track_2'));
      expect(playState.currentTrack?.title, equals('Neon Drift'));
      expect(playState.status, equals(PlaybackStatus.idle));

      // 4. Verify QueueController restored items and index
      final queueState = container.read(queueControllerProvider);
      expect(queueState.items.length, equals(2));
      expect(queueState.currentIndex, equals(1));
      expect(queueState.currentTrack?.id, equals('audius_track_2'));

      // 5. Verify AudioHandler received restored media item and queue
      expect(audioHandler.mediaItem.value?.id, equals('audius_track_2'));
      expect(audioHandler.queue.value.length, equals(2));
      expect(audioHandler.playbackState.value.queueIndex, equals(1));
    });

    test('re-resolves temporary streaming URL when play() is called on restored track', () async {
      await localDataSource.saveQueue(
        tracks: [track1, track2],
        currentIndex: 0,
      );

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.restoreSavedQueue();

      // Player engine should not have loaded stream URL yet
      expect(player.loadedUrl, isNull);
      expect(repository.resolvedTrackIds, isEmpty);

      // User presses Play on restored track
      await controller.play();

      // Verify stream URL was dynamically re-resolved using stable track ID
      expect(repository.resolvedTrackIds, equals(['audius_track_1']));
      expect(player.loadedUrl, contains('audius_track_1'));
      expect(player.isPlaying, isTrue);
    });

    test('re-resolves temporary streaming URL when OS notification play is triggered', () async {
      await localDataSource.saveQueue(
        tracks: [track1, track2],
        currentIndex: 1,
      );

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.restoreSavedQueue();

      // Trigger play via OS AudioHandler
      await audioHandler.play();

      expect(repository.resolvedTrackIds, equals(['audius_track_2']));
      expect(player.loadedUrl, contains('audius_track_2'));
      expect(player.isPlaying, isTrue);
    });

    test('gracefully handles missing or empty local storage queue', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.restoreSavedQueue();

      expect(container.read(playbackControllerProvider).currentTrack, isNull);
      expect(container.read(queueControllerProvider).items, isEmpty);
      expect(audioHandler.mediaItem.value, isNull);
    });

    test('gracefully handles corrupted local storage queue payload', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('audifi_playback_queue_v1', 'NOT_VALID_JSON{:::');

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.restoreSavedQueue();

      expect(container.read(playbackControllerProvider).currentTrack, isNull);
      expect(container.read(queueControllerProvider).items, isEmpty);
    });

    test(
      'queue exhaustion stops player and completes playback state',
      () async {
        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(track2, contextTracks: [track1, track2]);

        expect(container.read(queueControllerProvider).currentIndex, equals(1));

        // Skip past the last track with repeatMode off
        await controller.skipToNext();

        expect(player.isPlaying, isFalse);
        expect(
          container.read(playbackControllerProvider).status,
          equals(PlaybackStatus.completed),
        );
      },
    );
  });
}
