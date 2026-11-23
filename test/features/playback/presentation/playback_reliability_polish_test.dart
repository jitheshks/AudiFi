import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/entities/repeat_mode.dart'
    as audifi;
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/controllers/queue_controller.dart';
import 'package:audifi/features/playback/presentation/widgets/now_playing/now_playing_controls.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/widgets/audifi_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../test_helpers/stub_repositories.dart';

class FallbackMockAudioPlayerService extends StubAudioPlayerService {
  int setAudioUrlAttempts = 0;
  int playCallCount = 0;
  int stopCallCount = 0;
  String? lastLoadedUrl;
  bool shouldFailFirstAttempt = false;

  @override
  Future<void> setAudioUrl(String url) async {
    setAudioUrlAttempts++;
    lastLoadedUrl = url;
    if (shouldFailFirstAttempt && setAudioUrlAttempts == 1) {
      throw Exception('Simulated corrupt audio stream or expired URL');
    }
    await super.setAudioUrl(url);
  }

  @override
  Future<void> play() async {
    playCallCount++;
    await super.play();
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    await super.stop();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testTrack = Track(
    id: 'track_polish_1',
    title: 'Polish Track',
    duration: 200,
  );

  group('Phase 7 - Playback Reliability & Polish', () {
    test('PlaybackController automatically recovers and resolves fresh stream on initial source load failure', () async {
      final mockPlayer = FallbackMockAudioPlayerService()
        ..shouldFailFirstAttempt = true;

      final container = ProviderContainer(
        overrides: [
          ...createStubRepositoryOverrides(audioPlayerService: mockPlayer),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(playbackControllerProvider.notifier);

      // Directly trigger playTrack
      await controller.playTrack(testTrack);

      // Verify that after 1st attempt threw, the controller recovered and called setAudioUrl a 2nd time with fresh resolution
      expect(mockPlayer.setAudioUrlAttempts, equals(2));
      expect(mockPlayer.lastLoadedUrl, contains('track_polish_1'));
      expect(mockPlayer.playCallCount, equals(1));
    });

    test('Queue clearing automatically stops player and resets active playback state', () async {
      final mockPlayer = FallbackMockAudioPlayerService();

      final container = ProviderContainer(
        overrides: [
          ...createStubRepositoryOverrides(audioPlayerService: mockPlayer),
        ],
      );
      addTearDown(container.dispose);

      final playbackCtrl = container.read(playbackControllerProvider.notifier);
      final queueCtrl = container.read(queueControllerProvider.notifier);

      await playbackCtrl.playTrack(testTrack);
      expect(container.read(playbackControllerProvider).hasTrack, isTrue);

      // Now completely empty the queue
      queueCtrl.setQueue([]);
      await Future<void>.delayed(Duration.zero);

      final finalState = container.read(playbackControllerProvider);
      expect(finalState.hasTrack, isFalse);
      expect(finalState.status, equals(PlaybackStatus.idle));
      expect(mockPlayer.stopCallCount, equals(1));
    });

    testWidgets(
      'AudifiNetworkImage downscales decoding with target cacheWidth and cacheHeight',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AudifiNetworkImage(
                imageUrl: 'https://audius.co/artwork/test.jpg',
                width: 48,
                height: 48,
              ),
            ),
          ),
        );

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        final imageWidget = tester.widget<Image>(imageFinder);
        expect(imageWidget.image, isA<ResizeImage>());
        final resizeImage = imageWidget.image as ResizeImage;
        expect(resizeImage.width, isNotNull);
        expect(resizeImage.height, isNotNull);
        expect(resizeImage.width, greaterThanOrEqualTo(64));
      },
    );

    testWidgets(
      'NowPlayingControls renders retry icon and semantic label on error',
      (tester) async {
        bool playPauseTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NowPlayingControls(
                isPlaying: false,
                isBuffering: false,
                hasError: true,
                isShuffle: false,
                repeatMode: audifi.RepeatMode.off,
                onPlayPause: () => playPauseTapped = true,
                onNext: () {},
                onPrevious: () {},
                onToggleShuffle: () {},
                onCycleRepeat: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
        expect(find.bySemanticsLabel('Retry playback'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.refresh_rounded));
        expect(playPauseTapped, isTrue);
      },
    );
  });
}
