import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:audifi/features/albums/domain/entities/album.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/library/domain/entities/user_library.dart';
import 'package:audifi/features/library/presentation/views/library_view.dart';
import 'package:audifi/features/playlists/domain/entities/playlist.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  group('LibraryView', () {
    const testTrack = Track(
      id: 'track_1',
      title: 'Neon Nights',
      duration: 210,
      user: User(id: 'artist_1', name: 'Synth Artist', handle: 'synthart'),
    );

    const testAlbum = Album(
      id: 'album_1',
      albumName: 'Neon Odyssey',
      user: User(id: 'artist_1', name: 'Synth Artist', handle: 'synthart'),
    );

    const testPlaylist = Playlist(
      id: 'playlist_1',
      playlistName: 'Chillwave Vibes',
      user: User(id: 'curator_1', name: 'Chill Curator', handle: 'curator1'),
    );

    const testArtist = User(
      id: 'artist_1',
      name: 'Synth Artist',
      handle: 'synthart',
      followerCount: 5000,
    );

    Widget createTestWidget({
      StubLibraryRepository? stubRepo,
      LibraryCategory? initialTab,
    }) {
      final repo = stubRepo ?? StubLibraryRepository();
      return ProviderScope(
        overrides: [...createStubRepositoryOverrides(libraryRepo: repo)],
        child: MaterialApp(home: LibraryView(initialTab: initialTab)),
      );
    }

    testWidgets('renders all library category filter chips', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Liked'), findsWidgets);
      expect(find.text('Playlists'), findsWidgets);
      expect(find.text('Downloads'), findsWidgets);
      expect(find.text('Local Files'), findsWidgets);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('renders default empty state on Liked category', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(initialTab: LibraryCategory.liked),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Your favorite tracks will appear here.'),
        findsOneWidget,
      );
      expect(find.text('Discover music'), findsOneWidget);
    });

    testWidgets('switching chips shows respective empty states', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Artists chip
      await tester.ensureVisible(
        find.byKey(const ValueKey('library_chip_artists')),
      );
      await tester.tap(find.byKey(const ValueKey('library_chip_artists')));
      await tester.pumpAndSettle();
      expect(find.text('No followed artists yet.'), findsOneWidget);

      // Tap Playlists chip
      await tester.ensureVisible(
        find.byKey(const ValueKey('library_chip_playlists')),
      );
      await tester.tap(find.byKey(const ValueKey('library_chip_playlists')));
      await tester.pumpAndSettle();
      expect(find.text('No playlists yet.'), findsOneWidget);

      // Tap History chip
      await tester.ensureVisible(
        find.byKey(const ValueKey('library_chip_history')),
      );
      await tester.tap(find.byKey(const ValueKey('library_chip_history')));
      await tester.pumpAndSettle();
      expect(find.text('Listening history is empty.'), findsOneWidget);

      // Tap Downloads chip
      await tester.ensureVisible(
        find.byKey(const ValueKey('library_chip_downloaded')),
      );
      await tester.tap(find.byKey(const ValueKey('library_chip_downloaded')));
      await tester.pumpAndSettle();
      expect(find.text('No downloaded tracks.'), findsOneWidget);

      // Tap Local Files chip
      await tester.ensureVisible(
        find.byKey(const ValueKey('library_chip_localFiles')),
      );
      await tester.tap(find.byKey(const ValueKey('library_chip_localFiles')));
      await tester.pumpAndSettle();
      expect(find.text('No local files imported yet.'), findsOneWidget);
      expect(find.text('Import Audio'), findsOneWidget);
    });

    testWidgets('renders content when library contains items', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final stubRepo = StubLibraryRepository()
        ..libraryState = const UserLibrary(
          likedTracks: [testTrack],
          savedAlbums: [testAlbum],
          savedPlaylists: [testPlaylist],
          followedArtists: [testArtist],
        );

      await tester.pumpWidget(
        createTestWidget(stubRepo: stubRepo, initialTab: LibraryCategory.liked),
      );
      await tester.pumpAndSettle();

      // In Liked tab
      expect(find.text('Neon Nights'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);

      // Switch to Artists
      await tester.ensureVisible(
        find.byKey(const ValueKey('library_chip_artists')),
      );
      await tester.tap(find.byKey(const ValueKey('library_chip_artists')));
      await tester.pumpAndSettle();
      expect(find.text('Synth Artist'), findsOneWidget);

      // Switch to Playlists
      await tester.ensureVisible(
        find.byKey(const ValueKey('library_chip_playlists')),
      );
      await tester.tap(find.byKey(const ValueKey('library_chip_playlists')));
      await tester.pumpAndSettle();
      expect(find.text('Chillwave Vibes'), findsOneWidget);
    });
  });
}
