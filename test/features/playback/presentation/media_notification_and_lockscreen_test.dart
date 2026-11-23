import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audifi_audio_handler.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/models/artwork.dart';
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
    _position = Duration.zero;
    _playingController.add(false);
    _processingController.add(EngineProcessingState.idle);
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    _positionController.add(position);
  }

  @override
  Future<void> setAudioUrl(String url) async {
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
    isDisposed = true;
    await _playingController.close();
    await _processingController.close();
    await _positionController.close();
    await _bufferedController.close();
    await _durationController.close();
    await _completedController.close();
  }

  void emitProcessingState(EngineProcessingState state) =>
      _processingController.add(state);
  void emitDuration(Duration? duration) => _durationController.add(duration);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3.2: Media Notification & Lock Screen Metadata Synchronization', () {
    late _FakeAudioPlayerService fakePlayer;
    late AudifiAudioHandler audioHandler;

    setUp(() {
      fakePlayer = _FakeAudioPlayerService();
      audioHandler = AudifiAudioHandler(playerService: fakePlayer);
    });

    tearDown(() async {
      await audioHandler.dispose();
      await fakePlayer.dispose();
    });

    test('syncTrack populates all media metadata and display properties', () {
      const track = Track(
        id: 'track_1',
        title: 'Cyberpunk Skyline',
        genre: 'Electronic',
        duration: 240,
        artwork: Artwork(
          small: 'https://audius.co/art/small.jpg',
          medium: 'https://audius.co/art/medium.jpg',
          large: 'https://audius.co/art/large.jpg',
        ),
        user: User(id: 'user_1', name: 'Synth Master', handle: 'synthmaster'),
      );

      audioHandler.syncTrack(track);

      final item = audioHandler.mediaItem.value;
      expect(item, isNotNull);
      expect(item!.id, equals('track_1'));
      expect(item.title, equals('Cyberpunk Skyline'));
      expect(item.artist, equals('Synth Master'));
      expect(item.album, equals('AudiFi'));
      expect(item.genre, equals('Electronic'));
      expect(item.displayTitle, equals('Cyberpunk Skyline'));
      expect(item.displaySubtitle, equals('Synth Master'));
      expect(item.displayDescription, equals('Electronic'));
      expect(item.duration, equals(const Duration(seconds: 240)));
      expect(
        item.artUri,
        equals(Uri.parse('https://audius.co/art/medium.jpg')),
      );
      expect(item.extras?['trackId'], equals('track_1'));
    });

    test('syncTrack handles empty, whitespace, and null metadata with safe fallbacks', () {
      const trackWithBlanks = Track(
        id: 'track_blank',
        title: '   ',
        duration: 0,
        user: User(id: 'user_blank', name: '  \t ', handle: 'blank'),
      );

      audioHandler.syncTrack(trackWithBlanks);

      final item = audioHandler.mediaItem.value;
      expect(item, isNotNull);
      expect(item!.title, equals('Unknown Title'));
      expect(item.artist, equals('Unknown Artist'));
      expect(item.displayTitle, equals('Unknown Title'));
      expect(item.displaySubtitle, equals('Unknown Artist'));
      expect(item.duration, isNull);
      expect(item.artUri, isNull);
    });

    test('syncTrack falls back to user profile picture when track artwork is absent', () {
      const trackWithUserArtOnly = Track(
        id: 'track_user_art',
        title: 'Artist Profile Fallback',
        duration: 120,
        artwork: null,
        user: User(
          id: 'artist_1',
          name: 'Featured Artist',
          handle: 'featured',
          profilePicture: Artwork(
            medium: 'https://audius.co/users/avatar_480.jpg',
          ),
        ),
      );

      audioHandler.syncTrack(trackWithUserArtOnly);

      final item = audioHandler.mediaItem.value;
      expect(item, isNotNull);
      expect(
        item!.artUri,
        equals(Uri.parse('https://audius.co/users/avatar_480.jpg')),
      );
    });

    test('syncTrack ignores malformed or unsupported URI schemes safely', () {
      const trackWithInvalidArt = Track(
        id: 'track_bad_uri',
        title: 'Invalid Scheme',
        duration: 60,
        artwork: Artwork(medium: 'javascript:alert(1)'),
      );

      audioHandler.syncTrack(trackWithInvalidArt);

      final item = audioHandler.mediaItem.value;
      expect(item, isNotNull);
      expect(item!.artUri, isNull);
    });

    test(
      'durationStream updates mediaItem duration only when valid and positive',
      () async {
        const track = Track(
          id: 'track_dur',
          title: 'Duration Sync',
          duration: 100,
        );

        audioHandler.syncTrack(track);
        expect(
          audioHandler.mediaItem.value!.duration,
          equals(const Duration(seconds: 100)),
        );

        // Player engine emits accurate header duration
        fakePlayer.emitDuration(const Duration(milliseconds: 105432));
        await pumpEventQueue();

        expect(
          audioHandler.mediaItem.value!.duration,
          equals(const Duration(milliseconds: 105432)),
        );

        // Null duration from player reset does not corrupt mediaItem
        fakePlayer.emitDuration(null);
        await pumpEventQueue();

        expect(
          audioHandler.mediaItem.value!.duration,
          equals(const Duration(milliseconds: 105432)),
        );
      },
    );
  });

  group('Phase 3.2: Media Notification Presentation & Actions', () {
    late _FakeAudioPlayerService fakePlayer;
    late AudifiAudioHandler audioHandler;

    setUp(() {
      fakePlayer = _FakeAudioPlayerService();
      audioHandler = AudifiAudioHandler(playerService: fakePlayer);
    });

    tearDown(() async {
      await audioHandler.dispose();
      await fakePlayer.dispose();
    });

    test(
      'Playback state reflects playing status and compact media controls',
      () async {
        await fakePlayer.play();
        await pumpEventQueue();

        final state = audioHandler.playbackState.value;
        expect(state.playing, isTrue);
        expect(state.controls[1].action, equals(MediaAction.pause));
        expect(state.androidCompactActionIndices, equals([0, 1, 2]));
        expect(state.controls[0].action, equals(MediaAction.skipToPrevious));
        expect(state.controls[2].action, equals(MediaAction.skipToNext));
        expect(state.controls.length, equals(3));
      },
    );

    test(
      'Playback state reflects paused status and switches control to play',
      () async {
        await fakePlayer.pause();
        await pumpEventQueue();

        final state = audioHandler.playbackState.value;
        expect(state.playing, isFalse);
        expect(state.controls[1].action, equals(MediaAction.play));
      },
    );

    test(
      'Processing states map accurately for Android MediaStyle notification',
      () async {
        fakePlayer.emitProcessingState(EngineProcessingState.loading);
        await pumpEventQueue();
        expect(
          audioHandler.playbackState.value.processingState,
          equals(AudioProcessingState.loading),
        );

        fakePlayer.emitProcessingState(EngineProcessingState.buffering);
        await pumpEventQueue();
        expect(
          audioHandler.playbackState.value.processingState,
          equals(AudioProcessingState.buffering),
        );

        fakePlayer.emitProcessingState(EngineProcessingState.ready);
        await pumpEventQueue();
        expect(
          audioHandler.playbackState.value.processingState,
          equals(AudioProcessingState.ready),
        );

        fakePlayer.emitProcessingState(EngineProcessingState.completed);
        await pumpEventQueue();
        expect(
          audioHandler.playbackState.value.processingState,
          equals(AudioProcessingState.completed),
        );
      },
    );
  });

  group('Phase 3.2: End-of-Queue Replay & Completed State Synchronization', () {
    test(
      'PlaybackController play() rewinds completed track to Duration.zero',
      () async {
        final fakePlayer = _FakeAudioPlayerService();
        final handler = AudifiAudioHandler(playerService: fakePlayer);

        setBootstrapAudioServices(
          audioHandler: handler,
          audioPlayerService: fakePlayer,
        );

        final container = ProviderContainer(
          overrides: [
            playbackRepositoryProvider.overrideWithValue(
              StubPlaybackRepository(),
            ),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await handler.dispose();
          await fakePlayer.dispose();
          resetBootstrapAudioServices();
        });

        const sampleTrack = Track(
          id: 'track_end',
          title: 'Final Song',
          duration: 180,
        );

        final controller = container.read(playbackControllerProvider.notifier);
        await controller.playTrack(sampleTrack);

        // Simulate reaching completed status
        fakePlayer._position = const Duration(seconds: 180);
        fakePlayer._duration = const Duration(seconds: 180);
        controller.state = controller.state.copyWith(
          status: PlaybackStatus.completed,
          position: const Duration(seconds: 180),
        );

        expect(controller.state.status, equals(PlaybackStatus.completed));
        expect(controller.state.position, equals(const Duration(seconds: 180)));

        // Invoking play() when completed seeks back to Duration.zero and plays
        await controller.play();

        expect(controller.state.position, equals(Duration.zero));
        expect(fakePlayer.currentPosition, equals(Duration.zero));
        expect(fakePlayer.isPlaying, isTrue);
      },
    );
  });

  group('Phase 3.2: Android Notification Manifest & Resource Hardening', () {
    test(
      'AndroidManifest.xml declares android.permission.POST_NOTIFICATIONS',
      () {
        final manifestFile = File('android/app/src/main/AndroidManifest.xml');
        expect(manifestFile.existsSync(), isTrue);

        final content = manifestFile.readAsStringSync();
        expect(
          content.contains('android.permission.POST_NOTIFICATIONS'),
          isTrue,
          reason: 'Android 13+ requires POST_NOTIFICATIONS for foreground media notification',
        );
        expect(
          content.contains(
            'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
          ),
          isTrue,
        );
      },
    );

    test(
      'Monochrome notification vector drawable exists and is valid vector XML',
      () {
        final iconFile = File(
          'android/app/src/main/res/drawable/ic_notification.xml',
        );
        expect(iconFile.existsSync(), isTrue);

        final content = iconFile.readAsStringSync();
        expect(content.contains('<vector'), isTrue);
        expect(content.contains('android:width="24dp"'), isTrue);
        expect(content.contains('android:height="24dp"'), isTrue);
        expect(
          content.contains('#FFFFFFFF') || content.contains('#FFFFFF'),
          isTrue,
        );
      },
    );
  });
}
