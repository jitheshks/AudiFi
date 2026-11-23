import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/core/theme/app_motion.dart';
import 'package:audifi/core/theme/app_theme.dart';
import 'package:audifi/core/theme/theme_controller.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/discover/presentation/widgets/discover_charts_section.dart';
import 'package:audifi/features/library/presentation/controllers/library_controller.dart';
import 'package:audifi/features/library/presentation/views/library_view.dart';
import 'package:audifi/features/search/presentation/views/search_view.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/widgets/audifi_content_switcher.dart';
import 'package:audifi/shared/widgets/audifi_underlined_tabs.dart';

import '../../test_helpers/stub_repositories.dart';

void main() {
  Widget testWrapper({
    required Widget child,
    bool isReduced = false,
    bool disableAnimations = false,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        ...createStubRepositoryOverrides(),
        if (isReduced) isReducedMotionProvider.overrideWithValue(true),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('AudifiContentSwitcher Architecture & Motion Mechanics', () {
    testWidgets('animates cross-fade with durationShort in Full Motion', (
      tester,
    ) async {
      var currentKey = 'first';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return testWrapper(
              child: AudifiContentSwitcher(
                child: Container(
                  key: ValueKey(currentKey),
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      final animatedSwitcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(animatedSwitcher.duration, equals(AppMotion.durationShort));
      expect(animatedSwitcher.switchInCurve, equals(AppMotion.curveDecelerate));
    });

    testWidgets(
      'resolves duration to Duration.zero under in-app Reduced Motion',
      (tester) async {
        await tester.pumpWidget(
          testWrapper(
            isReduced: true,
            child: AudifiContentSwitcher(
              child: Container(key: const ValueKey('test'), height: 100),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final animatedSwitcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );
        expect(animatedSwitcher.duration, equals(Duration.zero));
      },
    );

    testWidgets(
      'resolves duration to Duration.zero under platform disableAnimations',
      (tester) async {
        await tester.pumpWidget(
          testWrapper(
            disableAnimations: true,
            child: AudifiContentSwitcher(
              child: Container(key: const ValueKey('test'), height: 100),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final animatedSwitcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );
        expect(animatedSwitcher.duration, equals(Duration.zero));
      },
    );

    testWidgets(
      'layoutBuilder wraps outgoing children with IgnorePointer and ExcludeSemantics',
      (tester) async {
        var key = 'item_a';
        late StateSetter updateState;
        await tester.pumpWidget(
          testWrapper(
            child: StatefulBuilder(
              builder: (context, setState) {
                updateState = setState;
                return AudifiContentSwitcher(
                  child: ElevatedButton(
                    key: ValueKey(key),
                    onPressed: () {},
                    child: Text(key),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to item_b
        updateState(() {
          key = 'item_b';
        });
        await tester.pump();
        // Pump mid-flight frame
        await tester.pump(const Duration(milliseconds: 100));

        // During transition, the outgoing item is wrapped in IgnorePointer and ExcludeSemantics
        final ignorePointers = tester.widgetList<IgnorePointer>(
          find.byType(IgnorePointer),
        );
        expect(ignorePointers.any((ip) => ip.ignoring == true), isTrue);

        final excludeSemantics = tester.widgetList<ExcludeSemantics>(
          find.byType(ExcludeSemantics),
        );
        expect(excludeSemantics.isNotEmpty, isTrue);

        await tester.pumpAndSettle();
      },
    );

    testWidgets('handles rapid successive key changes without throwing', (
      tester,
    ) async {
      for (var i = 0; i < 6; i++) {
        await tester.pumpWidget(
          testWrapper(
            child: AudifiContentSwitcher(
              child: SizedBox(key: ValueKey('rapid_$i'), height: 50.0 + i * 10),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expect(find.byType(AudifiContentSwitcher), findsOneWidget);
    });
  });

  group('DiscoverChartsSection Content & Tab Transitions', () {
    testWidgets(
      'switching charts tab animates content via AudifiContentSwitcher',
      (tester) async {
        await tester.pumpWidget(
          testWrapper(
            child: const SingleChildScrollView(child: DiscoverChartsSection()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AudifiContentSwitcher), findsOneWidget);

        // Initially on Top Tracks
        expect(find.byKey(const ValueKey('top_tracks_list')), findsOneWidget);

        // Tap Top Artists tab
        await tester.tap(find.text('Top Artists'));
        // Pump mid-flight frame of tab transition (100ms)
        await tester.pump(const Duration(milliseconds: 100));

        // AudifiContentSwitcher contains transitioning children
        expect(find.byType(AudifiContentSwitcher), findsOneWidget);

        // Settle into Top Artists
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('top_artists_list')), findsOneWidget);
        expect(find.byKey(const ValueKey('top_tracks_list')), findsNothing);

        // Tap Popular Playlists tab
        await tester.tap(find.text('Popular Playlists'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('popular_playlists_list')),
          findsOneWidget,
        );
      },
    );

    testWidgets('charts tab switches immediately in Reduced Motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(
          isReduced: true,
          child: const SingleChildScrollView(child: DiscoverChartsSection()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Top Artists'));
      // In Reduced Motion, transition duration is 0ms
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('top_artists_list')), findsOneWidget);
    });
  });

  group('SearchView Tab & Content-State Transitions', () {
    testWidgets(
      'query input transitions from recent searches to loading and results',
      (tester) async {
        await tester.pumpWidget(testWrapper(child: const SearchView()));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('search_recent_list')),
          findsOneWidget,
        );

        // Enter search query
        await tester.enterText(find.byType(TextField), 'Electronic Odyssey');
        // Wait for debounce timer (350ms)
        await tester.pump(const Duration(milliseconds: 360));

        // Triggers search results loading with stable key
        expect(find.byType(AudifiContentSwitcher), findsOneWidget);

        await tester.pumpAndSettle();
        // Results arrive with stable key
        expect(find.byKey(const ValueKey('search_all_data')), findsOneWidget);
      },
    );

    testWidgets(
      'switching search kind filter tabs smoothly cross-fades content',
      (tester) async {
        await tester.pumpWidget(testWrapper(child: const SearchView()));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Synth');
        await tester.pump(const Duration(milliseconds: 360));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('search_all_data')), findsOneWidget);

        // Tap Tracks tab in tab bar
        final tracksTab = find.descendant(
          of: find.byType(AudifiUnderlinedTabs<String>),
          matching: find.text('Tracks'),
        );
        await tester.tap(tracksTab);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('search_tracks_data')),
          findsOneWidget,
        );

        // Tap Artists tab in tab bar
        final artistsTab = find.descendant(
          of: find.byType(AudifiUnderlinedTabs<String>),
          matching: find.text('Artists'),
        );
        await tester.tap(artistsTab);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('search_users_data')), findsOneWidget);
      },
    );
  });

  group('LibraryView Tab & Empty-State Transitions', () {
    testWidgets(
      'switching tabs cross-fades between personal collections via AudifiContentSwitcher',
      (tester) async {
        await tester.pumpWidget(testWrapper(child: const LibraryView()));
        await tester.pumpAndSettle();

        expect(find.byType(AudifiContentSwitcher), findsOneWidget);
        // Initially empty tracks tab
        expect(
          find.byKey(const ValueKey('library_tracks_empty')),
          findsOneWidget,
        );

        // Tap Artists tab
        await tester.ensureVisible(
          find.byKey(const ValueKey('library_chip_artists')),
        );
        await tester.tap(find.byKey(const ValueKey('library_chip_artists')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('library_artists_empty')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('library_tracks_empty')),
          findsNothing,
        );

        // Tap Playlists tab
        await tester.ensureVisible(
          find.byKey(const ValueKey('library_chip_playlists')),
        );
        await tester.tap(find.byKey(const ValueKey('library_chip_playlists')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('library_playlists_empty')),
          findsOneWidget,
        );

        // Ensure History tab is visible in scrollable tab row before tapping
        await tester.ensureVisible(
          find.byKey(const ValueKey('library_chip_history')),
        );
        await tester.tap(find.byKey(const ValueKey('library_chip_history')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('library_history_empty')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'empty collection transitions smoothly to populated list when track is liked',
      (tester) async {
        const sampleTrack = Track(
          id: 'fav_lib_1',
          title: 'My Favorite Track',
          duration: 180,
          user: User(id: 'u1', name: 'Artist 1', handle: 'art1'),
        );

        await tester.pumpWidget(testWrapper(child: const LibraryView()));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('library_tracks_empty')),
          findsOneWidget,
        );

        // Like a track via controller
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LibraryView)),
        );
        container
            .read(libraryControllerProvider.notifier)
            .toggleLikeTrack(sampleTrack);

        // Pump mid-flight frame of empty -> populated cross-fade (100ms)
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // AudifiContentSwitcher contains active transition
        expect(find.byType(AudifiContentSwitcher), findsOneWidget);

        await tester.pumpAndSettle();

        // Populated list is active
        expect(
          find.byKey(const ValueKey('library_tracks_populated')),
          findsOneWidget,
        );
        expect(find.text('My Favorite Track'), findsOneWidget);

        // Unlike track (populated -> empty transition)
        container
            .read(libraryControllerProvider.notifier)
            .toggleLikeTrack(sampleTrack);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('library_tracks_empty')),
          findsOneWidget,
        );
      },
    );
  });
}
