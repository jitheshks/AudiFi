import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/features/playback/data/services/audio_prebuffer_service.dart';

class _FakeResponseBodyAdapter implements HttpClientAdapter {
  _FakeResponseBodyAdapter({
    required this.statusCode,
    required this.byteStream,
    this.headers = const {},
  });

  final int statusCode;
  final Stream<Uint8List> byteStream;
  final Map<String, List<String>> headers;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody(byteStream, statusCode, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AudioPrebufferService', () {
    late Directory tempDir;
    late Dio rawDio;
    late DioClient dioClient;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('prebuffer_test_');
      rawDio = Dio();
      dioClient = DioClient(rawDio: rawDio);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('strictly enforces byte limit when server returns 200 OK with excessive data', () async {
      // 1.5 MB generated stream
      final largeBytes = Uint8List(1500 * 1024);
      final stream = Stream<Uint8List>.fromIterable([largeBytes]);

      rawDio.httpClientAdapter = _FakeResponseBodyAdapter(
        statusCode: 200,
        byteStream: stream,
        headers: {
          'content-type': ['audio/mpeg'],
          'content-length': ['${largeBytes.length}'],
        },
      );

      final service = AudioPrebufferService(
        dioClient: dioClient,
        targetBytes: 768 * 1024,
        customStorageDirectory: tempDir,
      );

      final meta = await service.prebufferTrack(
        'track_large',
        'https://audius.co/stream',
      );

      expect(meta, isNotNull);
      expect(meta!.trackId, equals('track_large'));
      expect(meta.bufferedBytes, equals(768 * 1024));
      expect(File(meta.filePath).existsSync(), isTrue);
      expect(File(meta.filePath).lengthSync(), equals(768 * 1024));
      expect(meta.isComplete, isTrue);

      // Verify no orphaned .part file exists
      final partFile = File('${tempDir.path}/track_large.part');
      expect(partFile.existsSync(), isFalse);
    });

    test('successfully stores prebuffer with 206 Partial Content and Content-Range', () async {
      final chunkBytes = Uint8List(500 * 1024);
      final stream = Stream<Uint8List>.fromIterable([chunkBytes]);

      rawDio.httpClientAdapter = _FakeResponseBodyAdapter(
        statusCode: 206,
        byteStream: stream,
        headers: {
          'content-type': ['audio/mpeg'],
          'content-range': ['bytes 0-511999/4000000'],
        },
      );

      final service = AudioPrebufferService(
        dioClient: dioClient,
        targetBytes: 500 * 1024,
        customStorageDirectory: tempDir,
      );

      final meta = await service.prebufferTrack(
        'track_partial',
        'https://audius.co/stream',
      );

      expect(meta, isNotNull);
      expect(meta!.bufferedBytes, equals(500 * 1024));
      expect(meta.totalBytes, equals(4000000));
      expect(meta.isValid, isTrue);
    });

    test('handles premature EOF on short track gracefully', () async {
      final shortBytes = Uint8List(128 * 1024);
      final stream = Stream<Uint8List>.fromIterable([shortBytes]);

      rawDio.httpClientAdapter = _FakeResponseBodyAdapter(
        statusCode: 200,
        byteStream: stream,
        headers: {
          'content-type': ['audio/mpeg'],
        },
      );

      final service = AudioPrebufferService(
        dioClient: dioClient,
        targetBytes: 768 * 1024,
        customStorageDirectory: tempDir,
      );

      final meta = await service.prebufferTrack(
        'track_short',
        'https://audius.co/stream',
      );

      expect(meta, isNotNull);
      expect(meta!.bufferedBytes, equals(128 * 1024));
      expect(meta.isComplete, isFalse);
      expect(meta.isValid, isTrue);
    });

    test('cancelling prebuffer cleans up partial file immediately', () async {
      final controller = StreamController<Uint8List>();
      rawDio.httpClientAdapter = _FakeResponseBodyAdapter(
        statusCode: 200,
        byteStream: controller.stream,
      );

      final service = AudioPrebufferService(
        dioClient: dioClient,
        targetBytes: 768 * 1024,
        customStorageDirectory: tempDir,
      );

      final cancelToken = CancelToken();
      final future = service.prebufferTrack(
        'track_cancelled',
        'https://audius.co/stream',
        cancelToken: cancelToken,
      );

      // Yield initial chunk
      controller.add(Uint8List(64 * 1024));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Cancel while download is in-flight
      cancelToken.cancel('user_skipped');
      controller.close();

      final result = await future;
      expect(result, isNull);

      final partFile = File('${tempDir.path}/track_cancelled.part');
      final bufFile = File('${tempDir.path}/track_cancelled.buf');
      expect(partFile.existsSync(), isFalse);
      expect(bufFile.existsSync(), isFalse);
      expect(service.hasPrebuffer('track_cancelled'), isFalse);
    });

    test('evicts oldest prebuffer when cache exceeds max capacity', () async {
      final bytes = Uint8List(64 * 1024);
      rawDio.httpClientAdapter = _FakeResponseBodyAdapter(
        statusCode: 200,
        byteStream: Stream<Uint8List>.fromIterable([bytes]),
      );

      final service = AudioPrebufferService(
        dioClient: dioClient,
        targetBytes: 64 * 1024,
        customStorageDirectory: tempDir,
      );

      await service.prebufferTrack('track_1', 'https://audius.co/1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      rawDio.httpClientAdapter = _FakeResponseBodyAdapter(
        statusCode: 200,
        byteStream: Stream<Uint8List>.fromIterable([bytes]),
      );
      await service.prebufferTrack('track_2', 'https://audius.co/2');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(service.hasPrebuffer('track_1'), isTrue);
      expect(service.hasPrebuffer('track_2'), isTrue);

      // Adding 3rd track must evict oldest (track_1)
      rawDio.httpClientAdapter = _FakeResponseBodyAdapter(
        statusCode: 200,
        byteStream: Stream<Uint8List>.fromIterable([bytes]),
      );
      await service.prebufferTrack('track_3', 'https://audius.co/3');

      expect(service.hasPrebuffer('track_1'), isFalse);
      expect(service.hasPrebuffer('track_2'), isTrue);
      expect(service.hasPrebuffer('track_3'), isTrue);
    });
  });
}
