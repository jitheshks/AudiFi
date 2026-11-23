import 'package:audifi/app.dart';
import 'package:audifi/app/router/app_navigation_shell.dart';
import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/widgets/mini_player/mini_player.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_helpers/stub_repositories.dart';

void main() {
  group('Navigation & Bottom Navigation Visibility', () {
    const testTrack = Track(
      id: 'test_track_1',
      title: 'Midnight City',
      duration: 240,
      user: User(id: 'u1', name: 'M83', handle: 'm83'),
    );

    testWidgets(
      'AudifiApp launches and navigates through 5 primary destinations',
      (tester) async {
        // Set standard mobile screen size
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

        // 1. Initial destination is Home
        expect(find.text('Explore Discover'), findsWidgets);
        expect(find.text('Liked'), findsOneWidget);
        expect(find.text('Offline'), findsOneWidget);
        expect(find.text('Device'), findsOneWidget);

        // 2. Navigate to Discover
        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();
        expect(find.text('Genres'), findsOneWidget);
        expect(find.text('Charts'), findsOneWidget);
        expect(find.text('Popular Playlists'), findsOneWidget);

        // 3. Navigate to Search
        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();
        expect(
          find.text('Search songs, artists, or playlists'),
          findsOneWidget,
        );
        expect(find.text('Find What You Love'), findsOneWidget);

        // 4. Navigate to Library
        await tester.tap(find.text('Library'));
        await tester.pumpAndSettle();
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Liked'), findsWidgets);
        expect(find.text('Local Files'), findsWidgets);

        // 5. Navigate to Settings matching settings.png
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(find.text('PLAYBACK'), findsOneWidget);
        expect(find.text('AUDIO'), findsOneWidget);
        expect(find.text('APPEARANCE'), findsOneWidget);

        // 6. Navigate to Appearance drill-down matching appearance.png
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
        expect(find.text('THEME'), findsOneWidget);
        expect(find.text('ACCENT'), findsOneWidget);
        expect(find.text('PLAYER'), findsOneWidget);
        expect(find.text('ANIMATION'), findsOneWidget);
      },
    );

    testWidgets(
      'Bottom navigation bar is visible on main destinations and hidden on Appearance and Accent Color',
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

        Finder bottomNavHome() => find.descendant(
          of: find.byType(InkWell),
          matching: find.text('Home'),
        );
        Finder bottomNavSettings() => find.descendant(
          of: find.byType(InkWell),
          matching: find.text('Settings'),
        );

        // 1. Home - bottom navigation visible
        expect(bottomNavHome(), findsOneWidget);
        expect(bottomNavSettings(), findsOneWidget);

        // 2. Discover - visible
        await tester.tap(find.text('Discover'));
        await tester.pumpAndSettle();
        expect(bottomNavHome(), findsOneWidget);

        // 3. Search - visible
        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();
        expect(bottomNavHome(), findsOneWidget);

        // 4. Library - visible
        await tester.tap(find.text('Library'));
        await tester.pumpAndSettle();
        expect(bottomNavHome(), findsOneWidget);

        // 5. Settings - visible
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(bottomNavHome(), findsOneWidget);
        expect(bottomNavSettings(), findsOneWidget);

        // 6. Navigate to Appearance - bottom navigation HIDDEN
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
        expect(find.text('Appearance'), findsOneWidget); // Header
        expect(bottomNavHome(), findsNothing);
        expect(bottomNavSettings(), findsNothing);

        // 7. Navigate to Accent Color - bottom navigation HIDDEN
        await tester.tap(find.text('Accent color'));
        await tester.pumpAndSettle();
        expect(find.text('Accent color'), findsOneWidget); // Header
        expect(bottomNavHome(), findsNothing);
        expect(bottomNavSettings(), findsNothing);

        // 8. Return to Appearance - still HIDDEN
        await tester.tap(find.text('‹ Appearance'));
        await tester.pumpAndSettle();
        expect(find.text('Appearance'), findsOneWidget);
        expect(bottomNavHome(), findsNothing);
        expect(bottomNavSettings(), findsNothing);

        // 9. Return to Settings - bottom navigation VISIBLE again
        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();
        expect(find.text('PLAYBACK'), findsOneWidget);
        expect(bottomNavHome(), findsOneWidget);
        expect(bottomNavSettings(), findsOneWidget);

        // 10. Switch between main application tabs - visible
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(bottomNavHome(), findsOneWidget);

        await tester.tap(find.text('Library'));
        await tester.pumpAndSettle();
        expect(bottomNavHome(), findsOneWidget);
      },
    );

    testWidgets(
      'MiniPlayer remains functional and visible when bottom navigation is hidden during active playback',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        late WidgetRef capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: createStubRepositoryOverrides(),
            child: Consumer(
              builder: (context, ref, child) {
                capturedRef = ref;
                return const AudifiApp();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        Finder bottomNavHome() => find.descendant(
          of: find.byType(InkWell),
          matching: find.text('Home'),
        );
        Finder miniPlayerTrackTitle() => find.descendant(
          of: find.byType(MiniPlayer),
          matching: find.text('Midnight City'),
        );

        // Start playback
        capturedRef
            .read(playbackControllerProvider.notifier)
            .playTrack(testTrack);
        await tester.pumpAndSettle();

        // On Home: MiniPlayer is visible AND bottom nav is visible
        expect(miniPlayerTrackTitle(), findsOneWidget);
        expect(bottomNavHome(), findsOneWidget);

        // Navigate to Settings
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(miniPlayerTrackTitle(), findsOneWidget);
        expect(bottomNavHome(), findsOneWidget);

        // Navigate to Appearance: MiniPlayer remains, bottom nav is hidden
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
        expect(miniPlayerTrackTitle(), findsOneWidget);
        expect(bottomNavHome(), findsNothing);

        // Navigate to Accent Color: MiniPlayer remains, bottom nav is hidden
        await tester.tap(find.text('Accent color'));
        await tester.pumpAndSettle();
        expect(miniPlayerTrackTitle(), findsOneWidget);
        expect(bottomNavHome(), findsNothing);

        // Back to Appearance
        await tester.tap(find.text('‹ Appearance'));
        await tester.pumpAndSettle();
        expect(miniPlayerTrackTitle(), findsOneWidget);
        expect(bottomNavHome(), findsNothing);

        // Back to Settings: MiniPlayer remains, bottom nav is restored
        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();
        expect(miniPlayerTrackTitle(), findsOneWidget);
        expect(bottomNavHome(), findsOneWidget);
      },
    );

    testWidgets(
      'Bottom navigation selected state uses global accent color without selected outline or pill border',
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

        // 1. Initial destination is Home
        // Find Home text widget
        final homeTextFinder = find.descendant(
          of: find.byType(InkWell),
          matching: find.text('Home'),
        );
        expect(homeTextFinder, findsOneWidget);

        // Verify active text uses global accent (Color(0xFFBD3535))
        final defaultTextStyle = tester.widget<DefaultTextStyle>(
          find
              .ancestor(
                of: homeTextFinder,
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        );
        expect(defaultTextStyle.style.color, AppColors.accent);

        // 2. Inactive destination (Discover) uses muted text color
        final discoverTextFinder = find.descendant(
          of: find.byType(InkWell),
          matching: find.text('Discover'),
        );
        expect(discoverTextFinder, findsOneWidget);
        final discoverTextStyle = tester.widget<DefaultTextStyle>(
          find
              .ancestor(
                of: discoverTextFinder,
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        );
        expect(discoverTextStyle.style.color, isNot(AppColors.accent));

        // 3. Confirm NO selected outline or border around active item
        // Find containers under the Home InkWell
        final homeInkWell = find
            .ancestor(of: homeTextFinder, matching: find.byType(InkWell))
            .first;
        final containers = tester.widgetList<Container>(
          find.descendant(of: homeInkWell, matching: find.byType(Container)),
        );
        for (final container in containers) {
          final decoration = container.decoration;
          if (decoration is BoxDecoration) {
            // Must have NO border
            expect(decoration.border, isNull);
          }
        }
      },
    );

    testWidgets(
      'Switching destinations smoothly updates colors and maintains layout stability',
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

        final homeTextFinder = find.descendant(
          of: find.byType(InkWell),
          matching: find.text('Home'),
        );
        final discoverTextFinder = find.descendant(
          of: find.byType(InkWell),
          matching: find.text('Discover'),
        );

        final homeRectBefore = tester.getRect(homeTextFinder);
        final discoverRectBefore = tester.getRect(discoverTextFinder);

        // Tap Discover
        await tester.tap(discoverTextFinder);
        await tester.pumpAndSettle();

        final homeRectAfter = tester.getRect(homeTextFinder);
        final discoverRectAfter = tester.getRect(discoverTextFinder);

        // Verify item positions do not shift when selection changes
        expect(homeRectAfter, equals(homeRectBefore));
        expect(discoverRectAfter, equals(discoverRectBefore));

        // Verify Discover now has active accent color
        final discoverTextStyle = tester.widget<DefaultTextStyle>(
          find
              .ancestor(
                of: discoverTextFinder,
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        );
        expect(discoverTextStyle.style.color, AppColors.accent);
      },
    );

    test('isBottomNavVisible route matching returns expected visibility', () {
      expect(AppNavigationShell.isBottomNavVisible('/'), isTrue);
      expect(AppNavigationShell.isBottomNavVisible('/discover'), isTrue);
      expect(AppNavigationShell.isBottomNavVisible('/search'), isTrue);
      expect(AppNavigationShell.isBottomNavVisible('/library'), isTrue);
      expect(AppNavigationShell.isBottomNavVisible('/settings'), isTrue);
      expect(
        AppNavigationShell.isBottomNavVisible('/settings/appearance'),
        isFalse,
      );
      expect(
        AppNavigationShell.isBottomNavVisible('/settings/appearance/accent'),
        isFalse,
      );
      expect(
        AppNavigationShell.isBottomNavVisible('/settings/playback'),
        isFalse,
      );
      expect(AppNavigationShell.isBottomNavVisible('/settings/audio'), isFalse);
    });
  });
}
