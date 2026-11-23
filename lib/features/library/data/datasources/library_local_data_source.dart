import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../shared/models/artwork.dart';
import '../../../albums/domain/entities/album.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../tracks/domain/entities/track.dart';

/// Local data source persisting the guest user's personal music collection
/// (liked tracks, saved albums, saved playlists, followed artists).
class LibraryLocalDataSource {
  const LibraryLocalDataSource({required this.prefsAsync});

  final Future<SharedPreferences> prefsAsync;

  static const String _likedTracksKey = 'audifi_liked_tracks_v1';
  static const String _savedAlbumsKey = 'audifi_saved_albums_v1';
  static const String _savedPlaylistsKey = 'audifi_saved_playlists_v1';
  static const String _followedArtistsKey = 'audifi_followed_artists_v1';

  // --- Liked Tracks ---

  Future<List<Track>> getLikedTracks() async {
    try {
      final prefs = await prefsAsync;
      final raw = prefs.getString(_likedTracksKey);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];

      final tracks = <Track>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] as String?;
          final title = item['title'] as String?;
          if (id == null || title == null) continue;

          final artworkUrl = item['artworkUrl'] as String?;
          final userId = item['userId'] as String?;
          final userName = item['userName'] as String?;
          final userHandle = item['userHandle'] as String?;
          final isVerified = item['isVerified'] as bool? ?? false;

