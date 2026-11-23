import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/features/downloads/data/datasources/download_remote_data_source.dart';
import 'package:audifi/features/downloads/domain/entities/track_download_permission.dart';

void main() {
  group('Live Audius Download API & Creator Permissions Verification', () {
    late Dio dio;
    late DioClient dioClient;
    late DownloadRemoteDataSource dataSource;

    setUp(() {
      dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.audius.co/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      dioClient = DioClient(rawDio: dio);
      dataSource = DownloadRemoteDataSource(client: dioClient);
    });

    test(
      'Live Scenario 1: Creator-Authorized Download Track (jaKgV)',
      () async {
        // 1. Verify permission state from track metadata
        final perm = await dataSource.verifyDownloadPermission('jaKgV');
        expect(perm, equals(TrackDownloadPermission.authorized));

        // 2. Resolve official download URL via 302 redirect
        final downloadUrl = await dataSource.getDownloadUrl('jaKgV');
        expect(downloadUrl, isNotEmpty);
        expect(downloadUrl, contains('tracks/cidstream'));
        expect(downloadUrl, contains('skip_play_count=true'));

        // 3. Inspect headers from download location
        final headResponse = await dio.head<void>(
          downloadUrl,
          options: Options(followRedirects: true),
        );
        expect(headResponse.statusCode, equals(200));
        expect(
          headResponse.headers.value('content-type'),
          contains('audio/mpeg'),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'Live Scenario 2: Creator-Disabled Download Track (oWElNq5)',
      () async {
        // 1. Verify permission state from track metadata
        final perm = await dataSource.verifyDownloadPermission('oWElNq5');
        expect(perm, equals(TrackDownloadPermission.disabled));

        // 2. Endpoint must reject with 404 and throw TrackNotDownloadableException
        expect(
          () => dataSource.getDownloadUrl('oWElNq5'),
          throwsA(isA<TrackNotDownloadableException>()),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('Live Scenario 3: Creator-Gated Access Track (6kPrmyl)', () async {
      // 1. Verify permission state from track metadata (gated)
      final perm = await dataSource.verifyDownloadPermission('6kPrmyl');
      expect(perm, equals(TrackDownloadPermission.gated));

      // 2. Endpoint must reject unauthenticated request with 403 and throw TrackDownloadGatedException
      expect(
        () => dataSource.getDownloadUrl('6kPrmyl'),
        throwsA(isA<TrackDownloadGatedException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
