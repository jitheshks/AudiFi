import 'package:audifi/core/api/api_client.dart';
import 'package:audifi/core/api/api_constants.dart';
import 'package:audifi/core/api/api_endpoints.dart';
import 'package:audifi/core/api/api_exceptions.dart';
import 'package:audifi/core/api/api_interceptors.dart';
import 'package:audifi/shared/models/api_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(RequestOptions requestOptions) {
    nextCalled = true;
  }
}

void main() {
  group('ApiConstants & ApiEndpoints', () {
    test('ApiConstants matches verified Audius OpenAPI specification', () {
      expect(ApiConstants.baseUrl, 'https://api.audius.co/v1');
      expect(ApiConstants.defaultAppName, 'AudiFi');
      expect(ApiConstants.connectTimeout, const Duration(seconds: 15));
      expect(ApiConstants.receiveTimeout, const Duration(seconds: 15));
      expect(ApiConstants.sendTimeout, const Duration(seconds: 15));
    });

    test('ApiEndpoints constructs verified routes', () {
      expect(ApiEndpoints.trendingTracks, '/tracks/trending');
      expect(ApiEndpoints.trackStream('track123'), '/tracks/track123/stream');
      expect(ApiEndpoints.trackDetails('track123'), '/tracks/track123');
      expect(ApiEndpoints.trendingPlaylists, '/playlists/trending');
      expect(ApiEndpoints.playlistDetails('pl456'), '/playlists/pl456');
      expect(ApiEndpoints.playlistTracks('pl456'), '/playlists/pl456/tracks');
      expect(ApiEndpoints.userDetails('user789'), '/users/user789');
      expect(
        ApiEndpoints.userByHandle('artist_xyz'),
        '/users/handle/artist_xyz',
      );
      expect(ApiEndpoints.userTracks('user789'), '/users/user789/tracks');
      expect(ApiEndpoints.searchFull, '/search/full');
      expect(ApiEndpoints.resolve, '/resolve');
    });
  });

  group('ApiException', () {
    test('maps connection timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/tracks'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.type, ApiExceptionType.connectionTimeout);
    });

    test('maps 400 Bad Request', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/tracks'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/tracks'),
          statusCode: 400,
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.type, ApiExceptionType.badRequest);
      expect(apiException.statusCode, 400);
    });

    test('maps 404 Not Found', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/tracks/missing'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/tracks/missing'),
          statusCode: 404,
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.type, ApiExceptionType.notFound);
      expect(apiException.statusCode, 404);
    });

    test('maps 500 Server Error', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/tracks'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/tracks'),
          statusCode: 500,
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.type, ApiExceptionType.serverError);
      expect(apiException.statusCode, 500);
    });
  });

  group('AudiusHeadersInterceptor', () {
    test('attaches app_name to query parameters automatically', () {
      final interceptor = AudiusHeadersInterceptor(appName: 'AudifiTest');
      final options = RequestOptions(path: '/tracks');
      final handler = _TestRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.nextCalled, isTrue);
      expect(options.queryParameters[ApiConstants.paramAppName], 'AudifiTest');
      expect(options.headers['Accept'], 'application/json');
    });
  });

  group('ApiResponse Model', () {
    test('deserializes Audius envelope structure', () {
      final json = {
        'data': [
          {'id': 't1', 'title': 'Track One'},
        ],
        'signature': 'sig123',
        'timestamp': '2026-11-17T12:00:00Z',
        'latest_chain_block': 123456,
        'latest_indexed_block': 123450,
      };

      final response = ApiResponse.fromJson(
        json,
        (data) => (data as List).map((e) => e['title'] as String).toList(),
      );

      expect(response.data, ['Track One']);
      expect(response.signature, 'sig123');
      expect(response.latestChainBlock, 123456);
      expect(response.latestIndexedBlock, 123450);
    });
  });

  group('ApiClient', () {
    test('rawDio returns underlying client instance', () {
      final dio = Dio();
      final client = ApiClient(rawDio: dio);
      expect(client.rawDio, equals(dio));
    });
  });
}
