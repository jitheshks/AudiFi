import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';

/// Remote data source responsible for resolving Audius audio stream URLs.
/// Never downloads audio bytes into memory via HTTP.
class StreamRemoteDataSource {
  const StreamRemoteDataSource({required this.client});

  final DioClient client;

  /// Resolves the streamable audio URL for [trackId] from `/tracks/{track_id}/stream`.
  /// Supports both standard 302 redirect extraction and JSON stream_url_response.
  Future<String> getStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    try {
      AppLogger.debug(
        'Resolving stream URL for track: $trackId',
        tag: 'Playback',
      );

      // Request stream URL using no_redirect=true and followRedirects=false to prevent
      // memory buffering of audio bytes while safely inspecting headers or response JSON.
      final response = await client.get<dynamic>(
        ApiEndpoints.trackStream(trackId),
        queryParameters: {'no_redirect': 'true'},
        cancelToken: cancelToken,
        options: Options(
          followRedirects: false,
          validateStatus: (status) =>
              status != null &&
              (status < 400 ||
                  status == 301 ||
                  status == 302 ||
                  status == 307 ||
                  status == 308),
        ),
      );

      String? streamUrl;

      // 1. Check HTTP Redirect Location header (301, 302, 307, 308)
      if (response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 307 ||
          response.statusCode == 308) {
        streamUrl = response.headers.value('location');
      }

      // 2. Check 200 OK JSON response containing {"data": "<stream_url>"}
      if (streamUrl == null || streamUrl.isEmpty) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final streamData = data['data'];
          if (streamData is String && streamData.isNotEmpty) {
            streamUrl = streamData;
          }
        } else if (data is String && data.startsWith('http')) {
          streamUrl = data.trim();
        }
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        throw ServerException(
          message: 'Unable to resolve audio stream URL for track $trackId',
          statusCode: response.statusCode,
        );
      }

      AppLogger.debug(
        'Successfully resolved stream URL for track $trackId: ${AppLogger.redactSensitive(streamUrl)}',
        tag: 'Playback',
      );

      return streamUrl;
    } catch (e, st) {
      if (cancelToken?.isCancelled == true ||
          (e is DioException && e.type == DioExceptionType.cancel) ||
          e is CancellationException) {
        AppLogger.debug(
          'Stream URL resolution cancelled for track $trackId',
          tag: 'Playback',
        );
        throw const CancellationException();
      }
      if (e is AppException) rethrow;
      AppLogger.error(
        'Stream URL resolution failed for track $trackId',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
      throw NetworkException(
        message: 'Network error resolving stream for track $trackId: $e',
      );
    }
  }
}

/// Riverpod provider for [StreamRemoteDataSource].
final streamRemoteDataSourceProvider = Provider<StreamRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return StreamRemoteDataSource(client: client);
});
