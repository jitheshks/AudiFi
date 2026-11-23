import 'dart:io';

import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/features/downloads/data/datasources/download_local_data_source.dart';
import 'package:audifi/features/downloads/domain/entities/downloaded_track.dart';
import 'package:audifi/features/playback/data/datasources/queue_local_data_source.dart';
import 'package:audifi/features/playback/data/datasources/stream_remote_data_source.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockStreamRemoteDataSource extends StreamRemoteDataSource {
  MockStreamRemoteDataSource() : super(client: DioClient(rawDio: Dio()));

  int remoteCallCount = 0;

  @override
  Future<String> getStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    remoteCallCount++;
    return 'https://creatornode.audius.co/tracks/stream/$trackId.mp3';
  }
}

class MockQueueLocalDataSource extends QueueLocalDataSource {
  MockQueueLocalDataSource(Future<SharedPreferences> prefs)
    : super(prefsAsync: prefs);

  @override
  Future<void> saveQueue({
    required List<Track> tracks,
    required int currentIndex,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SharedPreferences prefs;
  late DownloadLocalDataSource downloadDataSource;
  late MockStreamRemoteDataSource remoteDataSource;
  late MockQueueLocalDataSource queueDataSource;
  late PlaybackRepositoryImpl playbackRepository;

  const downloadedTrack = Track(
    id: 'offline_track_123',
    title: 'Offline Masterpiece',
    duration: 210,
  );

  const onlineTrack = Track(
    id: 'online_track_456',
    title: 'Online Streaming Track',
    duration: 195,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tempDir = await Directory.systemTemp.createTemp('audifi_playback_test_');

    downloadDataSource = DownloadLocalDataSource(
      prefsAsync: Future.value(prefs),
      customDownloadDir: tempDir.path,
    );
    await downloadDataSource.init();

    // Create physical downloaded file
    final localPath = await downloadDataSource.getTargetFilePath(
      downloadedTrack.id,
    );
    await File(localPath).writeAsBytes(List.generate(1024, (i) => i % 256));
    await downloadDataSource.saveDownloadedTrack(
      DownloadedTrack(
        track: downloadedTrack,
        localFilePath: localPath,
        fileSizeBytes: 1024,
        downloadedAt: DateTime.now(),
      ),
    );

    remoteDataSource = MockStreamRemoteDataSource();
    queueDataSource = MockQueueLocalDataSource(Future.value(prefs));

    playbackRepository = PlaybackRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: queueDataSource,
      downloadLocalDataSource: downloadDataSource,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Offline Playback Integration', () {
    test('resolveStreamUrl returns local offline file path without calling remote API', () async {
      final resolvedSource = await playbackRepository.resolveStreamUrl(
        downloadedTrack.id,
      );

      expect(resolvedSource, contains(downloadedTrack.id));
      expect(File(resolvedSource).existsSync(), isTrue);
      // Confirmed no network calls occurred
      expect(remoteDataSource.remoteCallCount, equals(0));
    });

    test(
      'resolveStreamUrl falls back to remote API when track is not downloaded',
      () async {
        final resolvedSource = await playbackRepository.resolveStreamUrl(
          onlineTrack.id,
        );

        expect(
          resolvedSource,
          equals(
            'https://creatornode.audius.co/tracks/stream/online_track_456.mp3',
          ),
        );
        expect(remoteDataSource.remoteCallCount, equals(1));
      },
    );

    test(
      'prefetchStreamUrl skips network call if track is already downloaded',
      () async {
        await playbackRepository.prefetchStreamUrl(downloadedTrack.id);

        // No network prefetch executed
        expect(remoteDataSource.remoteCallCount, equals(0));
      },
    );

    test('prefetchStreamUrl executes network call for online tracks', () async {
      await playbackRepository.prefetchStreamUrl(onlineTrack.id);

      expect(remoteDataSource.remoteCallCount, equals(1));
    });
  });
}
