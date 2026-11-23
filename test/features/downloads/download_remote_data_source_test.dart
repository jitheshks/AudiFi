import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/core/errors/app_exception.dart';
import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/features/downloads/data/datasources/download_remote_data_source.dart';
import 'package:audifi/features/downloads/domain/entities/track_download_permission.dart';

class _MockDownloadHttpClientAdapter implements HttpClientAdapter {
  _MockDownloadHttpClientAdapter(this.handler);

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
  group('DownloadRemoteDataSource', () {
    late Dio dio;
    late DioClient dioClient;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.audius.co/v1'));
      dioClient = DioClient(rawDio: dio);
    });

    test(
      'resolves official download URL from 302 redirect Location header',
      () async {
        dio.httpClientAdapter = _MockDownloadHttpClientAdapter((options) async {
          expect(options.path, contains('/tracks/auth_track_123/download'));
          return ResponseBody.fromString(
            '',
            302,
            headers: {
              'location': [
                'https://creatornode.audius.co/tracks/cidstream/QmAuthorizedAudio?filename=Song.mp3',
              ],
            },
          );
        });

        final dataSource = DownloadRemoteDataSource(client: dioClient);
        final downloadUrl = await dataSource.getDownloadUrl('auth_track_123');

        expect(
          downloadUrl,
          equals(
            'https://creatornode.audius.co/tracks/cidstream/QmAuthorizedAudio?filename=Song.mp3',
          ),
        );
      },
    );

    test('throws TrackNotDownloadableException when API returns 404', () async {
      dio.httpClientAdapter = _MockDownloadHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          '{"code":404,"error":"track is not downloadable"}',
          404,
          headers: {
            'content-type': ['application/json'],
          },
        );
      });

      final dataSource = DownloadRemoteDataSource(client: dioClient);
      expect(
        () => dataSource.getDownloadUrl('disabled_track_456'),
        throwsA(isA<TrackNotDownloadableException>()),
      );
    });

    test('throws TrackDownloadGatedException when API returns 403', () async {
      dio.httpClientAdapter = _MockDownloadHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          '{"code":403,"error":"you are not allowed to download this track"}',
          403,
          headers: {
            'content-type': ['application/json'],
          },
        );
      });

      final dataSource = DownloadRemoteDataSource(client: dioClient);
      expect(
        () => dataSource.getDownloadUrl('gated_track_789'),
        throwsA(isA<TrackDownloadGatedException>()),
      );
    });

    test(
      'throws ServerException when API returns 400 invalid trackId',
      () async {
        dio.httpClientAdapter = _MockDownloadHttpClientAdapter((options) async {
          return ResponseBody.fromString(
            '{"code":400,"error":"invalid trackId"}',
            400,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });

        final dataSource = DownloadRemoteDataSource(client: dioClient);
        expect(
          () => dataSource.getDownloadUrl('invalid_track_id'),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test('verifyDownloadPermission returns authorized for downloadable ungated track', () async {
      dio.httpClientAdapter = _MockDownloadHttpClientAdapter((options) async {
        expect(options.path, contains('/tracks/track_open'));
        return ResponseBody.fromString(
          '{"data":{"id":"track_open","is_downloadable":true,"is_download_gated":false}}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        );
      });

      final dataSource = DownloadRemoteDataSource(client: dioClient);
      final perm = await dataSource.verifyDownloadPermission('track_open');
      expect(perm, equals(TrackDownloadPermission.authorized));
    });

    test(
      'verifyDownloadPermission returns gated for download-gated track',
      () async {
        dio.httpClientAdapter = _MockDownloadHttpClientAdapter((options) async {
          return ResponseBody.fromString(
            '{"data":{"id":"track_gated","is_downloadable":true,"is_download_gated":true}}',
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });

        final dataSource = DownloadRemoteDataSource(client: dioClient);
        final perm = await dataSource.verifyDownloadPermission('track_gated');
        expect(perm, equals(TrackDownloadPermission.gated));
      },
    );

    test(
      'verifyDownloadPermission returns disabled when is_downloadable is false',
      () async {
        dio.httpClientAdapter = _MockDownloadHttpClientAdapter((options) async {
          return ResponseBody.fromString(
            '{"data":{"id":"track_closed","is_downloadable":false,"is_download_gated":false}}',
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });

        final dataSource = DownloadRemoteDataSource(client: dioClient);
        final perm = await dataSource.verifyDownloadPermission('track_closed');
        expect(perm, equals(TrackDownloadPermission.disabled));
      },
    );
  });
}
