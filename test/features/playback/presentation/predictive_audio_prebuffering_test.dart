import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/features/playback/data/datasources/next_track_url_cache.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/data/services/audio_prebuffer_service.dart';
import 'package:audifi/features/playback/data/services/prebuffered_audio_source.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/repositories/playback_repository.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

class _FakePrebufferPlayerService implements AudioPlayerService {
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _processingController =
      StreamController<EngineProcessingState>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  AudioSource? loadedSource;
  String? loadedUrl;
  bool isPlayingState = false;
  Duration currentPositionValue = Duration.zero;
  Duration? currentDurationValue = const Duration(seconds: 120);

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
    _processingController.add(EngineProcessingState.buffering);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    loadedSource = source;
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

  @override
  Future<void> seek(Duration position) async {
    currentPositionValue = position;
    _positionController.add(position);
  }

  @override
  Future<void> stop() async {
    isPlayingState = false;
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

  void emitCompletion() {
    _completedController.add(null);
  }
}

class _StubPlaybackRepository implements PlaybackRepository {
  String? predictedId;
  String? cachedUrl;

  @override
  Future<String> resolveStreamUrl(String trackId, {dynamic cancelToken}) async {
    return 'https://audius.co/stream/$trackId';
  }

  @override
  Future<void> prefetchStreamUrl(String trackId, {dynamic cancelToken}) async {
    predictedId = trackId;
    cachedUrl = 'https://audius.co/stream/$trackId';
  }

  @override
  String? get currentPredictedTrackId => predictedId;

  @override
  bool hasPrediction(String trackId) => predictedId == trackId;

  @override
  void invalidatePrediction({String reason = 'invalidated'}) {
    predictedId = null;
    cachedUrl = null;
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

  group('Spotify-Style Predictive Audio Prebuffering Integration', () {
    late Directory tempDir;
    late ProviderContainer container;
    late _FakePrebufferPlayerService player;
    late _StubPlaybackRepository repo;
    late NextTrackUrlCache urlCache;

    const trackA = Track(id: 'track_A', title: 'Track A', duration: 100);
    const trackB = Track(id: 'track_B', title: 'Track B', duration: 120);
    const trackC = Track(id: 'track_C', title: 'Track C', duration: 150);

    late AudioPrebufferService prebufferService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('prebuffering_test_');
      player = _FakePrebufferPlayerService();
      repo = _StubPlaybackRepository();
      urlCache = NextTrackUrlCache();
      prebufferService = AudioPrebufferService(
        dioClient: DioClient(rawDio: Dio()),
        customStorageDirectory: tempDir,
      );

      container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(player),
          playbackRepositoryProvider.overrideWithValue(repo),
          nextTrackUrlCacheProvider.overrideWithValue(urlCache),
          audioPrebufferServiceProvider.overrideWithValue(prebufferService),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('plays track using PrebufferedAudioSource on prebuffer hit and marks tracer', () async {
      // 1. Play Track A with context [Track A, Track B, Track C]
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        trackA,
        contextTracks: [trackA, trackB, trackC],
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Verify Track A was regular play
      expect(player.loadedSource, isNull);
      expect(player.loadedUrl, contains('track_A'));

      // 2. Prime a prebuffer file for Track B on disk
      final prebufferFile = File('${tempDir.path}/track_B.buf');
      prebufferFile.writeAsBytesSync(Uint8List(500 * 1024));

      // 3. Skip to Next (Track B)
      await controller.skipToNext();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 4. Verify PrebufferedAudioSource was used
      expect(player.loadedSource, isA<PrebufferedAudioSource>());
      final activeSource = player.loadedSource as PrebufferedAudioSource;
      expect(activeSource.trackId, equals('track_B'));
      expect(activeSource.prebufferedBytes, equals(500 * 1024));

      final tracer = PlaybackController.lastCompletedTracer;
      expect(tracer, isNotNull);
      expect(tracer!.hasMark('prebuffer_hit'), isTrue);
      expect(tracer.hasMark('prebuffer_miss'), isFalse);
    });

    test('falls back to standard remote stream when no prebuffer exists (prebuffer miss)', () async {
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(
        trackA,
        contextTracks: [trackA, trackB, trackC],
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Skip to Track B without prebuffer
      await controller.skipToNext();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(player.loadedSource, isNull);
      expect(player.loadedUrl, contains('track_B'));

      final tracer = PlaybackController.lastCompletedTracer;
      expect(tracer, isNotNull);
      expect(tracer!.hasMark('prebuffer_miss'), isTrue);
      expect(tracer.hasMark('prebuffer_hit'), isFalse);
    });

    test('handles offline prebuffer exhaustion gracefully without auto-skipping or error loop', () async {
      // Prime prebuffer file for Track B
      final prebufferFile = File('${tempDir.path}/track_B.buf');
      prebufferFile.writeAsBytesSync(Uint8List(200 * 1024));

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(trackB, contextTracks: [trackB, trackC]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(player.loadedSource, isA<PrebufferedAudioSource>());
      final source = player.loadedSource as PrebufferedAudioSource;

      // Simulate offline continuation failure callback
      source.onOfflineExhausted?.call('track_B');

      // Player completes playing the local prebuffered chunk
      player.emitCompletion();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Must pause cleanly on Track B without auto-skipping to Track C
      final playbackState = container.read(playbackControllerProvider);
      expect(playbackState.currentTrack?.id, equals('track_B'));
      expect(playbackState.status, equals(PlaybackStatus.paused));
    });
  });
}
