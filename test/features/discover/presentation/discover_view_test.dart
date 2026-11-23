import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/features/discover/presentation/views/discover_view.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  group('DiscoverView — Catalog Exploration Verification', () {
    Widget createTestWidget({
      StubTrackRepository? trackRepo,
      StubPlaylistRepository? playlistRepo,
      StubUserRepository? userRepo,
    }) {
      return ProviderScope(
        overrides: [
          ...createStubRepositoryOverrides(
            trackRepo: trackRepo ?? StubTrackRepository(),
            playlistRepo: playlistRepo ?? StubPlaylistRepository(),
            userRepo: userRepo ?? StubUserRepository(),
          ),
        ],
        child: const MaterialApp(home: DiscoverView()),
      );
    }

    testWidgets(
      'renders all verified catalog discovery sections without duplication',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Heading
        expect(find.text('Discover'), findsOneWidget);

        // Genres section
        expect(find.text('Genres'), findsOneWidget);
        expect(find.text('Electronic'), findsOneWidget);
        expect(find.text('Hip-Hop/Rap'), findsOneWidget);

        // Moods section
        expect(find.text('Moods'), findsOneWidget);
        expect(find.text('Upbeat'), findsOneWidget);
        expect(find.text('Energizing'), findsOneWidget);

        // Charts section with tabs (Top Tracks, Underground, Top Artists, Popular Playlists)
        expect(find.text('Charts'), findsOneWidget);
        expect(find.text('Top Tracks'), findsOneWidget);
        expect(find.text('Underground'), findsOneWidget);
        expect(find.text('Top Artists'), findsOneWidget);
        expect(find.text('Popular Playlists'), findsOneWidget);

        // New releases section (standalone carousel)
        expect(find.text('New releases'), findsOneWidget);
      },
    );

    testWidgets('genre card selection toggles active genre filter', (
      tester,
    ) async {
      final stubTrackRepo = StubTrackRepository();

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(trackRepo: stubTrackRepo));
      await tester.pumpAndSettle();

      // Initially 'All' genres
      expect(stubTrackRepo.lastGenre, isNull);

      // Tap Electronic genre
      await tester.tap(find.text('Electronic'));
      await tester.pumpAndSettle();

      expect(stubTrackRepo.lastGenre, equals('Electronic'));

      // Tap Electronic again to deselect
      await tester.tap(find.text('Electronic'));
      await tester.pumpAndSettle();

      expect(stubTrackRepo.lastGenre, isNull);
    });

    testWidgets('switching charts tabs loads respective catalog data', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Initial tab: Top Tracks
      expect(find.byKey(const ValueKey('top_tracks_list')), findsOneWidget);

      // 2. Switch to Underground
      await tester.tap(find.text('Underground'));
      await tester.pumpAndSettle();
      expect(find.text('Underground Gem'), findsOneWidget);

      // 3. Switch to Top Artists
      await tester.ensureVisible(find.text('Top Artists'));
      await tester.tap(find.text('Top Artists'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('top_artists_list')), findsOneWidget);
      expect(find.text('Top Artist 0'), findsOneWidget);
    });

    testWidgets('renders empty state when chart data is empty', (tester) async {
      final emptyTrackRepo = _EmptyTrackRepo();

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(trackRepo: emptyTrackRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('top_tracks_empty')), findsOneWidget);
      expect(find.text('No Tracks'), findsOneWidget);
    });
  });
}

class _EmptyTrackRepo extends StubTrackRepository {
  @override
  Future<List<Track>> getTrendingTracks({
    int limit = 20,
    int offset = 0,
    String? genre,
    String time = 'week',
  }) async {
    return const [];
  }
}
