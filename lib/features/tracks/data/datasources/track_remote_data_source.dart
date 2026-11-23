import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/track_model.dart';

/// Remote data source interfacing with Audius track endpoints.
class TrackRemoteDataSource {
  const TrackRemoteDataSource({required this.client});

  final DioClient client;

  /// Fetches trending tracks from `/tracks/trending`.
  Future<List<TrackModel>> getTrendingTracks({
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

    final response = await client.get<Map<String, dynamic>>(
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

  /// Fetches recently published tracks from `/tracks/latest`.
  Future<List<TrackModel>> getLatestTracks({
    int limit = 15,
    int offset = ApiConstants.defaultOffset,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
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

  /// Fetches published tracks for a user from `/users/{id}/tracks`.
  Future<List<TrackModel>> getUserTracks(
    String userId, {
    int limit = 50,
    int offset = ApiConstants.defaultOffset,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
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

  /// Fetches underground trending tracks from `/tracks/trending/underground`.
  Future<List<TrackModel>> getTrendingUndergroundTracks({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.trendingUndergroundTracks,
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

  /// Fetches complete track metadata for [trackId] from `/tracks/{id}`.
  Future<TrackModel?> getTrack(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.trackDetails(trackId),
      cancelToken: cancelToken,
    );

    final rawData = response.data?['data'];
    if (rawData is Map<String, dynamic>) {
      return TrackModel.fromJson(rawData);
    }
    return null;
  }
}

/// Riverpod provider for [TrackRemoteDataSource].
final trackRemoteDataSourceProvider = Provider<TrackRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return TrackRemoteDataSource(client: client);
});
