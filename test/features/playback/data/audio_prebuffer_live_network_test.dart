import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/features/playback/data/services/audio_prebuffer_service.dart';
import 'package:audifi/features/playback/data/services/prebuffered_audio_source.dart';

void main() {
  group('Live Audius Audio Prebuffer Verification', () {
    late Directory tempDir;
    late DioClient dioClient;
    late AudioPrebufferService prebufferService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('live_prebuffer_test_');
      dioClient = DioClient(rawDio: Dio());
      prebufferService = AudioPrebufferService(
        dioClient: dioClient,
        customStorageDirectory: tempDir,
      );
    });

    tearDown(() async {
      prebufferService.cancelAll();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('fetches trending track stream URL and successfully prebuffers bounded audio bytes', () async {
      // 1. Resolve a real live track stream URL from Audius API
      final trendingResponse = await dioClient.rawDio.get<Map<String, dynamic>>(
        'https://api.audius.co/v1/tracks/trending',
        queryParameters: {'limit': 1, 'app_name': 'Audifi'},
      );

      expect(trendingResponse.statusCode, equals(200));
      final trackData =
          (trendingResponse.data!['data'] as List).first
              as Map<String, dynamic>;
      final trackId = trackData['id'] as String;
      expect(trackId, isNotEmpty);

      final streamUrl =
          'https://api.audius.co/v1/tracks/$trackId/stream?app_name=Audifi';

      // 2. Prebuffer bounded audio prefix (768 KiB = 786,432 bytes)
      final meta = await prebufferService.prebufferTrack(trackId, streamUrl);

      expect(meta, isNotNull);
      expect(meta!.trackId, equals(trackId));
      expect(meta.isComplete, isTrue);
      expect(
        meta.bufferedBytes,
        lessThanOrEqualTo(AudioPrebufferService.defaultPrebufferBytes),
      );
      expect(meta.bufferedBytes, greaterThan(0));

      final file = File(meta.filePath);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), equals(meta.bufferedBytes));

      // 3. Verify audio file contains valid audio header (ID3 or MPEG sync)
      final headerBytes = file.openSync().readSync(4);
      final isId3 =
          headerBytes[0] == 0x49 &&
          headerBytes[1] == 0x44 &&
          headerBytes[2] == 0x33; // 'ID3'
      final isMpeg =
          headerBytes[0] == 0xFF &&
          (headerBytes[1] & 0xE0) == 0xE0; // MPEG sync
      expect(
        isId3 || isMpeg,
        isTrue,
        reason: 'Downloaded file must start with valid MP3 header',
      );

      // 4. Verify PrebufferedAudioSource can slice and serve local prebuffer
      final source = PrebufferedAudioSource(
        trackId: trackId,
        remoteUri: Uri.parse(streamUrl),
        prebufferedFile: file,
        prebufferedBytes: meta.bufferedBytes,
        totalContentLength: meta.totalBytes,
      );

      final slice = await source.request(0, 1024);
      expect(slice.contentLength, equals(1024));
      final bytes = await slice.stream.expand((chunk) => chunk).toList();
      expect(bytes.length, equals(1024));
      expect(bytes.sublist(0, 4), equals(headerBytes));
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
