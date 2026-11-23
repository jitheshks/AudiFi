import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

/// Remote data source interfacing with Audius user and artist endpoints.
class ArtistRemoteDataSource {
  const ArtistRemoteDataSource({required this.client});

  final DioClient client;

  /// Retrieves user profile details by ID from `/users/{id}`.
  Future<UserModel?> getUser(String userId) async {
    final response = await client.get<Map<String, dynamic>>(
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

  /// Retrieves top users having at least one track by follower count from `/users/top`.
  Future<List<UserModel>> getTopUsers({int limit = 12, int offset = 0}) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.usersTop,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    final rawData = response.data?['data'];
    if (rawData is List<dynamic>) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList();
    }
    return const [];
  }

  /// Retrieves artists related to [userId] from `/users/{id}/related`.
  Future<List<UserModel>> getRelatedUsers(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        '/users/$userId/related',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final rawData = response.data?['data'];
      if (rawData is List<dynamic>) {
        return rawData
            .whereType<Map<String, dynamic>>()
            .map(UserModel.fromJson)
            .toList();
      }
    } catch (_) {}
    return const [];
  }
}

/// Riverpod provider for [ArtistRemoteDataSource].
final artistRemoteDataSourceProvider = Provider<ArtistRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return ArtistRemoteDataSource(client: client);
});
