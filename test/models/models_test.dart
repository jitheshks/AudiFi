import 'package:audifi/features/albums/data/models/album_model.dart';
import 'package:audifi/features/artists/data/models/user_model.dart';
import 'package:audifi/features/playlists/data/models/playlist_model.dart';
import 'package:audifi/features/search/data/models/search_result_model.dart';
import 'package:audifi/features/tracks/data/models/track_model.dart';
import 'package:audifi/shared/models/artwork.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Artwork Model', () {
    test('deserializes valid JSON with all resolutions', () {
      final json = {
        '150x150': 'https://audius.co/art/small.jpg',
        '480x480': 'https://audius.co/art/medium.jpg',
        '1000x1000': 'https://audius.co/art/large.jpg',
        'mirrors': ['https://node1.audius.co', 'https://node2.audius.co'],
      };

      final artwork = Artwork.fromJson(json);
      expect(artwork.small, 'https://audius.co/art/small.jpg');
      expect(artwork.medium, 'https://audius.co/art/medium.jpg');
      expect(artwork.large, 'https://audius.co/art/large.jpg');
      expect(artwork.primaryUrl, 'https://audius.co/art/medium.jpg');
      expect(artwork.thumbnailUrl, 'https://audius.co/art/small.jpg');
      expect(artwork.mirrors.length, 2);

      final outJson = artwork.toJson();
      expect(outJson['150x150'], 'https://audius.co/art/small.jpg');
      expect(outJson['480x480'], 'https://audius.co/art/medium.jpg');
    });

    test('handles missing or null resolutions safely', () {
      final artwork = Artwork.fromJson({});
      expect(artwork.small, isNull);
      expect(artwork.medium, isNull);
      expect(artwork.large, isNull);
      expect(artwork.primaryUrl, isNull);
      expect(artwork.thumbnailUrl, isNull);
      expect(artwork.mirrors, isEmpty);
    });
  });

  group('User Model', () {
    test('deserializes full user profile and serializes back', () {
      final json = {
        'id': 'user_123',
        'name': 'Deadmau5',
        'handle': 'deadmau5',
        'bio': 'Electronic music producer and DJ.',
        'location': 'Toronto, ON',
        'is_verified': true,
        'follower_count': 1250000,
        'followee_count': 42,
        'track_count': 18,
        'playlist_count': 5,
        'album_count': 2,
        'profile_picture': {
          '150x150': 'https://audius.co/avatar_150.jpg',
          '480x480': 'https://audius.co/avatar_480.jpg',
        },
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user_123');
      expect(user.name, 'Deadmau5');
      expect(user.handle, 'deadmau5');
      expect(user.bio, 'Electronic music producer and DJ.');
      expect(user.isVerified, isTrue);
      expect(user.formattedFollowers, '1.3M');
      expect(
        user.profilePicture?.primaryUrl,
        'https://audius.co/avatar_480.jpg',
      );

      final outJson = user.toJson();
      expect(outJson['id'], 'user_123');
      expect(outJson['handle'], 'deadmau5');
      expect(outJson['follower_count'], 1250000);
    });

    test('handles minimal / missing user fields safely', () {
      final user = UserModel.fromJson({'id': 999, 'handle': 'new_artist'});
      expect(user.id, '999');
      expect(user.name, 'new_artist');
      expect(user.handle, 'new_artist');
      expect(user.bio, isNull);
      expect(user.isVerified, isFalse);
      expect(user.followerCount, 0);
      expect(user.formattedFollowers, '0');
    });
  });

  group('Track Model', () {
    test('deserializes complete track object', () {
      final json = {
        'id': 'track_456',
        'title': 'Strobe',
        'description': 'Classic progressive house track.',
        'genre': 'Electronic',
        'mood': 'Euphoric',
        'release_date': '2010-02-23',
        'duration': 637,
        'play_count': 452000,
        'favorite_count': 32000,
        'repost_count': 5200,
        'comment_count': 840,
        'artwork': {
          '150x150': 'https://audius.co/art_150.jpg',
          '480x480': 'https://audius.co/art_480.jpg',
        },
        'user': {
          'id': 'user_123',
          'name': 'Deadmau5',
          'handle': 'deadmau5',
          'is_verified': true,
        },
        'permalink': '/deadmau5/strobe',
        'is_streamable': true,
      };

      final track = TrackModel.fromJson(json);
      expect(track.id, 'track_456');
      expect(track.title, 'Strobe');
      expect(track.genre, 'Electronic');
      expect(track.formattedDuration, '10:37');
      expect(track.formattedPlays, '452.0K');
      expect(track.user?.name, 'Deadmau5');
      expect(track.artwork?.primaryUrl, 'https://audius.co/art_480.jpg');

      final outJson = track.toJson();
      expect(outJson['title'], 'Strobe');
      expect(outJson['duration'], 637);
      expect(outJson['is_streamable'], isTrue);
    });

    test('handles minimal / unexpected track fields gracefully', () {
      final track = TrackModel.fromJson({'id': 'empty_t'});
      expect(track.id, 'empty_t');
      expect(track.title, 'Untitled Track');
      expect(track.duration, 0);
      expect(track.formattedDuration, '0:00');
      expect(track.user, isNull);
      expect(track.artwork, isNull);
    });
  });

  group('Playlist & Album Models', () {
    test('deserializes playlist entity', () {
      final json = {
        'id': 'pl_789',
        'playlist_name': 'Best of Electronic',
        'description': 'Curated progressive tunes.',
        'is_album': false,
        'track_count': 12,
        'total_play_count': 89000,
        'user': {'id': 'user_u1', 'name': 'Curator Club', 'handle': 'curator'},
      };

      final playlist = PlaylistModel.fromJson(json);
      expect(playlist.id, 'pl_789');
      expect(playlist.playlistName, 'Best of Electronic');
      expect(playlist.isAlbum, isFalse);
      expect(playlist.trackCount, 12);
      expect(playlist.user?.name, 'Curator Club');
    });

    test('deserializes and handles Album representation', () {
      final json = {
        'id': 'alb_101',
        'playlist_name': 'Random Album Title',
        'is_album': true,
        'track_count': 10,
        'release_date': '2024-01-01',
        'user': {'id': 'user_123', 'name': 'Deadmau5', 'handle': 'deadmau5'},
      };

      final album = AlbumModel.fromJson(json);
      expect(album.id, 'alb_101');
      expect(album.title, 'Random Album Title');
      expect(album.artist?.name, 'Deadmau5');
      expect(album.trackCount, 10);

      final playlist = album.toPlaylist();
      expect(playlist.isAlbum, isTrue);
      expect(playlist.id, 'alb_101');
    });
  });

  group('SearchResult Model', () {
    test('deserializes aggregated search results', () {
      final json = {
        'tracks': [
          {'id': 't1', 'title': 'Track One'},
        ],
        'users': [
          {'id': 'u1', 'name': 'Artist One', 'handle': 'art1'},
        ],
        'playlists': [
          {'id': 'p1', 'playlist_name': 'Playlist One', 'is_album': false},
        ],
        'albums': [
          {'id': 'a1', 'playlist_name': 'Album One', 'is_album': true},
        ],
      };

      final result = SearchResultModel.fromJson(json);
      expect(result.tracks.length, 1);
      expect(result.users.length, 1);
      expect(result.playlists.length, 1);
      expect(result.albums.length, 1);
      expect(result.isNotEmpty, isTrue);
      expect(result.isEmpty, isFalse);
    });

    test('handles empty search results correctly', () {
      final emptyResult = SearchResultModel.fromJson({});
      expect(emptyResult.isEmpty, isTrue);
      expect(emptyResult.isNotEmpty, isFalse);
    });
  });
}