          tracks.add(
            Track(
              id: id,
              title: title,
              duration: (item['duration'] as num?)?.toInt() ?? 0,
              genre: item['genre'] as String?,
              mood: item['mood'] as String?,
              playCount: (item['playCount'] as num?)?.toInt() ?? 0,
              artwork: artworkUrl != null
                  ? Artwork(
                      small: artworkUrl,
                      medium: artworkUrl,
                      large: artworkUrl,
                    )
                  : null,
              user: userId != null
                  ? User(
                      id: userId,
                      name: userName ?? 'Artist',
                      handle: userHandle ?? '',
                      isVerified: isVerified,
                    )
                  : null,
            ),
          );
        }
      }
      return tracks;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to read liked tracks from local storage',
        tag: 'LibraryLocalDataSource',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  Future<void> saveLikedTracks(List<Track> tracks) async {
    try {
      final prefs = await prefsAsync;
      final serialized = tracks.map((t) {
        return {
          'id': t.id,
          'title': t.title,
          'duration': t.duration,
          'genre': t.genre,
          'mood': t.mood,
          'playCount': t.playCount,
          'artworkUrl': t.artwork?.primaryUrl,
          'userId': t.user?.id,
          'userName': t.user?.name,
          'userHandle': t.user?.handle,
          'isVerified': t.user?.isVerified ?? false,
        };
      }).toList();

      await prefs.setString(_likedTracksKey, jsonEncode(serialized));
    } catch (e, st) {
      AppLogger.warning(
        'Failed to save liked tracks to local storage',
        tag: 'LibraryLocalDataSource',
        error: e,
        stackTrace: st,
      );
    }
  }

  // --- Saved Albums ---

  Future<List<Album>> getSavedAlbums() async {
    try {
      final prefs = await prefsAsync;
      final raw = prefs.getString(_savedAlbumsKey);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];

      final albums = <Album>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] as String?;
          final title = item['title'] as String?;
          if (id == null || title == null) continue;

          final artworkUrl = item['artworkUrl'] as String?;
          final userId = item['userId'] as String?;
          final userName = item['userName'] as String?;
          final userHandle = item['userHandle'] as String?;
          final isVerified = item['isVerified'] as bool? ?? false;

          albums.add(
            Album(
              id: id,
              title: title,
              trackCount: (item['trackCount'] as num?)?.toInt() ?? 0,
              description: item['description'] as String?,
              artwork: artworkUrl != null
                  ? Artwork(
                      small: artworkUrl,
                      medium: artworkUrl,
                      large: artworkUrl,
                    )
                  : null,
              user: userId != null
                  ? User(
                      id: userId,
                      name: userName ?? 'Artist',
                      handle: userHandle ?? '',
                      isVerified: isVerified,
                    )
                  : null,
            ),
          );
        }
      }
      return albums;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to read saved albums from local storage',
        tag: 'LibraryLocalDataSource',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  Future<void> saveSavedAlbums(List<Album> albums) async {
    try {
      final prefs = await prefsAsync;
      final serialized = albums.map((a) {
        return {
          'id': a.id,
          'title': a.title,
          'trackCount': a.trackCount,
          'description': a.description,
          'artworkUrl': a.artwork?.primaryUrl,
          'userId': a.user?.id,
          'userName': a.user?.name,
          'userHandle': a.user?.handle,
          'isVerified': a.user?.isVerified ?? false,
        };
      }).toList();

      await prefs.setString(_savedAlbumsKey, jsonEncode(serialized));
    } catch (e, st) {
      AppLogger.warning(
        'Failed to save albums to local storage',
        tag: 'LibraryLocalDataSource',
        error: e,
        stackTrace: st,
      );
    }
  }

  // --- Saved Playlists ---

  Future<List<Playlist>> getSavedPlaylists() async {
    try {
      final prefs = await prefsAsync;
      final raw = prefs.getString(_savedPlaylistsKey);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];

      final playlists = <Playlist>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] as String?;
          final name = item['name'] as String?;
          if (id == null || name == null) continue;

          final artworkUrl = item['artworkUrl'] as String?;
          final userId = item['userId'] as String?;
          final userName = item['userName'] as String?;
          final userHandle = item['userHandle'] as String?;
          final isVerified = item['isVerified'] as bool? ?? false;

          playlists.add(
            Playlist(
              id: id,
              playlistName: name,
              trackCount: (item['trackCount'] as num?)?.toInt() ?? 0,
              description: item['description'] as String?,
              artwork: artworkUrl != null
                  ? Artwork(
                      small: artworkUrl,
                      medium: artworkUrl,
                      large: artworkUrl,
                    )
                  : null,
              user: userId != null
                  ? User(
                      id: userId,
                      name: userName ?? 'Curator',
                      handle: userHandle ?? '',
                      isVerified: isVerified,
                    )
                  : null,
            ),
          );
        }
      }
      return playlists;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to read saved playlists from local storage',
        tag: 'LibraryLocalDataSource',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  Future<void> saveSavedPlaylists(List<Playlist> playlists) async {
    try {
      final prefs = await prefsAsync;
      final serialized = playlists.map((p) {
        return {
          'id': p.id,
          'name': p.playlistName,
          'trackCount': p.trackCount,
          'description': p.description,
          'artworkUrl': p.artwork?.primaryUrl,
          'userId': p.user?.id,
          'userName': p.user?.name,
          'userHandle': p.user?.handle,
          'isVerified': p.user?.isVerified ?? false,
        };
      }).toList();

      await prefs.setString(_savedPlaylistsKey, jsonEncode(serialized));
    } catch (e, st) {
      AppLogger.warning(
        'Failed to save playlists to local storage',
        tag: 'LibraryLocalDataSource',
        error: e,
        stackTrace: st,
      );
    }
  }

  // --- Followed Artists ---

  Future<List<User>> getFollowedArtists() async {
    try {
      final prefs = await prefsAsync;
      final raw = prefs.getString(_followedArtistsKey);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];

      final artists = <User>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] as String?;
          final name = item['name'] as String?;
          if (id == null || name == null) continue;

          final profileUrl = item['profileUrl'] as String?;

          artists.add(
            User(
              id: id,
              name: name,
              handle: (item['handle'] as String?) ?? '',
              bio: item['bio'] as String?,
              followerCount: (item['followerCount'] as num?)?.toInt() ?? 0,
              trackCount: (item['trackCount'] as num?)?.toInt() ?? 0,
              isVerified: (item['isVerified'] as bool?) ?? false,
              profilePicture: profileUrl != null
                  ? Artwork(
                      small: profileUrl,
                      medium: profileUrl,
                      large: profileUrl,
                    )
                  : null,
            ),
          );
        }
      }
      return artists;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to read followed artists from local storage',
        tag: 'LibraryLocalDataSource',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  Future<void> saveFollowedArtists(List<User> artists) async {
    try {
      final prefs = await prefsAsync;
      final serialized = artists.map((u) {
        return {
          'id': u.id,
          'name': u.name,
          'handle': u.handle,
          'bio': u.bio,
          'followerCount': u.followerCount,
          'trackCount': u.trackCount,
          'isVerified': u.isVerified,
          'profileUrl': u.profilePicture?.primaryUrl,
        };
      }).toList();

      await prefs.setString(_followedArtistsKey, jsonEncode(serialized));
    } catch (e, st) {
      AppLogger.warning(
        'Failed to save followed artists to local storage',
        tag: 'LibraryLocalDataSource',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await prefsAsync;
      await Future.wait([
        prefs.remove(_likedTracksKey),
        prefs.remove(_savedAlbumsKey),
        prefs.remove(_savedPlaylistsKey),
        prefs.remove(_followedArtistsKey),
      ]);
    } catch (e) {
      AppLogger.warning('Failed to clear library storage', error: e);
    }
  }
}

/// Provider for [LibraryLocalDataSource].
final libraryLocalDataSourceProvider = Provider<LibraryLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesAsyncProvider);
  return LibraryLocalDataSource(prefsAsync: prefsAsync);
});
