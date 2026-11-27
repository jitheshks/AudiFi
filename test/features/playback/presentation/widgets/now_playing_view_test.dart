import 'package:audifi/core/theme/theme_controller.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/entities/repeat_mode.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/views/now_playing_view.dart';
import 'package:audifi/features/playback/presentation/widgets/now_playing/ambient_gradient_background.dart';
import 'package:audifi/features/playback/presentation/widgets/now_playing/now_playing_app_bar.dart';
import 'package:audifi/features/playback/presentation/widgets/queue/queue_sheet.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/widgets/audifi_track_options_sheet.dart';
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
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      // Exactly one Queue entry point exists (in the bottom action area)
      expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      // Audio Info button is completely removed
      expect(find.text('Audio Info'), findsNothing);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);
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

    testWidgets('bottom Queue button opens QueueSheet as single entry point', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const activeTrack = Track(
        id: 'np_queue_test',
        title: 'Queue Test Track',
        user: User(id: 'u1', name: 'Queue Artist', handle: 'queue'),
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
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: NowPlayingView()),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar should NOT have a queue button
      // Find the top bar
      final topBar = find.byType(NowPlayingAppBar);
      expect(
        find.descendant(of: topBar, matching: find.byIcon(Icons.queue_music_rounded)),
        findsNothing,
      );

      // Bottom Queue button is the sole queue entry point
      final queueButton = find.widgetWithText(TextButton, 'Queue');
      expect(queueButton, findsOneWidget);

      await tester.ensureVisible(queueButton);
      await tester.tap(queueButton);
      await tester.pumpAndSettle();

      // Verify QueueSheet opened
      expect(find.byType(QueueSheet), findsOneWidget);
      expect(find.text('Up Next'), findsOneWidget);
    });

    testWidgets('top-right overflow menu opens track options sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const activeTrack = Track(
        id: 'np_options_test',
        title: 'Options Test Track',
        user: User(id: 'u1', name: 'Options Artist', handle: 'options'),
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
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: NowPlayingView()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 3-dot overflow menu
      final moreButton = find.byIcon(Icons.more_vert_rounded);
      expect(moreButton, findsOneWidget);

      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Verify track options sheet opened with standard actions
      expect(find.byType(AudifiTrackOptionsSheet), findsOneWidget);
      // For the currently playing track, Play Next is hidden per spec
      expect(find.text('Play Next'), findsNothing);
      expect(find.text('Add to Queue'), findsOneWidget);
      expect(find.text('Add to Playlist'), findsOneWidget);
      expect(find.text('Go to Artist'), findsOneWidget);
      // Verify no Audio Info menu item exists
      expect(find.text('Audio Info'), findsNothing);
    });

    testWidgets('remains responsive without overflow across portrait and landscape', (
      tester,
    ) async {
      const activeTrack = Track(
        id: 'np_responsive_test',
        title: 'Responsive Track',
        genre: 'Electronic',
        duration: 200,
        user: User(id: 'u1', name: 'Responsive Artist', handle: 'resp'),
      );

      for (final size in [
        const Size(360, 640),  // Compact mobile portrait
        const Size(412, 915),  // Modern phone portrait (e.g. POCO F7)
        const Size(800, 1280), // Tablet portrait
        const Size(915, 412),  // Phone landscape
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
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

        // Verify core elements exist and no overflow occurred
        expect(find.text('NOW PLAYING'), findsOneWidget);
        expect(find.text('Queue'), findsOneWidget);
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
