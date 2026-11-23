import 'package:audifi/core/errors/app_exception.dart';
import 'package:audifi/features/playback/data/datasources/next_track_url_cache.dart';
import 'package:audifi/features/playback/data/datasources/queue_local_data_source.dart';
import 'package:audifi/features/playback/data/datasources/stream_remote_data_source.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class MockStreamRemoteDataSource implements StreamRemoteDataSource {
  int callCount = 0;
  String? lastTrackId;
  CancelToken? lastCancelToken;
  bool shouldThrowCancellation = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> getStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    callCount++;
    lastTrackId = trackId;
    lastCancelToken = cancelToken;

    if (shouldThrowCancellation || cancelToken?.isCancelled == true) {
      throw const CancellationException();
    }

    return 'https://creatornode.audius.co/tracks/$trackId.mp3';
  }
}

class FakeQueueLocalDataSource implements QueueLocalDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> saveQueue({
    required List<Track> tracks,
    required int currentIndex,
  }) async {}

  @override
  Future<({List<Track> tracks, int currentIndex})?> restoreQueue() async =>
      null;

  @override
  Future<void> clearQueue() async {}
}

void main() {
  group('PlaybackRepositoryImpl', () {
    late MockStreamRemoteDataSource remoteDataSource;
    late FakeQueueLocalDataSource localDataSource;
    late NextTrackUrlCache predictionCache;
    late PlaybackRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockStreamRemoteDataSource();
      localDataSource = FakeQueueLocalDataSource();
      predictionCache = NextTrackUrlCache();
      repository = PlaybackRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        predictionCache: predictionCache,
      );
    });

    test('resolveStreamUrl fetches from remote on cold call and does not cache without prefetch', () async {
      final url = await repository.resolveStreamUrl('track_1');

      expect(url, equals('https://creatornode.audius.co/tracks/track_1.mp3'));
      expect(remoteDataSource.callCount, equals(1));
      expect(predictionCache.has('track_1'), isFalse);
    });

    test(
      'resolveStreamUrl consumes cached URL on cache hit without network call',
      () async {
        predictionCache.put('track_2', 'https://cached.audius.co/track_2.mp3');

        expect(repository.hasPrediction('track_2'), isTrue);

        final url = await repository.resolveStreamUrl('track_2');

        expect(url, equals('https://cached.audius.co/track_2.mp3'));
        expect(
          remoteDataSource.callCount,
          equals(0),
        ); // Zero remote network calls
        // Consumed single-use cache
        expect(repository.hasPrediction('track_2'), isFalse);
      },
    );

    test('prefetchStreamUrl warms single-slot cache in background', () async {
      expect(predictionCache.has('track_upcoming'), isFalse);

      await repository.prefetchStreamUrl('track_upcoming');

      expect(predictionCache.has('track_upcoming'), isTrue);
      expect(remoteDataSource.callCount, equals(1));

      // Subsequent resolveStreamUrl consumes cache
      final url = await repository.resolveStreamUrl('track_upcoming');
      expect(
        url,
        equals('https://creatornode.audius.co/tracks/track_upcoming.mp3'),
      );
      expect(remoteDataSource.callCount, equals(1)); // Still 1
      expect(predictionCache.has('track_upcoming'), isFalse);
    });

    test(
      'prefetchStreamUrl avoids duplicate requests if track is already cached',
      () async {
        predictionCache.put(
          'track_duplicate',
          'https://cached.audius.co/track_duplicate.mp3',
        );

        await repository.prefetchStreamUrl('track_duplicate');

        expect(remoteDataSource.callCount, equals(0));
      },
    );

    test('invalidatePrediction clears cached prediction', () async {
      predictionCache.put(
        'track_invalidate',
        'https://cached.audius.co/track_invalidate.mp3',
      );
      expect(repository.hasPrediction('track_invalidate'), isTrue);

      repository.invalidatePrediction(reason: 'queue_modified');

      expect(repository.hasPrediction('track_invalidate'), isFalse);
    });

    test(
      'resolveStreamUrl propagates CancelToken to remote data source',
      () async {
        final cancelToken = CancelToken();
        cancelToken.cancel('skip');

        expect(
          () => repository.resolveStreamUrl(
            'track_cancel',
            cancelToken: cancelToken,
          ),
          throwsA(isA<CancellationException>()),
        );
      },
    );
  });
}
