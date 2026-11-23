import 'dart:convert';
import 'dart:typed_data';

import 'package:audifi/core/constants/api_constants.dart';
import 'package:audifi/core/constants/api_endpoints.dart';
import 'package:audifi/core/errors/app_exception.dart';
import 'package:audifi/core/logging/app_logger.dart';
import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/features/playback/data/datasources/stream_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class MockStreamAdapter implements HttpClientAdapter {
  MockStreamAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('StreamRemoteDataSource', () {
    late Dio dio;
    late DioClient dioClient;
    late StreamRemoteDataSource dataSource;

    void setupMock(
      Future<ResponseBody> Function(RequestOptions options) handler,
    ) {
      dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      dio.httpClientAdapter = MockStreamAdapter(handler);
      dioClient = DioClient(rawDio: dio);
      dataSource = StreamRemoteDataSource(client: dioClient);
    }

    test('resolves stream URL from 302 redirect Location header', () async {
      const trackId = 'track_123';
      const redirectUrl =
          'https://audius-discovery-1.audius.co/v1/tracks/stream/audio123.mp3';

      setupMock((options) async {
        expect(options.path, equals(ApiEndpoints.trackStream(trackId)));
        expect(options.queryParameters['no_redirect'], equals('true'));
        expect(options.followRedirects, isFalse);

        return ResponseBody.fromString(
          '',
          302,
          headers: {
            'location': [redirectUrl],
          },
        );
      });

      final url = await dataSource.getStreamUrl(trackId);
      expect(url, equals(redirectUrl));
    });

    test('resolves stream URL from 200 OK JSON response', () async {
      const trackId = 'track_456';
      const streamUrl =
          'https://audius-creator-node.audius.co/ipfs/QmAudio456.mp3';

      setupMock((options) async {
        expect(options.path, equals(ApiEndpoints.trackStream(trackId)));
        return ResponseBody.fromString(
          jsonEncode({'data': streamUrl}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final url = await dataSource.getStreamUrl(trackId);
      expect(url, equals(streamUrl));
    });

    test('throws ServerException when response lacks stream URL', () async {
      const trackId = 'track_empty';

      setupMock((options) async {
        return ResponseBody.fromString(
          jsonEncode({'data': ''}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      expect(
        () => dataSource.getStreamUrl(trackId),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws NetworkException on connection failure', () async {
      const trackId = 'track_fail';

      setupMock((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Connection refused',
        );
      });

      expect(
        () => dataSource.getStreamUrl(trackId),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws CancellationException on request cancellation', () async {
      const trackId = 'track_cancel';
      final cancelToken = CancelToken();

      setupMock((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: 'Request was cancelled',
        );
      });

      expect(
        () => dataSource.getStreamUrl(trackId, cancelToken: cancelToken),
        throwsA(isA<CancellationException>()),
      );
    });

    test('AppLogger redacts sensitive tokens and api_key from stream URLs', () {
      const sensitiveUrl =
          'https://audius-dn.com/stream?api_key=secret_key_12345&token=jwt_token_abc&signature=sig789';
      final sanitized = AppLogger.redactSensitive(sensitiveUrl);

      expect(sanitized, contains('api_key=[REDACTED]'));
      expect(sanitized, contains('token=[REDACTED]'));
      expect(sanitized, isNot(contains('secret_key_12345')));
      expect(sanitized, isNot(contains('jwt_token_abc')));
    });
  });
}
