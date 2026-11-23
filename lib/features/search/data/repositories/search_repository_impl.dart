import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../datasources/search_remote_data_source.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

/// Implementation of [SearchRepository] coordinating the [SearchRemoteDataSource].
class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl({required this.remoteDataSource});

  final SearchRemoteDataSource remoteDataSource;

  @override
  Future<SearchResult> search(
    String query, {
    String? kind,
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    bool? includePurchaseable,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const SearchResult();
    }

    try {
      return await remoteDataSource.searchFull(
        trimmed,
        kind: kind,
        limit: limit,
        offset: offset,
        includePurchaseable: includePurchaseable,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to execute catalog search for query "$trimmed"',
        tag: 'SearchRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (error is AppException) rethrow;
      throw ErrorMapper.mapToException(error, stackTrace);
    }
  }
}

/// Riverpod provider for the [SearchRepository] domain abstraction.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final remoteDataSource = ref.watch(searchRemoteDataSourceProvider);
  return SearchRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Alias provider for explicit implementation reference.
final searchRepositoryImplProvider = searchRepositoryProvider;
