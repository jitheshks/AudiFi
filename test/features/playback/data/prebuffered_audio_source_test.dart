import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/features/playback/data/services/prebuffered_audio_source.dart';

void main() {
  group('PrebufferedAudioSource', () {
    late Directory tempDir;
    late File prebufferFile;
    const int prebufferedBytes = 500 * 1024; // 500 KiB

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('prebuffer_source_test_');
      prebufferFile = File('${tempDir.path}/track_test.buf');

      // Create a deterministic byte pattern for testing slices
      final bytes = Uint8List(prebufferedBytes);
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = i % 256;
      }
      prebufferFile.writeAsBytesSync(bytes);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('serves local prefix from byte 0 up to prebufferedBytes', () async {
      final source = PrebufferedAudioSource(
        trackId: 'track_test',
        prebufferedFile: prebufferFile,
        prebufferedBytes: prebufferedBytes,
        totalContentLength: 2000 * 1024,
        remoteUri: Uri.parse(
          'http://127.0.0.1:9999/dummy',
        ), // Unreachable port simulates offline
      );

      final response = await source.request(0, prebufferedBytes);

      expect(response.rangeRequestsSupported, isTrue);
      expect(response.offset, equals(0));
      expect(response.contentLength, equals(prebufferedBytes));
      expect(response.contentType, equals('audio/mpeg'));

      final chunks = await response.stream.toList();
      final totalRead = chunks.fold<int>(0, (sum, c) => sum + c.length);
      expect(totalRead, equals(prebufferedBytes));
    });

    test('serves sub-slice of local prebuffer when start and end are within prebuffer', () async {
      final source = PrebufferedAudioSource(
        trackId: 'track_test',
        prebufferedFile: prebufferFile,
        prebufferedBytes: prebufferedBytes,
        totalContentLength: 2000 * 1024,
        remoteUri: Uri.parse('http://127.0.0.1:9999/dummy'),
      );

      const start = 1000;
      const end = 5000;
      final response = await source.request(start, end);

      expect(response.offset, equals(start));
      expect(response.contentLength, equals(end - start));

      final chunks = await response.stream.toList();
      final totalRead = chunks.fold<int>(0, (sum, c) => sum + c.length);
      expect(totalRead, equals(4000));
    });

    test('gracefully yields all local bytes and invokes onOfflineExhausted when continuation fails offline', () async {
      bool exhaustedCalled = false;
      String? exhaustedTrackId;

      final source = PrebufferedAudioSource(
        trackId: 'track_test',
        prebufferedFile: prebufferFile,
        prebufferedBytes: prebufferedBytes,
        totalContentLength: 2000 * 1024,
        remoteUri: Uri.parse('http://127.0.0.1:9999/non_existent_stream'),
        onOfflineExhausted: (tId) {
          exhaustedCalled = true;
          exhaustedTrackId = tId;
        },
      );

      // Full stream request without end bound
      final response = await source.request(0, null);

      expect(response.offset, equals(0));
      expect(response.sourceLength, equals(2000 * 1024));

      final chunks = await response.stream.toList();
      final totalRead = chunks.fold<int>(0, (sum, c) => sum + c.length);

      // All 500 KiB local bytes were read without error
      expect(totalRead, equals(prebufferedBytes));
      expect(exhaustedCalled, isTrue);
      expect(exhaustedTrackId, equals('track_test'));
    });
  });
}
