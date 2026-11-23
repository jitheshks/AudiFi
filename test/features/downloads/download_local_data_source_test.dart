import 'dart:io';

import 'package:audifi/features/downloads/data/datasources/download_local_data_source.dart';
import 'package:audifi/features/downloads/domain/entities/downloaded_track.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SharedPreferences prefs;
  late DownloadLocalDataSource dataSource;

  const testTrack = Track(
    id: 'test_track_1',
    title: 'Offline Song',
    duration: 180,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tempDir = await Directory.systemTemp.createTemp('audifi_downloads_test_');
    dataSource = DownloadLocalDataSource(
      prefsAsync: Future.value(prefs),
      customDownloadDir: tempDir.path,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DownloadLocalDataSource', () {
    test(
      'cleans up orphaned .tmp files and initializes successfully',
      () async {
        final orphanFile = File('${tempDir.path}/orphan.tmp');
        await orphanFile.writeAsString('partial-bytes');
        expect(await orphanFile.exists(), isTrue);

        await dataSource.init();

        expect(await orphanFile.exists(), isFalse);
      },
    );

    test(
      'saves downloaded track and confirms physical file presence',
      () async {
        await dataSource.init();
        final finalPath = await dataSource.getTargetFilePath(testTrack.id);
        final file = File(finalPath);
        await file.writeAsBytes(List.generate(1024, (i) => i % 256));

        final downloadedTrack = DownloadedTrack(
          track: testTrack,
          localFilePath: finalPath,
          fileSizeBytes: 1024,
          downloadedAt: DateTime.now(),
        );

        await dataSource.saveDownloadedTrack(downloadedTrack);

        expect(dataSource.isTrackDownloaded(testTrack.id), isTrue);
        expect(dataSource.getDownloadedTracks().length, equals(1));
        expect(
          dataSource.getDownloadedTrack(testTrack.id)?.track.title,
          equals('Offline Song'),
        );

        final storageBytes = await dataSource.getTotalStorageBytes();
        expect(storageBytes, equals(1024));
      },
    );

    test('reconciles and removes metadata when physical file is deleted outside app', () async {
      await dataSource.init();
      final finalPath = await dataSource.getTargetFilePath(testTrack.id);
      final file = File(finalPath);
      await file.writeAsBytes(List.generate(2048, (i) => i % 256));

      final downloadedTrack = DownloadedTrack(
        track: testTrack,
        localFilePath: finalPath,
        fileSizeBytes: 2048,
        downloadedAt: DateTime.now(),
      );
      await dataSource.saveDownloadedTrack(downloadedTrack);
      expect(dataSource.isTrackDownloaded(testTrack.id), isTrue);

      // Simulate external file deletion
      await file.delete();

      // Create new instance pointing to same storage to simulate app restart
      final newDataSource = DownloadLocalDataSource(
        prefsAsync: Future.value(prefs),
        customDownloadDir: tempDir.path,
      );
      await newDataSource.init();

      expect(newDataSource.isTrackDownloaded(testTrack.id), isFalse);
      expect(newDataSource.getDownloadedTracks(), isEmpty);
    });

    test('removes downloaded track and cleans up disk file', () async {
      await dataSource.init();
      final finalPath = await dataSource.getTargetFilePath(testTrack.id);
      final file = File(finalPath);
      await file.writeAsBytes(List.generate(512, (i) => i % 256));

      final downloadedTrack = DownloadedTrack(
        track: testTrack,
        localFilePath: finalPath,
        fileSizeBytes: 512,
        downloadedAt: DateTime.now(),
      );
      await dataSource.saveDownloadedTrack(downloadedTrack);
      expect(await file.exists(), isTrue);

      await dataSource.removeDownloadedTrack(testTrack.id);

      expect(dataSource.isTrackDownloaded(testTrack.id), isFalse);
      expect(await file.exists(), isFalse);
    });

    test('clearAll removes all audio files and clears metadata', () async {
      await dataSource.init();
      for (int i = 1; i <= 3; i++) {
        final path = await dataSource.getTargetFilePath('track_$i');
        await File(path)
            .writeAsBytes(List.generate(100 * i, (idx) => idx % 256));
        await dataSource.saveDownloadedTrack(
          DownloadedTrack(
            track: Track(id: 'track_$i', title: 'Track $i', duration: 120),
            localFilePath: path,
            fileSizeBytes: 100 * i,
            downloadedAt: DateTime.now(),
          ),
        );
      }
      expect(dataSource.getDownloadedTracks().length, equals(3));

      await dataSource.clearAll();

      expect(dataSource.getDownloadedTracks(), isEmpty);
      expect(await dataSource.getTotalStorageBytes(), equals(0));
    });
  });
}
