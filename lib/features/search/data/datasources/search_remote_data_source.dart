import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/search_result_model.dart';

/// Remote data source interfacing with Audius search endpoints.
class SearchRemoteDataSource {
  const SearchRemoteDataSource({required this.client});

  final DioClient client;

  /// Executes full-catalog search across tracks, users, playlists, and albums
  /// via `/search/full`.
  Future<SearchResultModel> searchFull(
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

    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.searchFull,
      queryParameters: queryParams,
    );

    final rawData = response.data?['data'];
    if (rawData is Map<String, dynamic>) {
      return SearchResultModel.fromJson(rawData);
    }
    return const SearchResultModel();
  }
}

/// Riverpod provider for [SearchRemoteDataSource].
final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return SearchRemoteDataSource(client: client);
});
