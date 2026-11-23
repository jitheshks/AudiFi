import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/library/domain/entities/user_library.dart';
import 'package:audifi/features/library/presentation/views/library_view.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  group('LibraryView — In-Library Search, Shuffle & Sorting Verification', () {
    const trackA = Track(
      id: 't_a',
      title: 'Alpha Wave',
      duration: 180,
      user: User(id: 'u1', name: 'Zeta Artist', handle: 'zeta'),
    );

    const trackB = Track(
      id: 't_b',
      title: 'Beta Pulse',
      duration: 220,
      user: User(id: 'u2', name: 'Apex Creator', handle: 'apex'),
    );

    Widget createTestWidget({
      LibraryCategory? initialTab,
      List<Track> likedTracks = const [],
    }) {
      final stubLib = StubLibraryRepository()
        ..libraryState = UserLibrary(likedTracks: likedTracks);

      return ProviderScope(
        overrides: [...createStubRepositoryOverrides(libraryRepo: stubLib)],
        child: MaterialApp(home: LibraryView(initialTab: initialTab)),
      );
    }

    testWidgets(
      'in-library search filters liked tracks by title in real-time',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestWidget(
            initialTab: LibraryCategory.liked,
            likedTracks: [trackA, trackB],
          ),
        );
        await tester.pumpAndSettle();

        // Both tracks visible initially
        expect(find.text('Alpha Wave'), findsOneWidget);
        expect(find.text('Beta Pulse'), findsOneWidget);

        // Search for 'Alpha'
        await tester.enterText(find.byType(TextField), 'Alpha');
        await tester.pumpAndSettle();

        // Only Alpha Wave matches
        expect(find.text('Alpha Wave'), findsOneWidget);
        expect(find.text('Beta Pulse'), findsNothing);

        // Clear search
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Alpha Wave'), findsOneWidget);
        expect(find.text('Beta Pulse'), findsOneWidget);
      },
    );

    testWidgets(
      'in-library search displays empty state with clear action on non-match',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestWidget(
            initialTab: LibraryCategory.liked,
            likedTracks: [trackA, trackB],
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'NonExistent');
        await tester.pumpAndSettle();

        expect(find.text('No matches for "nonexistent"'), findsOneWidget);
        expect(find.text('Clear search'), findsOneWidget);

        await tester.tap(find.text('Clear search'));
        await tester.pumpAndSettle();

        expect(find.text('Alpha Wave'), findsOneWidget);
        expect(find.text('Beta Pulse'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Shuffle and Play All action buttons on Liked category',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestWidget(
            initialTab: LibraryCategory.liked,
            likedTracks: [trackA, trackB],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Shuffle'), findsOneWidget);
        expect(find.text('Play All'), findsOneWidget);

        // Tap Shuffle and settle playback
        await tester.tap(find.text('Shuffle'));
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets('initialTab parameter opens requested category directly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(initialTab: LibraryCategory.downloaded),
      );
      await tester.pumpAndSettle();

      // Directly opens downloaded tab
      expect(find.text('No downloaded tracks.'), findsOneWidget);
    });

    testWidgets('sort menu options can be selected', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          initialTab: LibraryCategory.liked,
          likedTracks: [trackA, trackB],
        ),
      );
      await tester.pumpAndSettle();

      // Default sort indicator
      expect(find.text('Recently Added'), findsOneWidget);

      // Tap sort menu
      await tester.tap(find.text('Recently Added'));
      await tester.pumpAndSettle();

      // Select Title (A-Z)
      await tester.tap(find.text('Title (A-Z)'));
      await tester.pumpAndSettle();

      expect(find.text('Title (A-Z)'), findsOneWidget);
    });
  });
}
