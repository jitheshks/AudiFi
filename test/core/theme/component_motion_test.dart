import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import 'package:audifi/core/theme/app_motion.dart';
import 'package:audifi/core/theme/app_theme.dart';
import 'package:audifi/core/theme/theme_controller.dart';
import 'package:audifi/features/discover/presentation/widgets/discover_genres_section.dart';
import 'package:audifi/features/playback/domain/entities/repeat_mode.dart';
import 'package:audifi/features/playback/presentation/widgets/mini_player/mini_player_controls.dart';
import 'package:audifi/features/playback/presentation/widgets/now_playing/now_playing_controls.dart';
import 'package:audifi/shared/widgets/audifi_button.dart';
import 'package:audifi/shared/widgets/audifi_favorite_button.dart';
import 'package:audifi/shared/widgets/audifi_loading_indicator.dart';

import '../../test_helpers/stub_repositories.dart';

void main() {
  Widget testWrapper({
    required Widget child,
    bool isReduced = false,
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [
        ...createStubRepositoryOverrides(),
        if (isReduced) isReducedMotionProvider.overrideWithValue(true),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );
  }

  group('AudifiButton Motion & State Transitions', () {
    testWidgets(
      'press scale scales to 0.98 on pointer down and restores to 1.0 on release',
      (tester) async {
        var pressed = false;
        await tester.pumpWidget(
          testWrapper(
            child: AudifiButton(
              text: 'Press Me',
              onPressed: () => pressed = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final buttonFinder = find.byType(AudifiButton);
        final animatedScaleFinder = find.descendant(
          of: buttonFinder,
          matching: find.byType(AnimatedScale),
        );

        // Initially at scale 1.0
        var animatedScale = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(animatedScale.scale, equals(1.0));

        // Start gesture (down)
        final gesture = await tester.startGesture(
          tester.getCenter(buttonFinder),
        );
        await tester.pump(const Duration(milliseconds: 50));

        // AnimatedScale target is updated to AppMotion.pressScale (0.98)
        animatedScale = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(animatedScale.scale, equals(AppMotion.pressScale));
        expect(animatedScale.scale, equals(0.98));

        // Release pointer (up)
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));

        // Restores to 1.0
        animatedScale = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(animatedScale.scale, equals(1.0));
        await tester.pumpAndSettle();
        expect(pressed, isTrue);
      },
    );

    testWidgets(
      'disabled button maintains scale 1.0 and does not scale on pointer down',
      (tester) async {
        await tester.pumpWidget(
          testWrapper(
            child: const AudifiButton(text: 'Disabled', onPressed: null),
          ),
        );
        await tester.pumpAndSettle();

        final buttonFinder = find.byType(AudifiButton);
        final animatedScaleFinder = find.descendant(
          of: buttonFinder,
          matching: find.byType(AnimatedScale),
        );

        var animatedScale = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(animatedScale.scale, equals(1.0));

        final gesture = await tester.startGesture(
          tester.getCenter(buttonFinder),
        );
        await tester.pump(const Duration(milliseconds: 50));

        animatedScale = tester.widget<AnimatedScale>(animatedScaleFinder);
        expect(animatedScale.scale, equals(1.0));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'loading button transitions to spinner via AnimatedSwitcher and prevents press scaling',
      (tester) async {
        await tester.pumpWidget(
          testWrapper(
            child: AudifiButton(
              text: 'Loading',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));

        final buttonFinder = find.byType(AudifiButton);
        final switcherFinder = find.descendant(
          of: buttonFinder,
          matching: find.byType(AnimatedSwitcher),
        );
        expect(switcherFinder, findsOneWidget);
        expect(find.byType(AudifiLoadingIndicator), findsOneWidget);

        // Start gesture on loading button
        final gesture = await tester.startGesture(
          tester.getCenter(buttonFinder),
        );
        await tester.pump(const Duration(milliseconds: 50));

        final animatedScaleFinder = find.descendant(
          of: buttonFinder,
          matching: find.byType(AnimatedScale),
        );
        final animatedScale = tester.widget<AnimatedScale>(animatedScaleFinder);
        // Does not scale down when loading
        expect(animatedScale.scale, equals(1.0));

        await gesture.up();
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets('reduced motion disables press scaling animation duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(
          isReduced: true,
          child: AudifiButton(text: 'Reduced', onPressed: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final animatedScaleFinder = find.descendant(
        of: find.byType(AudifiButton),
        matching: find.byType(AnimatedScale),
      );
      final animatedScale = tester.widget<AnimatedScale>(animatedScaleFinder);
      expect(animatedScale.duration, equals(Duration.zero));
    });
  });

  group('AudifiFavoriteButton Pop Animation & Color Transition', () {
    testWidgets(
      'like toggle triggers heart pop sequence peaking above 1.0 and returning to 1.0',
      (tester) async {
        var isFav = false;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return testWrapper(
                child: AudifiFavoriteButton(
                  isFavorite: isFav,
                  onToggle: () => setState(() => isFav = !isFav),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

        // Tap to favorite
        await tester.tap(find.byType(AudifiFavoriteButton));
        // Pump initial frame to start animation
        await tester.pump();

        // Advance into the peak of the pop sequence (mid-flight of 200ms durationShort)
        await tester.pump(const Duration(milliseconds: 90));

        final transformFinder = find.byKey(
          const ValueKey('audifi_favorite_scale_transform'),
        );
        expect(transformFinder, findsOneWidget);

        final transformWidget = tester.widget<Transform>(transformFinder);
        final currentScale = transformWidget.transform.entry(0, 0);
        // The heart pop peaks at 1.25, so mid-flight scale must be greater than 1.0
        expect(currentScale, greaterThan(1.0));

        // Let the pop animation complete
        await tester.pumpAndSettle();

        final finalTransform = tester.widget<Transform>(transformFinder);
        expect(finalTransform.transform.entry(0, 0), equals(1.0));
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'unlike toggle triggers subtle dip sequence below 1.0 and returning to 1.0',
      (tester) async {
        var isFav = true;
        var toggleCalled = false;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return testWrapper(
                child: AudifiFavoriteButton(
                  isFavorite: isFav,
                  onToggle: () {
                    toggleCalled = true;
                    setState(() => isFav = !isFav);
                  },
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

        // Tap to unfavorite
        await tester.tap(find.byType(AudifiFavoriteButton));
        expect(toggleCalled, isTrue);
        await tester.pump();

        // Advance into the dip of the unlike sequence
        await tester.pump(const Duration(milliseconds: 50));

        final transformFinder = find.byKey(
          const ValueKey('audifi_favorite_scale_transform'),
        );
        final transformWidget = tester.widget<Transform>(transformFinder);
        final currentScale = transformWidget.transform.entry(0, 0);
        // The unlike dips to 0.88, so mid-flight scale must be less than 1.0
        expect(currentScale, lessThan(1.0));

        await tester.pumpAndSettle();
        final finalTransform = tester.widget<Transform>(transformFinder);
        expect(finalTransform.transform.entry(0, 0), equals(1.0));
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      },
    );

    testWidgets('rapid repeated toggles remain stable without exceptions', (
      tester,
    ) async {
      var isFav = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return testWrapper(
              child: AudifiFavoriteButton(
                isFavorite: isFav,
                onToggle: () => setState(() => isFav = !isFav),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Rapidly tap 5 times without pumpAndSettle
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(AudifiFavoriteButton));
        await tester.pump(const Duration(milliseconds: 30));
      }

      // Settle completely
      await tester.pumpAndSettle();
      expect(find.byType(AudifiFavoriteButton), findsOneWidget);
    });

    testWidgets('reduced motion avoids heart pop scale animation', (
      tester,
    ) async {
      var isFav = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return testWrapper(
              isReduced: true,
              child: AudifiFavoriteButton(
                isFavorite: isFav,
                onToggle: () => setState(() => isFav = !isFav),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AudifiFavoriteButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));

      final transformFinder = find.byKey(
        const ValueKey('audifi_favorite_scale_transform'),
      );
      final transformWidget = tester.widget<Transform>(transformFinder);
      // Scale remains exactly 1.0 under reduced motion
      expect(transformWidget.transform.entry(0, 0), equals(1.0));

      await tester.pumpAndSettle();
    });

    testWidgets('meets WCAG minimum tap target and accessibility guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        testWrapper(
          child: AudifiFavoriteButton(isFavorite: false, onToggle: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });
  });

  group('Playback Controls AnimatedSwitcher & Icon Transitions', () {
    testWidgets(
      'NowPlayingControls play/pause button switches icons smoothly with AnimatedSwitcher',
      (tester) async {
        var playing = false;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return testWrapper(
                child: NowPlayingControls(
                  isPlaying: playing,
                  isBuffering: false,
                  isShuffle: false,
                  repeatMode: RepeatMode.off,
                  onPlayPause: () => setState(() => playing = !playing),
                  onNext: () {},
                  onPrevious: () {},
                  onToggleShuffle: () {},
                  onCycleRepeat: () {},
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.byIcon(Icons.pause_rounded), findsNothing);

        // Tap play button
        await tester.tap(find.byIcon(Icons.play_arrow_rounded));
        // Pump mid-flight frame of switcher
        await tester.pump(const Duration(milliseconds: 75));

        // AnimatedSwitcher contains the play/pause icon
        final switchers = find.byType(AnimatedSwitcher);
        expect(switchers, findsWidgets);

        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      },
    );

    testWidgets(
      'NowPlayingControls repeat button transitions repeat modes via AnimatedSwitcher',
      (tester) async {
        var mode = RepeatMode.all;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return testWrapper(
                child: NowPlayingControls(
                  isPlaying: true,
                  isBuffering: false,
                  isShuffle: false,
                  repeatMode: mode,
                  onPlayPause: () {},
                  onNext: () {},
                  onPrevious: () {},
                  onToggleShuffle: () {},
                  onCycleRepeat: () {
                    setState(() {
                      mode = mode == RepeatMode.all
                          ? RepeatMode.one
                          : RepeatMode.off;
                    });
                  },
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
        expect(find.byIcon(Icons.repeat_one_rounded), findsNothing);

        // Cycle repeat mode
        await tester.tap(find.byIcon(Icons.repeat_rounded));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.repeat_one_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'NowPlayingControls shuffle indicator dot scales with AnimatedScale',
      (tester) async {
        var shuffle = false;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return testWrapper(
                child: NowPlayingControls(
                  isPlaying: true,
                  isBuffering: false,
                  isShuffle: shuffle,
                  repeatMode: RepeatMode.off,
                  onPlayPause: () {},
                  onNext: () {},
                  onPrevious: () {},
                  onToggleShuffle: () => setState(() => shuffle = !shuffle),
                  onCycleRepeat: () {},
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // When shuffle is false, AnimatedScale on the indicator dot is 0.0
        final animatedScales = tester.widgetList<AnimatedScale>(
          find.byType(AnimatedScale),
        );
        expect(animatedScales.any((s) => s.scale == 0.0), isTrue);

        // Toggle shuffle on
        await tester.tap(find.byIcon(Icons.shuffle_rounded));
        await tester.pumpAndSettle();

        // When shuffle is true, AnimatedScale on the indicator dot is 1.0
        final updatedScales = tester.widgetList<AnimatedScale>(
          find.byType(AnimatedScale),
        );
        expect(updatedScales.any((s) => s.scale == 1.0), isTrue);
      },
    );

    testWidgets(
      'MiniPlayerControls play/pause transitions using AnimatedSwitcher',
      (tester) async {
        var playing = false;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return testWrapper(
                child: MiniPlayerControls(
                  isPlaying: playing,
                  isBuffering: false,
                  onPlayPause: () => setState(() => playing = !playing),
                  onNext: () {},
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.byIcon(Icons.pause_rounded), findsNothing);

        await tester.tap(find.byIcon(Icons.play_arrow_rounded));
        await tester.pump(const Duration(milliseconds: 75));

        final switcherFinder = find.byType(AnimatedSwitcher);
        expect(switcherFinder, findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      },
    );
  });

  group('DiscoverGenresSection Animated Selection', () {
    testWidgets(
      'genre card selection animates border smoothly without layout dimension shift',
      (tester) async {
        await tester.pumpWidget(
          testWrapper(child: const DiscoverGenresSection()),
        );
        await tester.pumpAndSettle();

        // Discover genre cards render as AnimatedContainers
        final animatedContainers = find.byType(AnimatedContainer);
        expect(animatedContainers, findsWidgets);

        final initialBox = tester.renderObject<RenderBox>(
          animatedContainers.first,
        );
        final initialSize = initialBox.size;
        expect(initialSize.width, equals(140.0));
        expect(initialSize.height, equals(84.0));

        // Tap the first genre card
        await tester.tap(animatedContainers.first);
        // Pump mid-flight animation
        await tester.pump(const Duration(milliseconds: 100));

        // Verify dimensions remain exactly 140x84 during animation (zero layout jump)
        final midBox = tester.renderObject<RenderBox>(animatedContainers.first);
        expect(midBox.size.width, equals(140.0));
        expect(midBox.size.height, equals(84.0));

        await tester.pumpAndSettle();

        final finalBox = tester.renderObject<RenderBox>(
          animatedContainers.first,
        );
        expect(finalBox.size.width, equals(140.0));
        expect(finalBox.size.height, equals(84.0));
      },
    );

    testWidgets('reduced motion selects genre card with Duration.zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(isReduced: true, child: const DiscoverGenresSection()),
      );
      await tester.pumpAndSettle();

      final animatedContainers = find.byType(AnimatedContainer);
      final firstContainer = tester.widget<AnimatedContainer>(
        animatedContainers.first,
      );
      expect(firstContainer.duration, equals(Duration.zero));
    });
  });
}
