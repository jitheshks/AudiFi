import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/track_download_permission.dart';

/// Exception thrown when a creator has disabled downloads for a track.
class TrackNotDownloadableException extends AppException {
  const TrackNotDownloadableException({
    super.message = 'Creator has not authorized downloads for this track.',
    super.statusCode = 404,
  });
}

/// Exception thrown when a download is restricted behind an access gate (purchase/NFT/follow).
class TrackDownloadGatedException extends AppException {
  const TrackDownloadGatedException({
    super.message =
        'This track requires creator-authorized purchase or access.',
    super.statusCode = 403,
  });
}

/// Remote data source responsible for verifying creator download authorization
/// and resolving official Audius download URLs via `/tracks/{track_id}/download`.
class DownloadRemoteDataSource {
  const DownloadRemoteDataSource({required this.client});

  final DioClient client;

  /// Resolves the official creator-authorized download URL for [trackId].
  ///
  /// Requests `/tracks/{track_id}/download` with `followRedirects: false`.
  /// - Status 302/301/307/308 -> returns destination `Location` URL.
  /// - Status 404 -> throws [TrackNotDownloadableException] (creator disabled).
  /// - Status 403 -> throws [TrackDownloadGatedException] (gated).
  /// - Other 4xx/5xx -> throws [ServerException].
  Future<String> getDownloadUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    try {
      AppLogger.debug(
        'Resolving official download URL for track: $trackId',
        tag: 'Downloads',
      );

      final response = await client.get<dynamic>(
        ApiEndpoints.trackDownload(trackId),
        queryParameters: {'no_redirect': 'true'},
        cancelToken: cancelToken,
        options: Options(
          followRedirects: false,
          validateStatus: (status) =>
              status != null &&
              (status < 500 ||
                  status == 301 ||
                  status == 302 ||
                  status == 307 ||
                  status == 308),
        ),
      );

      final statusCode = response.statusCode ?? 500;

      if (statusCode == 404) {
        AppLogger.warning(
          'Download rejected by Audius API (404): Track $trackId is not downloadable by creator settings.',
          tag: 'Downloads',
        );
        throw const TrackNotDownloadableException();
      }

      if (statusCode == 403) {
        AppLogger.warning(
          'Download rejected by Audius API (403): Track $trackId is gated behind access/purchase.',
          tag: 'Downloads',
        );
        throw const TrackDownloadGatedException();
      }

      if (statusCode >= 400) {
        throw ServerException(
          message: 'Download unavailable for track $trackId',
          statusCode: statusCode,
        );
      }

      // Check HTTP redirect Location header
      if (statusCode == 301 ||
          statusCode == 302 ||
          statusCode == 307 ||
          statusCode == 308) {
        final location = response.headers.value('location');
        if (location != null && location.isNotEmpty) {
          AppLogger.debug(
            'Resolved official download URL for $trackId: ${AppLogger.redactSensitive(location)}',
            tag: 'Downloads',
          );
          return location;
        }
      }

      // Check 200 OK JSON or string response
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final downloadData = data['data'];
        if (downloadData is String && downloadData.isNotEmpty) {
          return downloadData;
        }
      } else if (data is String && data.startsWith('http')) {
        return data.trim();
      }

      throw ServerException(
        message: 'No download location returned for track $trackId',
        statusCode: statusCode,
      );
    } catch (e, st) {
      if (cancelToken?.isCancelled == true ||
          (e is DioException && e.type == DioExceptionType.cancel) ||
          e is CancellationException) {
        AppLogger.debug(
          'Download URL resolution cancelled for track $trackId',
          tag: 'Downloads',
        );
        throw const CancellationException();
      }

      if (e is TrackNotDownloadableException ||
          e is TrackDownloadGatedException) {
        rethrow;
      }

      AppLogger.warning(
        'Failed to resolve download URL for track $trackId: $e',
        tag: 'Downloads',
        error: e,
        stackTrace: st,
      );

      if (e is AppException) rethrow;
      throw NetworkException(
        message: 'Network error resolving download for track $trackId',
      );
    }
  }

  /// Verifies creator download authorization against the official Audius API.
  Future<TrackDownloadPermission> verifyDownloadPermission(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.trackDetails(trackId),
        cancelToken: cancelToken,
      );

      final rawData = response.data?['data'];
      if (rawData is Map<String, dynamic>) {
        final isDownloadable = rawData['is_downloadable'] as bool? ?? false;
        final isGated = rawData['is_download_gated'] as bool? ?? false;

        if (isDownloadable && !isGated) {
          return TrackDownloadPermission.authorized;
        } else if (isGated) {
          return TrackDownloadPermission.gated;
        } else {
          return TrackDownloadPermission.disabled;
        }
      }
      return TrackDownloadPermission.disabled;
    } catch (e) {
      AppLogger.debug(
        'Error checking download permission for $trackId: $e',
        tag: 'Downloads',
      );
      return TrackDownloadPermission.error;
    }
  }
}

/// Provider for [DownloadRemoteDataSource].
final downloadRemoteDataSourceProvider = Provider<DownloadRemoteDataSource>((
  ref,
) {
  final client = ref.watch(dioClientProvider);
  return DownloadRemoteDataSource(client: client);
});
