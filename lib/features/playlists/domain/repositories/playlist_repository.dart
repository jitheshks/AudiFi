import '../../../../core/constants/api_constants.dart';
import '../../../albums/domain/entities/album.dart';
import '../../../tracks/domain/entities/track.dart';
import '../entities/playlist.dart';

/// Pure domain repository contract abstracting playlist operations.
abstract interface class PlaylistRepository {
  /// Retrieves trending curated playlists for a given time window.
  Future<List<Playlist>> getTrendingPlaylists({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    String time = ApiConstants.defaultTimeRange,
  });

  /// Retrieves newly released curated playlists from `/playlists/new-releases`.
  Future<List<Playlist>> getNewReleasesPlaylists({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  });

  /// Retrieves newly released commercial albums from `/playlists/new-releases?type=album`.
  Future<List<Album>> getNewReleaseAlbums({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  });

  /// Retrieves playlist metadata by unique ID.
  Future<Playlist?> getPlaylist(String playlistId);

  /// Retrieves track listing for a given playlist.
  Future<List<Track>> getPlaylistTracks(String playlistId);
}
