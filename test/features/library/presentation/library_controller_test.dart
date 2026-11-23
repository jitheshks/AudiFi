import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/features/albums/domain/entities/album.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/library/data/repositories/library_repository_impl.dart';
import 'package:audifi/features/library/presentation/controllers/library_controller.dart';
import 'package:audifi/features/playlists/domain/entities/playlist.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  group('LibraryController', () {
    late ProviderContainer container;
    late StubLibraryRepository stubRepo;

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

    setUp(() {
      stubRepo = StubLibraryRepository();
      container = ProviderContainer(
        overrides: [libraryRepositoryProvider.overrideWithValue(stubRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state loads empty library and updates from repo', () async {
      final initial = container.read(libraryControllerProvider);
      expect(initial.likedTracks, isEmpty);
      expect(initial.savedAlbums, isEmpty);
      expect(initial.savedPlaylists, isEmpty);
      expect(initial.followedArtists, isEmpty);
    });

    test('toggleLikeTrack optimistically adds and removes track', () async {
      final controller = container.read(libraryControllerProvider.notifier);

      await controller.toggleLikeTrack(testTrack);
      var state = container.read(libraryControllerProvider);
      expect(state.isTrackLiked(testTrack.id), isTrue);
      expect(state.likedTracks.first.title, 'Neon Nights');

      await controller.toggleLikeTrack(testTrack);
      state = container.read(libraryControllerProvider);
      expect(state.isTrackLiked(testTrack.id), isFalse);
      expect(state.likedTracks, isEmpty);
    });

    test('toggleSaveAlbum optimistically adds and removes album', () async {
      final controller = container.read(libraryControllerProvider.notifier);

      await controller.toggleSaveAlbum(testAlbum);
      var state = container.read(libraryControllerProvider);
      expect(state.isAlbumSaved(testAlbum.id), isTrue);
      expect(state.savedAlbums.first.albumName, 'Neon Odyssey');

      await controller.toggleSaveAlbum(testAlbum);
      state = container.read(libraryControllerProvider);
      expect(state.isAlbumSaved(testAlbum.id), isFalse);
      expect(state.savedAlbums, isEmpty);
    });

    test(
      'toggleSavePlaylist optimistically adds and removes playlist',
      () async {
        final controller = container.read(libraryControllerProvider.notifier);

        await controller.toggleSavePlaylist(testPlaylist);
        var state = container.read(libraryControllerProvider);
        expect(state.isPlaylistSaved(testPlaylist.id), isTrue);
        expect(state.savedPlaylists.first.playlistName, 'Chillwave Vibes');

        await controller.toggleSavePlaylist(testPlaylist);
        state = container.read(libraryControllerProvider);
        expect(state.isPlaylistSaved(testPlaylist.id), isFalse);
        expect(state.savedPlaylists, isEmpty);
      },
    );

    test('toggleFollowArtist optimistically adds and removes artist', () async {
      final controller = container.read(libraryControllerProvider.notifier);

      await controller.toggleFollowArtist(testArtist);
      var state = container.read(libraryControllerProvider);
      expect(state.isArtistFollowed(testArtist.id), isTrue);
      expect(state.followedArtists.first.name, 'Synth Artist');

      await controller.toggleFollowArtist(testArtist);
      state = container.read(libraryControllerProvider);
      expect(state.isArtistFollowed(testArtist.id), isFalse);
      expect(state.followedArtists, isEmpty);
    });

    test('remove individual items removes only target item', () async {
      final controller = container.read(libraryControllerProvider.notifier);

      await controller.toggleLikeTrack(testTrack);
      await controller.toggleSaveAlbum(testAlbum);
      await controller.toggleSavePlaylist(testPlaylist);
      await controller.toggleFollowArtist(testArtist);

      await controller.removeLikedTrack(testTrack.id);
      expect(
        container.read(libraryControllerProvider).isTrackLiked(testTrack.id),
        isFalse,
      );

      await controller.removeSavedAlbum(testAlbum.id);
      expect(
        container.read(libraryControllerProvider).isAlbumSaved(testAlbum.id),
        isFalse,
      );

      await controller.removeSavedPlaylist(testPlaylist.id);
      expect(
        container
            .read(libraryControllerProvider)
            .isPlaylistSaved(testPlaylist.id),
        isFalse,
      );

      await controller.unfollowArtist(testArtist.id);
      expect(
        container
            .read(libraryControllerProvider)
            .isArtistFollowed(testArtist.id),
        isFalse,
      );
    });

    test('clearLibrary resets all collections to empty', () async {
      final controller = container.read(libraryControllerProvider.notifier);

      await controller.toggleLikeTrack(testTrack);
      await controller.toggleSaveAlbum(testAlbum);
      await controller.toggleSavePlaylist(testPlaylist);
      await controller.toggleFollowArtist(testArtist);

      var state = container.read(libraryControllerProvider);
      expect(state.likedTracks, isNotEmpty);
      expect(state.savedAlbums, isNotEmpty);

      await controller.clearLibrary();

      state = container.read(libraryControllerProvider);
      expect(state.likedTracks, isEmpty);
      expect(state.savedAlbums, isEmpty);
      expect(state.savedPlaylists, isEmpty);
      expect(state.followedArtists, isEmpty);
    });
  });
}
