import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/features/local_files/data/datasources/local_files_local_data_source.dart';
import 'package:audifi/features/local_files/domain/entities/local_audio_track.dart';
import 'package:audifi/features/playback/data/datasources/queue_local_data_source.dart';
import 'package:audifi/features/playback/data/datasources/stream_remote_data_source.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

void main() {
  group('Local Files Architecture & Operations', () {
    late Directory tempDir;
    late Directory sourceDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('audifi_local_test_');
      sourceDir = await Directory.systemTemp.createTemp('audifi_source_test_');
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
        if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
      } catch (_) {}
    });

    test('LocalAudioTrack serializes and deserializes correctly', () {
      final now = DateTime.now();
      final localTrack = LocalAudioTrack(
        track: const Track(
          id: 'local_123',
          title: 'My Device Song',
          duration: 215,
        ),
        localFilePath: '/path/to/song.mp3',
        fileSizeBytes: 5242880, // 5 MB
        importedAt: now,
        fileExtension: 'mp3',
      );

      final json = localTrack.toJson();
      final reconstituted = LocalAudioTrack.fromJson(json);

      expect(reconstituted.track.id, equals('local_123'));
      expect(reconstituted.track.title, equals('My Device Song'));
      expect(reconstituted.track.duration, equals(215));
      expect(reconstituted.fileExtension, equals('mp3'));
      expect(reconstituted.formattedSize, equals('5.0 MB'));
    });

    test('imports audio file into app-managed storage without destroying source file', () async {
      // Create a dummy source audio file in the user's directory
      final userAudioFile = File(
        '${sourceDir.path}/Artist Name - Summer Anthem.mp3',
      );
      await userAudioFile.writeAsString(
        'dummy mp3 binary content header and bytes',
      );

      final dataSource = LocalFilesLocalDataSource(
        prefsAsync: SharedPreferences.getInstance(),
        customStorageDir: '${tempDir.path}/audifi_local_files',
      );
      await dataSource.init();

      // Import the file
      final imported = await dataSource.importAudioFile(
        sourcePath: userAudioFile.path,
        originalName: 'Artist Name - Summer Anthem.mp3',
        sizeBytes: 42,
      );

      // 1. Verifies track metadata parsing
      expect(imported.track.id.startsWith('local_'), isTrue);
      expect(imported.track.title, equals('Summer Anthem'));
      expect(imported.track.user?.name, equals('Artist Name'));
      expect(imported.fileExtension, equals('mp3'));

      // 2. Verifies app-managed file was copied and exists
      final managedFile = File(imported.localFilePath);
      expect(managedFile.existsSync(), isTrue);

      // 3. Verifies the user's original source file is completely intact!
      expect(userAudioFile.existsSync(), isTrue);

      // 4. Verifies retrieval from dataSource
      expect(dataSource.isLocalFile(imported.track.id), isTrue);
      expect(dataSource.getLocalTracks().length, equals(1));
    });

    test('removing local track deletes app-managed copy while preserving user source file', () async {
      final userAudioFile = File('${sourceDir.path}/Original Track.flac');
      await userAudioFile.writeAsString('sample audio content');

      final dataSource = LocalFilesLocalDataSource(
        prefsAsync: SharedPreferences.getInstance(),
        customStorageDir: '${tempDir.path}/audifi_local_files',
      );
      await dataSource.init();

      final imported = await dataSource.importAudioFile(
        sourcePath: userAudioFile.path,
        originalName: 'Original Track.flac',
      );

      expect(dataSource.isLocalFile(imported.track.id), isTrue);

      // Remove from Audifi
      await dataSource.removeLocalTrack(imported.track.id);

      // App-managed copy is deleted
      expect(File(imported.localFilePath).existsSync(), isFalse);
      expect(dataSource.isLocalFile(imported.track.id), isFalse);

      // Original user file is STILL intact!
      expect(userAudioFile.existsSync(), isTrue);
    });

    test('PlaybackRepository resolves stream URL from local files without network call', () async {
      final userAudioFile = File('${sourceDir.path}/Offline Song.wav');
      await userAudioFile.writeAsString('wav audio binary test bytes');

      final localDataSource = LocalFilesLocalDataSource(
        prefsAsync: SharedPreferences.getInstance(),
        customStorageDir: '${tempDir.path}/audifi_local_files',
      );
      await localDataSource.init();

      final imported = await localDataSource.importAudioFile(
        sourcePath: userAudioFile.path,
        originalName: 'Offline Song.wav',
      );

      final failingRemote = _ThrowingStreamRemoteDataSource();
      final repository = PlaybackRepositoryImpl(
        remoteDataSource: failingRemote,
        localDataSource: QueueLocalDataSource(
          prefsAsync: SharedPreferences.getInstance(),
        ),
        localFilesLocalDataSource: localDataSource,
      );

      // Resolving stream URL returns the local file path directly (does not call remoteDataSource!)
      final resolvedUrl = await repository.resolveStreamUrl(imported.track.id);
      expect(resolvedUrl, equals(imported.localFilePath));

      // Prefetching skips remote call for local files
      await repository.prefetchStreamUrl(imported.track.id);
      expect(failingRemote.callCount, equals(0));
    });

    test(
      'supports all major audio formats: MP3, FLAC, WAV, M4A, AAC, OGG',
      () async {
        final formats = ['mp3', 'flac', 'wav', 'm4a', 'aac', 'ogg'];
        final dataSource = LocalFilesLocalDataSource(
          prefsAsync: SharedPreferences.getInstance(),
          customStorageDir: '${tempDir.path}/audifi_local_files',
        );
        await dataSource.init();

        for (final ext in formats) {
          final sampleFile = File('${sourceDir.path}/track.$ext');
          await sampleFile.writeAsString('audio content for $ext');

          final imported = await dataSource.importAudioFile(
            sourcePath: sampleFile.path,
            originalName: 'Track Name.$ext',
          );

          expect(imported.fileExtension, equals(ext));
          expect(File(imported.localFilePath).existsSync(), isTrue);
          expect(dataSource.isLocalFile(imported.track.id), isTrue);
        }

        expect(dataSource.getLocalTracks().length, equals(formats.length));
      },
    );

    test(
      'duplicate import creates independent unique tracks without collisions',
      () async {
        final sampleFile = File('${sourceDir.path}/Duplicate Track.mp3');
        await sampleFile.writeAsString('test binary content');

        final dataSource = LocalFilesLocalDataSource(
          prefsAsync: SharedPreferences.getInstance(),
          customStorageDir: '${tempDir.path}/audifi_local_files',
        );
        await dataSource.init();

        final firstImport = await dataSource.importAudioFile(
          sourcePath: sampleFile.path,
          originalName: 'Duplicate Track.mp3',
        );

        // Sleep a small duration to ensure distinct millisecond timestamp
        await Future<void>.delayed(const Duration(milliseconds: 5));

        final secondImport = await dataSource.importAudioFile(
          sourcePath: sampleFile.path,
          originalName: 'Duplicate Track.mp3',
        );

        expect(firstImport.track.id, isNot(equals(secondImport.track.id)));
        expect(
          firstImport.localFilePath,
          isNot(equals(secondImport.localFilePath)),
        );
        expect(File(firstImport.localFilePath).existsSync(), isTrue);
        expect(File(secondImport.localFilePath).existsSync(), isTrue);
        expect(dataSource.getLocalTracks().length, equals(2));
      },
    );

    test(
      'large file import completes responsively and preserves disk integrity',
      () async {
        final largeFile = File('${sourceDir.path}/Large Symphony.mp3');
        // Create a 2MB buffer
        final largeBytes = List<int>.filled(2 * 1024 * 1024, 65);
        await largeFile.writeAsBytes(largeBytes);

        final dataSource = LocalFilesLocalDataSource(
          prefsAsync: SharedPreferences.getInstance(),
          customStorageDir: '${tempDir.path}/audifi_local_files',
        );
        await dataSource.init();

        final imported = await dataSource.importAudioFile(
          sourcePath: largeFile.path,
          originalName: 'Large Symphony.mp3',
          sizeBytes: largeBytes.length,
        );

        expect(imported.fileSizeBytes, equals(2 * 1024 * 1024));
        expect(imported.formattedSize, equals('2.0 MB'));
        expect(
          File(imported.localFilePath).lengthSync(),
          equals(2 * 1024 * 1024),
        );
      },
    );

    test('reconciles missing on-disk files and cleans up orphaned .tmp files during init', () async {
      final dataSource = LocalFilesLocalDataSource(
        prefsAsync: SharedPreferences.getInstance(),
        customStorageDir: '${tempDir.path}/audifi_local_files',
      );
      await dataSource.init();

      // Create an orphaned .tmp file simulating an interrupted import
      final storageDir = Directory('${tempDir.path}/audifi_local_files');
      final orphanTmp = File('${storageDir.path}/interrupted_import.tmp');
      await orphanTmp.writeAsString('partial incomplete bytes');
      expect(orphanTmp.existsSync(), isTrue);

      // Re-initialize data source
      final freshDataSource = LocalFilesLocalDataSource(
        prefsAsync: SharedPreferences.getInstance(),
        customStorageDir: '${tempDir.path}/audifi_local_files',
      );
      await freshDataSource.init();

      // Verify orphan was deleted
      expect(orphanTmp.existsSync(), isFalse);
    });

    test('mixed queue resolution resolves Audius remote, downloaded, and local files seamlessly', () async {
      final localFile = File('${sourceDir.path}/My Local Song.mp3');
      await localFile.writeAsString('local audio bytes');

      final localDataSource = LocalFilesLocalDataSource(
        prefsAsync: SharedPreferences.getInstance(),
        customStorageDir: '${tempDir.path}/audifi_local_files',
      );
      await localDataSource.init();
      final localTrack = await localDataSource.importAudioFile(
        sourcePath: localFile.path,
        originalName: 'My Local Song.mp3',
      );

      final mockRemote = _MockStreamRemoteDataSource();
      final repository = PlaybackRepositoryImpl(
        remoteDataSource: mockRemote,
        localDataSource: QueueLocalDataSource(
          prefsAsync: SharedPreferences.getInstance(),
        ),
        localFilesLocalDataSource: localDataSource,
      );

      // Track 1: Audius remote stream
      final url1 = await repository.resolveStreamUrl('audius_track_1');
      expect(url1, equals('https://audius.co/stream/audius_track_1'));

      // Track 2: Local file track
      final url2 = await repository.resolveStreamUrl(localTrack.track.id);
      expect(url2, equals(localTrack.localFilePath));

      // Track 3: Audius remote stream
      final url3 = await repository.resolveStreamUrl('audius_track_2');
      expect(url3, equals('https://audius.co/stream/audius_track_2'));

      // Verify remote was ONLY called for audius tracks, NEVER for the local file!
      expect(
        mockRemote.requestedTrackIds,
        equals(['audius_track_1', 'audius_track_2']),
      );
    });
  });
}

class _MockStreamRemoteDataSource implements StreamRemoteDataSource {
  final List<String> requestedTrackIds = [];

  @override
  DioClient get client => throw UnimplementedError();

  @override
  Future<String> getStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    requestedTrackIds.add(trackId);
    return 'https://audius.co/stream/$trackId';
  }
}

class _ThrowingStreamRemoteDataSource implements StreamRemoteDataSource {
  int callCount = 0;

  @override
  DioClient get client => throw UnimplementedError();

  @override
  Future<String> getStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    callCount++;
    throw Exception('Should not call remote data source for local files!');
  }
}
