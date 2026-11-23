import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/domain/entities/artwork_palette.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/presentation/controllers/artwork_palette_controller.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/models/artwork.dart';

import '../../../test_helpers/stub_repositories.dart';

class MockPlaybackController extends PlaybackController {
  MockPlaybackController(this._initialState);
  final PlaybackState _initialState;

  @override
  PlaybackState build() => _initialState;

  void setTrack(Track? track) {
    state = state.copyWith(currentTrack: track);
  }
}

void main() {
  group('ArtworkPaletteController', () {
    late ProviderContainer container;
    late MockPlaybackController playbackController;
    int extractionCount = 0;

    const testTrackA = Track(
      id: 'track_a',
      title: 'Track A',
      artwork: Artwork(medium: 'https://audius.co/art/a.jpg'),
      user: User(id: 'u1', name: 'Artist A', handle: 'artist_a'),
    );

    const testTrackB = Track(
      id: 'track_b',
      title: 'Track B',
      artwork: Artwork(medium: 'https://audius.co/art/b.jpg'),
      user: User(id: 'u2', name: 'Artist B', handle: 'artist_b'),
    );

    const extractedPaletteA = ArtworkPalette(
      dominant: Color(0xFF102030),
      secondary: Color(0xFF203040),
      accent: Color(0xFF304050),
      background: Color(0xFF405060),
      isFallback: false,
    );

    const extractedPaletteB = ArtworkPalette(
      dominant: Color(0xFF908070),
      secondary: Color(0xFF807060),
      accent: Color(0xFF706050),
      background: Color(0xFF605040),
      isFallback: false,
    );

    setUp(() {
      extractionCount = 0;
      playbackController = MockPlaybackController(const PlaybackState());

      container = ProviderContainer(
        overrides: [
          ...createStubRepositoryOverrides(),
          playbackControllerProvider.overrideWith(() => playbackController),
          paletteExtractionStrategyProvider.overrideWithValue((
            url, {
            required Brightness brightness,
            required AudifiThemeColors colors,
          }) async {
            extractionCount++;
            if (url.contains('a.jpg')) return extractedPaletteA;
            if (url.contains('b.jpg')) return extractedPaletteB;
            if (url.contains('fail.jpg')) {
              throw Exception('Network image download timeout');
            }
            return ArtworkPalette(
              dominant: Color(url.hashCode | 0xFF000000),
              secondary: const Color(0xFF222222),
              accent: const Color(0xFF333333),
              background: const Color(0xFF444444),
              isFallback: false,
            );
          }),
        ],
      );
      // Ensure playbackController is initialized
      container.read(playbackControllerProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state returns fallback palette when track is null', () {
      final state = container.read(artworkPaletteProvider);
      expect(state.palette.isFallback, isTrue);
      expect(state.currentArtworkUrl, isNull);
      expect(extractionCount, equals(0));
    });

    test('extracts palette when track has artwork URL', () async {
      playbackController.setTrack(testTrackA);

      // Read to trigger subscription
      container.read(artworkPaletteProvider);
      await pumpEventQueue();

      final state = container.read(artworkPaletteProvider);
      expect(state.palette, equals(extractedPaletteA));
      expect(state.palette.isFallback, isFalse);
      expect(state.currentArtworkUrl, equals('https://audius.co/art/a.jpg'));
      expect(extractionCount, equals(1));
    });

    test(
      'caches extracted palette and avoids re-extraction on repeated track',
      () async {
        // 1. Play track A
        playbackController.setTrack(testTrackA);
        container.read(artworkPaletteProvider);
        await pumpEventQueue();
        expect(extractionCount, equals(1));

        // 2. Switch to track B
        playbackController.setTrack(testTrackB);
        container.read(artworkPaletteProvider);
        await pumpEventQueue();
        expect(extractionCount, equals(2));

        // 3. Switch back to track A -> Cache Hit
        playbackController.setTrack(testTrackA);
        container.read(artworkPaletteProvider);
        await pumpEventQueue();

        final state = container.read(artworkPaletteProvider);
        expect(state.palette, equals(extractedPaletteA));
        expect(extractionCount, equals(2)); // No third extraction!
      },
    );

    test('gracefully falls back when extraction throws exception', () async {
      const failingTrack = Track(
        id: 'fail_1',
        title: 'Broken Art Track',
        artwork: Artwork(medium: 'https://audius.co/art/fail.jpg'),
      );

      playbackController.setTrack(failingTrack);
      container.read(artworkPaletteProvider);
      await pumpEventQueue();

      final state = container.read(artworkPaletteProvider);
      expect(state.palette.isFallback, isTrue);
      expect(extractionCount, equals(1));
    });

    test('race condition: discards stale extraction results', () async {
      final completerA = Completer<ArtworkPalette>();
      final customPlaybackController = MockPlaybackController(
        const PlaybackState(),
      );

      final customContainer = ProviderContainer(
        overrides: [
          ...createStubRepositoryOverrides(),
          playbackControllerProvider.overrideWith(
            () => customPlaybackController,
          ),
          paletteExtractionStrategyProvider.overrideWithValue((
            url, {
            required Brightness brightness,
            required AudifiThemeColors colors,
          }) async {
            if (url.contains('a.jpg')) {
              return completerA.future; // delayed
            }
            return extractedPaletteB;
          }),
        ],
      );
      customContainer.read(playbackControllerProvider);

      // Request track A (slow extraction)
      customPlaybackController.setTrack(testTrackA);
      customContainer.read(artworkPaletteProvider);
      await pumpEventQueue();

      // Immediately switch to track B (fast extraction)
      customPlaybackController.setTrack(testTrackB);
      customContainer.read(artworkPaletteProvider);
      await pumpEventQueue();

      // Track B has already resolved
      expect(
        customContainer.read(artworkPaletteProvider).palette,
        equals(extractedPaletteB),
      );

      // Now track A finally finishes late
      completerA.complete(extractedPaletteA);
      await pumpEventQueue();

      // Track B palette must NOT be overwritten by the stale track A result
      expect(
        customContainer.read(artworkPaletteProvider).palette,
        equals(extractedPaletteB),
      );

      customContainer.dispose();
    });

    test('respects dynamicColors disabled preference', () async {
      await container
          .read(settingsControllerProvider.notifier)
          .setDynamicColors(false);

      playbackController.setTrack(testTrackA);
      container.read(artworkPaletteProvider);
      await pumpEventQueue();

      final state = container.read(artworkPaletteProvider);
      expect(state.palette.isFallback, isTrue);
      expect(extractionCount, equals(0)); // Never extracts when disabled
    });
  });
}
