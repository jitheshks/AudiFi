import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../albums/domain/entities/album.dart';
import '../../../tracks/domain/entities/track.dart';
import '../datasources/playlist_remote_data_source.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';

/// Implementation of [PlaylistRepository] coordinating the [PlaylistRemoteDataSource].
class PlaylistRepositoryImpl implements PlaylistRepository {
  const PlaylistRepositoryImpl({required this.remoteDataSource});

  final PlaylistRemoteDataSource remoteDataSource;

  @override
  Future<List<Playlist>> getTrendingPlaylists({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    String time = ApiConstants.defaultTimeRange,
  }) async {
    try {
      return await remoteDataSource.getTrendingPlaylists(
        limit: limit,
        offset: offset,
        time: time,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to get trending playlists',
        tag: 'PlaylistRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }

  @override
  Future<List<Playlist>> getNewReleasesPlaylists({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  }) async {
    try {
      return await remoteDataSource.getNewReleasesPlaylists(
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to get new releases playlists',
        tag: 'PlaylistRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }

  @override
  Future<List<Album>> getNewReleaseAlbums({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  }) async {
    try {
      return await remoteDataSource.getNewReleaseAlbums(
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to get new release albums',
        tag: 'PlaylistRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }

  @override
  Future<Playlist?> getPlaylist(String playlistId) async {
    try {
      return await remoteDataSource.getPlaylist(playlistId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to get playlist details for id $playlistId',
        tag: 'PlaylistRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }

  @override
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      return await remoteDataSource.getPlaylistTracks(playlistId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to get tracks for playlist $playlistId',
        tag: 'PlaylistRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }
}

/// Riverpod provider for the [PlaylistRepository] domain abstraction.
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final remoteDataSource = ref.watch(playlistRemoteDataSourceProvider);
  return PlaylistRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Alias provider for explicit implementation reference.
final playlistRepositoryImplProvider = playlistRepositoryProvider;
