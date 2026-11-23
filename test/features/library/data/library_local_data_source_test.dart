import 'dart:convert';

import 'package:audifi/features/albums/domain/entities/album.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/library/data/datasources/library_local_data_source.dart';
import 'package:audifi/features/playlists/domain/entities/playlist.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/models/artwork.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryLocalDataSource', () {
    late LibraryLocalDataSource dataSource;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dataSource = LibraryLocalDataSource(
        prefsAsync: SharedPreferences.getInstance(),
      );
    });

    test('persists and restores liked tracks safely', () async {
      const track = Track(
        id: 'track_1',
        title: 'Song 1',
        duration: 180,
        artwork: Artwork(
          small: 'https://cdn.example.com/art_small.jpg',
          medium: 'https://cdn.example.com/art_med.jpg',
          large: 'https://cdn.example.com/art_large.jpg',
        ),
        user: User(id: 'artist_1', name: 'Cool Artist', handle: 'cool_artist'),
      );

      await dataSource.saveLikedTracks([track]);
      final restored = await dataSource.getLikedTracks();

      expect(restored.length, equals(1));
      expect(restored.first.id, equals('track_1'));
      expect(restored.first.title, equals('Song 1'));
      expect(restored.first.user?.name, equals('Cool Artist'));
    });

    test('persists and restores saved albums safely', () async {
      const album = Album(
        id: 'album_1',
        title: 'Album 1',
        trackCount: 8,
        description: 'First Album',
        user: User(id: 'artist_1', name: 'Cool Artist', handle: 'cool_artist'),
      );

      await dataSource.saveSavedAlbums([album]);
      final restored = await dataSource.getSavedAlbums();

      expect(restored.length, equals(1));
      expect(restored.first.id, equals('album_1'));
      expect(restored.first.title, equals('Album 1'));
      expect(restored.first.trackCount, equals(8));
    });

    test('persists and restores saved playlists safely', () async {
      const playlist = Playlist(
        id: 'playlist_1',
        playlistName: 'Workout Mix',
        trackCount: 15,
        user: User(id: 'curator_1', name: 'Curator X', handle: 'curator_x'),
      );

      await dataSource.saveSavedPlaylists([playlist]);
      final restored = await dataSource.getSavedPlaylists();

      expect(restored.length, equals(1));
      expect(restored.first.id, equals('playlist_1'));
      expect(restored.first.playlistName, equals('Workout Mix'));
      expect(restored.first.trackCount, equals(15));
    });

    test('persists and restores followed artists safely', () async {
      const artist = User(
        id: 'user_1',
        name: 'Top Producer',
        handle: 'producer1',
        followerCount: 50000,
        trackCount: 30,
        isVerified: true,
      );

      await dataSource.saveFollowedArtists([artist]);
      final restored = await dataSource.getFollowedArtists();

      expect(restored.length, equals(1));
      expect(restored.first.id, equals('user_1'));
      expect(restored.first.name, equals('Top Producer'));
      expect(restored.first.isVerified, isTrue);
    });

    test(
      'corrupt or invalid JSON returns empty list without throwing',
      () async {
        SharedPreferences.setMockInitialValues({
          'audifi_liked_tracks_v1': 'invalid_json{',
          'audifi_saved_albums_v1': jsonEncode([
            {'missing_id': 'no'},
          ]),
        });

        final tracks = await dataSource.getLikedTracks();
        final albums = await dataSource.getSavedAlbums();

        expect(tracks, isEmpty);
        expect(albums, isEmpty);
      },
    );

    test('clearAll removes all library collections from storage', () async {
      const track = Track(id: 't1', title: 'T1', duration: 100);
      await dataSource.saveLikedTracks([track]);

      expect((await dataSource.getLikedTracks()).length, equals(1));
      await dataSource.clearAll();
      expect(await dataSource.getLikedTracks(), isEmpty);
    });
  });
}
