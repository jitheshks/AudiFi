import 'package:audifi/core/theme/theme_controller.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/entities/repeat_mode.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/views/now_playing_view.dart';
import 'package:audifi/features/playback/presentation/widgets/now_playing/ambient_gradient_background.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../../test_helpers/stub_repositories.dart';

class TestPlaybackController extends PlaybackController {
  TestPlaybackController(this.initialState);

  final PlaybackState initialState;

  int playPauseCalls = 0;
  int nextCalls = 0;
  int prevCalls = 0;

  @override
  PlaybackState build() {
    return initialState;
  }

  @override
  Future<void> togglePlayPause() async {
    playPauseCalls++;
  }

  @override
  Future<void> skipToNext() async {
    nextCalls++;
  }

  @override
  Future<void> skipToPrevious() async {
    prevCalls++;
  }
}

void main() {
  group('NowPlayingView', () {
    testWidgets('displays empty state when no track is currently playing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createStubRepositoryOverrides(),
          child: const MaterialApp(home: NowPlayingView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Active Track'), findsOneWidget);
      expect(find.text('Browse Music'), findsOneWidget);
    });

    testWidgets('renders all Now Playing components when track is active', (
      tester,
    ) async {
      const activeTrack = Track(
        id: 'np_1',
        title: 'Cyberpunk Odyssey',
        genre: 'Electronic',
        mood: 'Energetic',
        playCount: 145000,
        duration: 210,
        user: User(
          id: 'u1',
          name: 'Synth Producer',
          handle: 'synth',
          isVerified: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...createStubRepositoryOverrides(),
            playbackControllerProvider.overrideWith(
              () => TestPlaybackController(
                const PlaybackState(
                  currentTrack: activeTrack,
                  status: PlaybackStatus.playing,
                  position: Duration(seconds: 45),
                  duration: Duration(seconds: 210),
                  repeatMode: RepeatMode.all,
                  isShuffleEnabled: true,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: NowPlayingView()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header & ambient background
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.queue_music_rounded), findsNWidgets(2));
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Audio Info'), findsOneWidget);
      expect(find.text('Lyrics'), findsNothing);
      expect(find.byIcon(Icons.lyrics_rounded), findsNothing);
      expect(find.byType(AmbientGradientBackground), findsOneWidget);

      // Verify track info & metadata
      expect(find.text('Cyberpunk Odyssey'), findsOneWidget);
      expect(find.text('Synth Producer'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('Electronic · Energetic · 145k plays'), findsOneWidget);

      // Verify progress times
      expect(find.text('0:45'), findsOneWidget);
      expect(find.text('-2:45'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Verify controls
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    });

    testWidgets(
      'passes Flutter accessibility tap target and label guidelines',
      (tester) async {
        final handle = tester.ensureSemantics();
        const activeTrack = Track(
          id: 'np_a11y',
          title: 'Accessible Odyssey',
          genre: 'Electronic',
          duration: 180,
          user: User(id: 'u1', name: 'A11y Artist', handle: 'a11y'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
              playbackControllerProvider.overrideWith(
                () => TestPlaybackController(
                  const PlaybackState(
                    currentTrack: activeTrack,
                    status: PlaybackStatus.playing,
                    duration: Duration(seconds: 180),
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: NowPlayingView()),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
      },
    );

    testWidgets(
      'passes isReducedMotion to AmbientGradientBackground when isReducedMotionProvider is true',
      (tester) async {
        const activeTrack = Track(
          id: 'np_reduced_app',
          title: 'Reduced App Motion',
          genre: 'Ambient',
          duration: 200,
          user: User(id: 'u1', name: 'Ambient Artist', handle: 'ambient'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
              isReducedMotionProvider.overrideWithValue(true),
              playbackControllerProvider.overrideWith(
                () => TestPlaybackController(
                  const PlaybackState(
                    currentTrack: activeTrack,
                    status: PlaybackStatus.playing,
                    duration: Duration(seconds: 200),
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: NowPlayingView()),
          ),
        );
        await tester.pumpAndSettle();

        final ambient = tester.widget<AmbientGradientBackground>(
          find.byType(AmbientGradientBackground),
        );
        expect(ambient.isReducedMotion, isTrue);
      },
    );

    testWidgets(
      'passes isReducedMotion to AmbientGradientBackground when MediaQuery disableAnimations is true',
      (tester) async {
        const activeTrack = Track(
          id: 'np_reduced_platform',
          title: 'Reduced Platform Motion',
          genre: 'Ambient',
          duration: 200,
          user: User(id: 'u1', name: 'Ambient Artist', handle: 'ambient'),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
              isReducedMotionProvider.overrideWithValue(false),
              playbackControllerProvider.overrideWith(
                () => TestPlaybackController(
                  const PlaybackState(
                    currentTrack: activeTrack,
                    status: PlaybackStatus.playing,
                    duration: Duration(seconds: 200),
                  ),
                ),
              ),
            ],
            child: const MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: NowPlayingView(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final ambient = tester.widget<AmbientGradientBackground>(
          find.byType(AmbientGradientBackground),
        );
        expect(ambient.isReducedMotion, isTrue);
      },
    );

    testWidgets(
      'maintains full playback control interactivity under both Full and Reduced motion modes',
      (tester) async {
        const activeTrack = Track(
          id: 'np_interactive',
          title: 'Interactive Track',
          genre: 'Rock',
          duration: 300,
          user: User(id: 'u1', name: 'Rock Artist', handle: 'rock'),
        );

        for (final isReduced in [false, true]) {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ...createStubRepositoryOverrides(),
                isReducedMotionProvider.overrideWithValue(isReduced),
                playbackControllerProvider.overrideWith(
                  () => TestPlaybackController(
                    const PlaybackState(
                      currentTrack: activeTrack,
                      status: PlaybackStatus.playing,
                      duration: Duration(seconds: 300),
                    ),
                  ),
                ),
              ],
              child: const MaterialApp(home: NowPlayingView()),
            ),
          );
          await tester.pumpAndSettle();

          // Tap Play/Pause
          expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
          await tester.tap(find.byIcon(Icons.pause_rounded));
          await tester.pumpAndSettle();

          // Tap Skip Next
          expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
          await tester.tap(find.byIcon(Icons.skip_next_rounded));
          await tester.pumpAndSettle();

          // Tap Skip Previous
          expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
          await tester.tap(find.byIcon(Icons.skip_previous_rounded));
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
