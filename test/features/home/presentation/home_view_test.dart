import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/home/presentation/controllers/trending_tracks_controller.dart';
import 'package:audifi/features/home/presentation/views/home_view.dart';
import 'package:audifi/features/library/domain/entities/user_library.dart';
import 'package:audifi/features/library/presentation/controllers/listening_history_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  group('HomeView — Personalized Listening & Zero Catalog Duplication', () {
    const testTrack1 = Track(
      id: 't_recent_1',
      title: 'Neon Skyline',
      duration: 200,
      user: User(id: 'u1', name: 'Synth Master', handle: 'synthmaster'),
    );

    const testTrack2 = Track(
      id: 't_recent_2',
      title: 'Cyber Drive',
      duration: 240,
      user: User(id: 'u2', name: 'Future Wave', handle: 'futurewave'),
    );

    Widget createTestWidget({
      Map<String, Object>? initialPreferences,
      List<Track> history = const [],
      List<Track> likedTracks = const [],
      StubTrackRepository? trackRepo,
      StubLibraryRepository? libraryRepo,
    }) {
      final stubTrack = trackRepo ?? StubTrackRepository();
      final stubLib = libraryRepo ?? StubLibraryRepository();
      if (likedTracks.isNotEmpty) {
        stubLib.libraryState = UserLibrary(likedTracks: likedTracks);
      }

      return ProviderScope(
        overrides: [
          ...createStubRepositoryOverrides(
            initialPreferences: initialPreferences,
            trackRepo: stubTrack,
            libraryRepo: stubLib,
          ),
        ],
        child: const MaterialApp(home: HomeView()),
      );
    }

    testWidgets(
      'renders empty personalized dashboard for fresh user without catalog feeds',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Fresh user sees "Explore Discover" hero button
        expect(find.text('Explore Discover'), findsOneWidget);

        // Welcoming personal dashboard card
        expect(find.text('Your Personal Music Dashboard'), findsOneWidget);

        // Quick access collection shortcuts
        expect(find.text('Liked'), findsOneWidget);
        expect(find.text('Offline'), findsOneWidget);
        expect(find.text('Device'), findsOneWidget);

        // Verifies duplicate catalog feeds have been eliminated from Home
        expect(find.text('Popular artists'), findsNothing);
        expect(find.text('Trending playlists'), findsNothing);
        expect(find.text('Trending on Audius'), findsNothing);
        expect(find.text('New & notable'), findsNothing);
      },
    );

    testWidgets(
      'renders personalized listening state when user has history and likes',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestWidget(
            history: [testTrack1],
            likedTracks: [testTrack1, testTrack2],
          ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeView)),
        );
        await container
            .read(listeningHistoryProvider.notifier)
            .addTrack(testTrack1);
        await container
            .read(listeningHistoryProvider.notifier)
            .addTrack(testTrack1);
        await tester.pumpAndSettle();

        // Hero button adapts to "Resume listening"
        expect(find.text('Resume listening'), findsOneWidget);

        // Shows Recently Played
        expect(find.text('Recently Played'), findsOneWidget);
        expect(find.text('Neon Skyline'), findsWidgets);

        // Shows Frequently Played because play count > 1
        expect(find.text('Frequently Played'), findsOneWidget);

        // Collection shortcuts reflect item counts
        expect(find.text('Liked'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets(
      'TrendingTracksController SWR: preserves cached tracks when offline',
      (tester) async {
        final initialPrefs = {
          'audifi_home_trending_cache_v1': '[{"id":"cached_1","title":"Cached Hit","duration":180,"user":{"id":"u_c","name":"Cached Artist","handle":"cart"}}]',
        };

        final container = ProviderContainer(
          overrides: [
            ...createStubRepositoryOverrides(
              initialPreferences: initialPrefs,
              trackRepo: _FailingTrackRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Read trending controller
        final tracks = await container.read(
          trendingTracksControllerProvider.future,
        );

        // Cached content is preserved rather than throwing error
        expect(tracks.length, equals(1));
        expect(tracks.first.title, equals('Cached Hit'));
      },
    );
  });
}

class _FailingTrackRepository extends StubTrackRepository {
  @override
  Future<List<Track>> getTrendingTracks({
    int limit = 20,
    int offset = 0,
    String? genre,
    String time = 'week',
  }) async {
    throw Exception('Network unreachable (offline)');
  }
}
