import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/track_repository.dart';
import '../datasources/track_remote_data_source.dart';

/// Implementation of [TrackRepository] coordinating the [TrackRemoteDataSource].
class TrackRepositoryImpl implements TrackRepository {
  const TrackRepositoryImpl({required this.remoteDataSource});

  final TrackRemoteDataSource remoteDataSource;

  @override
  Future<List<Track>> getTrendingTracks({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    String? genre,
    String time = ApiConstants.defaultTimeRange,
  }) async {
    try {
      return await remoteDataSource.getTrendingTracks(
        limit: limit,
        offset: offset,
        genre: genre,
        time: time,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to get trending tracks (genre: $genre, time: $time)',
        tag: 'TrackRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }

  @override
  Future<List<Track>> getLatestTracks({
    int limit = 15,
    int offset = ApiConstants.defaultOffset,
  }) async {
    try {
      return await remoteDataSource.getLatestTracks(
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to get latest tracks',
        tag: 'TrackRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }

  @override
  Future<List<Track>> getUserTracks(
    String userId, {
    int limit = 50,
    int offset = ApiConstants.defaultOffset,
  }) async {
    try {
      return await remoteDataSource.getUserTracks(
        userId,
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to get tracks for user $userId',
        tag: 'TrackRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }

  @override
  Future<List<Track>> getTrendingUndergroundTracks({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  }) async {
    try {
      return await remoteDataSource.getTrendingUndergroundTracks(
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to get trending underground tracks',
        tag: 'TrackRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }
}

/// Riverpod provider for the [TrackRepository] domain abstraction.
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final remoteDataSource = ref.watch(trackRemoteDataSourceProvider);
  return TrackRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Alias provider for explicit implementation reference.
final trackRepositoryImplProvider = trackRepositoryProvider;
