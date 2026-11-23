import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../../core/api/api_endpoints.dart';
import '../../features/albums/domain/entities/album.dart';
import '../../features/artists/data/models/user_model.dart';
import '../../features/artists/domain/entities/user.dart';
import '../../features/playlists/data/models/playlist_model.dart';
import '../../features/playlists/domain/entities/playlist.dart';
import '../../features/search/data/models/search_result_model.dart';
import '../../features/search/domain/entities/search_result.dart';
import '../../features/tracks/data/models/track_model.dart';
import '../../features/tracks/domain/entities/track.dart';

/// Remote data source communicating directly with Audius API endpoints via [ApiClient].
class AudiusRemoteDataSource {
  const AudiusRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// Retrieves trending tracks from `/tracks/trending`.
  Future<List<Track>> getTrendingTracks({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    String? genre,
    String time = ApiConstants.defaultTimeRange,
  }) async {
    final queryParams = <String, dynamic>{
      ApiConstants.paramLimit: limit,
      ApiConstants.paramOffset: offset,
      ApiConstants.paramTime: time,
    };
    if (genre != null && genre.isNotEmpty) {
      queryParams[ApiConstants.paramGenre] = genre;
    }

    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.trendingTracks,
      queryParameters: queryParams,
    );

    final rawData = response.data?['data'];
    if (rawData is List<dynamic>) {
      return rawData
          .map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Retrieves the latest published tracks from `/tracks/latest`.
  Future<List<Track>> getLatestTracks({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.latestTracks,
      queryParameters: {
        ApiConstants.paramLimit: limit,
        ApiConstants.paramOffset: offset,
      },
    );

    final rawData = response.data?['data'];
    if (rawData is List<dynamic>) {
      return rawData
          .map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Retrieves trending playlists from `/playlists/trending`.
  Future<List<Playlist>> getTrendingPlaylists({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    String time = ApiConstants.defaultTimeRange,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.trendingPlaylists,
      queryParameters: {
        ApiConstants.paramLimit: limit,
        ApiConstants.paramOffset: offset,
        ApiConstants.paramTime: time,
      },
    );

    final rawData = response.data?['data'];
    if (rawData is List<dynamic>) {
      return rawData
          .map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Retrieves new release playlists or albums from `/playlists/new-releases`.
  Future<List<Playlist>> getNewReleasesPlaylists({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    String type = 'playlist',
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.newReleasesPlaylists,
      queryParameters: {
        ApiConstants.paramLimit: limit,
        ApiConstants.paramOffset: offset,
        ApiConstants.paramType: type,
      },
    );

    final rawData = response.data?['data'];
    if (rawData is List<dynamic>) {
      return rawData
          .map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Retrieves new release albums specifically via `/playlists/new-releases?type=album`.
  Future<List<Album>> getNewReleaseAlbums({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  }) async {
    final playlists = await getNewReleasesPlaylists(
      limit: limit,
      offset: offset,
      type: 'album',
    );
    return playlists.map(Album.fromPlaylist).toList();
  }

  /// Executes full-catalog search across tracks, users, playlists, and albums
  /// via `/search/full`.
  Future<SearchResult> searchFull(
    String query, {
    String? kind,
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    bool? includePurchaseable,
  }) async {
    final queryParams = <String, dynamic>{
      ApiConstants.paramQuery: query,
      ApiConstants.paramLimit: limit,
      ApiConstants.paramOffset: offset,
    };
    if (kind != null && kind.isNotEmpty) {
      queryParams[ApiConstants.paramKind] = kind;
    }
    if (includePurchaseable != null) {
      queryParams[ApiConstants.paramIncludePurchaseable] = includePurchaseable;
    }

    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.searchFull,
      queryParameters: queryParams,
    );

    final rawData = response.data?['data'];
    if (rawData is Map<String, dynamic>) {
      return SearchResultModel.fromJson(rawData);
    }
    return const SearchResult();
  }

  /// Retrieves artist/user details by user ID from `/users/{id}`.
  Future<User?> getUser(String userId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.userDetails(userId),
    );

    final rawData = response.data?['data'];
    if (rawData is Map<String, dynamic>) {
      return UserModel.fromJson(rawData);
    } else if (rawData is List<dynamic> && rawData.isNotEmpty) {
      return UserModel.fromJson(rawData.first as Map<String, dynamic>);
    }
    return null;
  }

  /// Retrieves artist/user tracks by user ID from `/users/{id}/tracks`.
  Future<List<Track>> getUserTracks(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.userTracks(userId),
      queryParameters: {
        ApiConstants.paramLimit: limit,
        ApiConstants.paramOffset: offset,
      },
    );

    final rawData = response.data?['data'];
    if (rawData is List<dynamic>) {
      return rawData
          .map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  /// Retrieves playlist details by playlist ID from `/playlists/{playlist_id}`.
  Future<Playlist?> getPlaylist(String playlistId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.playlistDetails(playlistId),
    );

    final rawData = response.data?['data'];
    if (rawData is List<dynamic> && rawData.isNotEmpty) {
      return PlaylistModel.fromJson(rawData.first as Map<String, dynamic>);
    } else if (rawData is Map<String, dynamic>) {
      return PlaylistModel.fromJson(rawData);
    }
    return null;
  }

  /// Retrieves track listings for a playlist from `/playlists/{playlist_id}/tracks`.
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.playlistTracks(playlistId),
    );

    final rawData = response.data?['data'];
    if (rawData is List<dynamic>) {
      return rawData
          .map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }
}

/// Riverpod provider for the [AudiusRemoteDataSource].
final audiusRemoteDataSourceProvider = Provider<AudiusRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AudiusRemoteDataSource(apiClient: apiClient);
});
