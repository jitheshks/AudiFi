import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/features/downloads/data/datasources/download_local_data_source.dart';
import 'package:audifi/features/downloads/data/datasources/download_remote_data_source.dart';
import 'package:audifi/features/downloads/domain/entities/download_progress.dart';
import 'package:audifi/features/downloads/presentation/controllers/download_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

class _FakeDownloadHttpClientAdapter implements HttpClientAdapter {
  _FakeDownloadHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // 1. Download resolution endpoint
    if (options.path.contains('/download')) {
      if (options.path.contains('auth_track')) {
        return ResponseBody.fromString(
          '',
          302,
          headers: {
            'location': ['https://cdn.audius.co/audio/auth_track.mp3'],
          },
        );
      }
      if (options.path.contains('disabled_track')) {
        return ResponseBody.fromString(
          '{"code":404,"error":"track is not downloadable"}',
          404,
          headers: {
            'content-type': ['application/json'],
          },
        );
      }
      if (options.path.contains('gated_track')) {
        return ResponseBody.fromString(
          '{"code":403,"error":"you are not allowed to download this track"}',
          403,
          headers: {
            'content-type': ['application/json'],
          },
        );
      }
    }

    // 2. Direct byte download from CDN
    if (options.path.contains('auth_track.mp3')) {
      return ResponseBody(
        Stream.value(Uint8List.fromList(List.generate(1024, (i) => i % 256))),
        200,
        headers: {
          'content-type': ['audio/mpeg'],
          'content-length': ['1024'],
        },
      );
    }

    return ResponseBody.fromString('Not found', 404);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Creator-Authorized Downloads in DownloadController', () {
    late Directory tempDir;
    late SharedPreferences prefs;
    late Dio dio;
    late DioClient dioClient;
    late DownloadLocalDataSource localDataSource;
    late DownloadRemoteDataSource remoteDataSource;
    late ProviderContainer container;

    const authorizedTrack = Track(
      id: 'auth_track',
      title: 'Authorized Track',
      isDownloadable: true,
      isDownloadGated: false,
    );

    const disabledTrack = Track(
      id: 'disabled_track',
      title: 'Disabled Track',
      isDownloadable: false,
      isDownloadGated: false,
    );

    const gatedTrack = Track(
      id: 'gated_track',
      title: 'Gated Track',
      isDownloadable: true,
      isDownloadGated: true,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tempDir = await Directory.systemTemp.createTemp(
        'creator_downloads_test_',
      );

      dio = Dio(BaseOptions(baseUrl: 'https://api.audius.co/v1'));
      dio.httpClientAdapter = _FakeDownloadHttpClientAdapter();
      dioClient = DioClient(rawDio: dio);

      localDataSource = DownloadLocalDataSource(
        prefsAsync: Future.value(prefs),
        customDownloadDir: tempDir.path,
      );
      await localDataSource.init();

      remoteDataSource = DownloadRemoteDataSource(client: dioClient);

      container = ProviderContainer(
        overrides: [
          downloadLocalDataSourceProvider.overrideWithValue(localDataSource),
          downloadRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'downloads creator-authorized track using official download URL',
      () async {
        final controller = container.read(downloadControllerProvider.notifier);

        await controller.downloadTrack(authorizedTrack);

        // Verify file is stored in local storage
        expect(localDataSource.isTrackDownloaded('auth_track'), isTrue);
        final downloaded = localDataSource.getDownloadedTrack('auth_track');
        expect(downloaded, isNotNull);
        expect(downloaded!.fileSizeBytes, equals(1024));

        final progress = container.read(downloadProgressProvider('auth_track'));
        expect(progress?.status, equals(DownloadStatus.completed));
      },
    );

    test('rejects download for track where creator disabled downloads (pre-flight & API rejection)', () async {
      final controller = container.read(downloadControllerProvider.notifier);

      await controller.downloadTrack(disabledTrack);

      expect(localDataSource.isTrackDownloaded('disabled_track'), isFalse);
      final progress = container.read(
        downloadProgressProvider('disabled_track'),
      );
      expect(progress?.status, equals(DownloadStatus.failed));
      expect(
        progress?.errorMessage,
        equals("Downloads aren't available for this track."),
      );

      // Ensure no temp file remained
      final tempFile = File('${tempDir.path}/disabled_track.tmp');
      expect(tempFile.existsSync(), isFalse);
    });

    test(
      'rejects download for gated track without downloading streaming bytes',
      () async {
        final controller = container.read(downloadControllerProvider.notifier);

        await controller.downloadTrack(gatedTrack);

        expect(localDataSource.isTrackDownloaded('gated_track'), isFalse);
        final progress = container.read(
          downloadProgressProvider('gated_track'),
        );
        expect(progress?.status, equals(DownloadStatus.failed));
        expect(
          progress?.errorMessage,
          equals('This download requires creator access.'),
        );

        final tempFile = File('${tempDir.path}/gated_track.tmp');
        expect(tempFile.existsSync(), isFalse);
      },
    );

    test('trackDownloadPermissionProvider resolves all 5 permission states correctly', () async {
      // 1. Authorized
      final authPerm = await container.read(
        trackDownloadPermissionProvider(authorizedTrack).future,
      );
      expect(authPerm, equals(TrackDownloadPermission.authorized));
      expect(authPerm.isAuthorized, isTrue);

      // 2. Disabled
      final disabledPerm = await container.read(
        trackDownloadPermissionProvider(disabledTrack).future,
      );
      expect(disabledPerm, equals(TrackDownloadPermission.disabled));
      expect(disabledPerm.isDisabled, isTrue);
      expect(
        disabledPerm.statusMessage,
        equals("Downloads aren't available for this track."),
      );

      // 3. Gated
      final gatedPerm = await container.read(
        trackDownloadPermissionProvider(gatedTrack).future,
      );
      expect(gatedPerm, equals(TrackDownloadPermission.gated));
      expect(gatedPerm.isGated, isTrue);
      expect(
        gatedPerm.statusMessage,
        equals('This download requires creator access.'),
      );

      // 4. Remote verification when metadata is null
      const unknownTrack = Track(id: 'auth_track', title: 'Unknown Track');
      final unknownPerm = await container.read(
        trackDownloadPermissionProvider(unknownTrack).future,
      );
      expect(unknownPerm, equals(TrackDownloadPermission.authorized));

      // 5. Remote verification 404
      const unknownDisabled = Track(
        id: 'disabled_track',
        title: 'Unknown Disabled',
      );
      final unknownDisabledPerm = await container.read(
        trackDownloadPermissionProvider(unknownDisabled).future,
      );
      expect(unknownDisabledPerm, equals(TrackDownloadPermission.disabled));
    });
  });
}
