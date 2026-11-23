import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/artist_remote_data_source.dart';

/// Implementation of [UserRepository] coordinating the [ArtistRemoteDataSource].
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl({required this.remoteDataSource});

  final ArtistRemoteDataSource remoteDataSource;

  @override
  Future<User?> getUser(String userId) async {
    try {
      return await remoteDataSource.getUser(userId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch artist profile for user ID $userId',
        tag: 'UserRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }

  @override
  Future<List<User>> getTopUsers({int limit = 12, int offset = 0}) async {
    try {
      return await remoteDataSource.getTopUsers(limit: limit, offset: offset);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch top users/artists',
        tag: 'UserRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }

  @override
  Future<List<User>> getRelatedUsers(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      return await remoteDataSource.getRelatedUsers(
        userId,
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch related artists for user $userId',
        tag: 'UserRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }
}

/// Riverpod provider for the [UserRepository] domain abstraction.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final remoteDataSource = ref.watch(artistRemoteDataSourceProvider);
  return UserRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Alias provider for explicit implementation reference.
final userRepositoryImplProvider = userRepositoryProvider;
