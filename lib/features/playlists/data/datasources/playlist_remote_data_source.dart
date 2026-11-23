import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../albums/data/models/album_model.dart';
import '../../../tracks/data/models/track_model.dart';
import '../models/playlist_model.dart';

/// Remote data source interfacing with Audius playlist and album endpoints.
class PlaylistRemoteDataSource {
  const PlaylistRemoteDataSource({required this.client});

  final DioClient client;

  /// Fetches trending playlists from `/playlists/trending`.
  Future<List<PlaylistModel>> getTrendingPlaylists({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    String time = ApiConstants.defaultTimeRange,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
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

  /// Fetches new releases from `/playlists/new-releases` with `type` filter.
  Future<List<PlaylistModel>> getNewReleasesPlaylists({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    String type = 'playlist',
  }) async {
    final response = await client.get<Map<String, dynamic>>(
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

  /// Fetches newly released albums via `/playlists/new-releases?type=album`.
  Future<List<AlbumModel>> getNewReleaseAlbums({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  }) async {
    final playlists = await getNewReleasesPlaylists(
      limit: limit,
      offset: offset,
      type: 'album',
    );
    return playlists.map((p) => AlbumModel.fromJson(p.toJson())).toList();
  }

  /// Fetches playlist details by ID from `/playlists/{playlist_id}`.
  Future<PlaylistModel?> getPlaylist(String playlistId) async {
    final response = await client.get<Map<String, dynamic>>(
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

  /// Fetches track listing for a playlist from `/playlists/{playlist_id}/tracks`.
  Future<List<TrackModel>> getPlaylistTracks(String playlistId) async {
    final response = await client.get<Map<String, dynamic>>(
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

/// Riverpod provider for [PlaylistRemoteDataSource].
final playlistRemoteDataSourceProvider = Provider<PlaylistRemoteDataSource>((
  ref,
) {
  final client = ref.watch(dioClientProvider);
  return PlaylistRemoteDataSource(client: client);
});
