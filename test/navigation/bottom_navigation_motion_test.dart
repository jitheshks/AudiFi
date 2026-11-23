import 'package:audifi/app.dart';
import 'package:audifi/app/router/app_navigation_shell.dart';
import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/core/theme/theme_controller.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/settings/presentation/views/settings_view.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_helpers/stub_repositories.dart';

class MutablePlaybackController extends PlaybackController {
  MutablePlaybackController(this._initial);

  final PlaybackState _initial;

  @override
  PlaybackState build() => _initial;

  void setTrack(Track? track) {
    state = PlaybackState(
      currentTrack: track,
      status: track != null ? PlaybackStatus.playing : PlaybackStatus.idle,
      duration: track != null
          ? Duration(seconds: track.duration)
          : Duration.zero,
    );
  }
}

void main() {
  const testTrack = Track(
    id: 'motion_track_1',
    title: 'Sliding Motion',
    genre: 'Electronic',
    duration: 180,
    user: User(id: 'u1', name: 'Motion Artist', handle: 'motion'),
  );

  group('Bottom Navigation Sliding Selection & Motion Consistency', () {
    testWidgets(
      'smoothly animates sliding selection when switching across all five destinations in Full Motion',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
              isReducedMotionProvider.overrideWithValue(false),
            ],
            child: const AudifiApp(),
          ),
        );
        await tester.pumpAndSettle();

        final destinations = [
          'Home',
          'Discover',
          'Search',
          'Library',
          'Settings',
        ];

        // Initial destination: Home (0)
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.selected == true &&
                w.properties.label == 'Home',
          ),
          findsOneWidget,
        );

        for (int i = 1; i < destinations.length; i++) {
          final targetLabel = destinations[i];
          final targetFinder = find.descendant(
            of: find.byType(AudifiBottomNavBar),
            matching: find.text(targetLabel),
          );

          // Tap target destination
          await tester.tap(targetFinder);
          await tester.pump();

          // Mid-way through transition (125ms): animation is actively running
          await tester.pump(const Duration(milliseconds: 125));
          expect(tester.hasRunningAnimations, isTrue);

          // Settle the transition
          await tester.pumpAndSettle();
          expect(tester.hasRunningAnimations, isFalse);

          // Verify target destination is selected
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  w.properties.selected == true &&
                  w.properties.label == targetLabel,
            ),
            findsOneWidget,
          );

          // Verify previous destination is no longer selected
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  w.properties.selected == true &&
                  w.properties.label == destinations[i - 1],
            ),
            findsNothing,
          );

          // Verify active item color is AppColors.accent
          final textStyle = tester.widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: targetFinder,
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          );
          expect(textStyle.style.color, AppColors.accent);
        }
      },
    );

    testWidgets(
      'switches destinations immediately without animation in Reduced Motion',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
              isReducedMotionProvider.overrideWithValue(true),
            ],
            child: const AudifiApp(),
          ),
        );
        await tester.pumpAndSettle();

        final searchFinder = find.descendant(
          of: find.byType(AudifiBottomNavBar),
          matching: find.text('Search'),
        );

        // Tap Search under Reduced Motion
        await tester.tap(searchFinder);
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.selected == true &&
                w.properties.label == 'Search',
          ),
          findsOneWidget,
        );

        final navBar = tester.widget<AudifiBottomNavBar>(
          find.byType(AudifiBottomNavBar),
        );
        expect(navBar.currentIndex, 2);
      },
    );

    testWidgets(
      'confirms zero selection background, pill, square, or border on AudifiBottomNavBar',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: createStubRepositoryOverrides(),
            child: const AudifiApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Examine each InkWell destination item
        final inkWells = find.descendant(
          of: find.byType(AudifiBottomNavBar),
          matching: find.byType(InkWell),
        );
        expect(inkWells, findsNWidgets(5));

        for (int i = 0; i < 5; i++) {
          final itemContainers = tester.widgetList<Container>(
            find.descendant(
              of: inkWells.at(i),
              matching: find.byType(Container),
            ),
          );

          for (final container in itemContainers) {
            final decoration = container.decoration;
            if (decoration is BoxDecoration) {
              expect(decoration.border, isNull);
              expect(decoration.shape, BoxShape.rectangle);
              // Background color on items must be null (transparent)
              expect(decoration.color, isNull);
            }
          }
        }
      },
    );
  });

  group('Bottom Navigation Visibility & Route Transitions', () {
    testWidgets(
      'animates bottom nav visibility smoothly when navigating into Settings sub-screens',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
              isReducedMotionProvider.overrideWithValue(false),
            ],
            child: const AudifiApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to Settings
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(AudifiBottomNavBar), findsOneWidget);

        // Tap Appearance -> enters /settings/appearance (bottom nav should animate away)
        await tester.tap(find.text('Appearance'));
        await tester.pump();

        // 125ms mid-way: animating
        await tester.pump(const Duration(milliseconds: 125));
        expect(tester.hasRunningAnimations, isTrue);

        // Settle route and visibility transition
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);

        // Bottom nav is hidden
        final visibilityFinder = find.byType(AudifiBottomNavVisibility);
        expect(visibilityFinder, findsOneWidget);
        final visibilityWidget = tester.widget<AudifiBottomNavVisibility>(
          visibilityFinder,
        );
        expect(visibilityWidget.visible, isFalse);

        // Back button: navigate back to Settings
        await tester.tap(find.text('‹ Settings'));
        await tester.pump();

        // 125ms mid-way: animating back in
        await tester.pump(const Duration(milliseconds: 125));
        expect(tester.hasRunningAnimations, isTrue);

        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        final restoredVisibility = tester.widget<AudifiBottomNavVisibility>(
          visibilityFinder,
        );
        expect(restoredVisibility.visible, isTrue);
      },
    );

    testWidgets(
      'preserves nested navigation and back-button behavior across sub-routes',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: createStubRepositoryOverrides(),
            child: const AudifiApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Settings -> Appearance -> Accent Color
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Accent color'));
        await tester.pumpAndSettle();

        expect(find.text('‹ Appearance'), findsOneWidget);
        expect(find.text('Accent color'), findsOneWidget);

        // Pop back to Appearance
        await tester.tap(find.text('‹ Appearance'));
        await tester.pumpAndSettle();
        expect(find.text('Appearance'), findsOneWidget);

        // Pop back to Settings
        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsView), findsOneWidget);
      },
    );
  });

  group('MiniPlayer Entrance, Exit & Motion Transitions', () {
    testWidgets(
      'animates MiniPlayer entrance and exit over durationMedium (300ms) in Full Motion',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        late MutablePlaybackController mutableController;
        mutableController = MutablePlaybackController(
          const PlaybackState(status: PlaybackStatus.idle),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
              isReducedMotionProvider.overrideWithValue(false),
              playbackControllerProvider.overrideWith(() => mutableController),
            ],
            child: const AudifiApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Initially no track: MiniPlayer renders SizedBox.shrink
        expect(find.text('Sliding Motion'), findsNothing);

        // Start playback -> triggers MiniPlayer entrance animation
        mutableController.setTrack(testTrack);
        await tester.pump();

        // 150ms mid-way: entrance animation is running
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.hasRunningAnimations, isTrue);

        // Settle entrance
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.text('Sliding Motion'), findsOneWidget);

        // Clear track -> triggers MiniPlayer exit animation
        mutableController.setTrack(null);
        await tester.pump();

        // 150ms mid-way: exit animation is running
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.hasRunningAnimations, isTrue);

        // Settle exit
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.text('Sliding Motion'), findsNothing);
      },
    );

    testWidgets('MiniPlayer enters and exits immediately in Reduced Motion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late MutablePlaybackController mutableController;
      mutableController = MutablePlaybackController(
        const PlaybackState(status: PlaybackStatus.idle),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...createStubRepositoryOverrides(),
            isReducedMotionProvider.overrideWithValue(true),
            playbackControllerProvider.overrideWith(() => mutableController),
          ],
          child: const AudifiApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Start playback
      mutableController.setTrack(testTrack);
      await tester.pump();

      // In Reduced Motion, it should immediately be visible without running animations
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Sliding Motion'), findsOneWidget);

      // Stop playback
      mutableController.setTrack(null);
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Sliding Motion'), findsNothing);
    });
  });

  group('NavigationRail Motion & Tablet Adaptations', () {
    testWidgets(
      'renders NavigationRail on wide viewports and supports all destinations',
      (tester) async {
        // Set wide viewport (tablet / desktop)
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: createStubRepositoryOverrides(),
            child: const AudifiApp(),
          ),
        );
        await tester.pumpAndSettle();

        // NavigationRail is present on wide viewports
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(AudifiBottomNavBar), findsNothing);

        // Switch to Discover on NavigationRail
        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, 1);

        // Switch to Settings on NavigationRail
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        final updatedRail = tester.widget<NavigationRail>(
          find.byType(NavigationRail),
        );
        expect(updatedRail.selectedIndex, 4);
      },
    );
  });
}
