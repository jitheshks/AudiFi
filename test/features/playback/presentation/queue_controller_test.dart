import 'package:dio/dio.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/domain/repositories/playback_repository.dart';
import 'package:audifi/features/playback/presentation/controllers/queue_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlaybackRepository implements PlaybackRepository {
  List<Track>? savedTracks;
  int? savedIndex;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async => 'https://mock.com/$trackId.mp3';

  @override
  Future<void> prefetchStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {}

  @override
  String? get currentPredictedTrackId => null;

  @override
  bool hasPrediction(String trackId) => false;

  @override
  void invalidatePrediction({String? reason}) {}

  @override
  Future<void> saveQueue({
    required List<Track> tracks,
    required int currentIndex,
  }) async {
    savedTracks = tracks;
    savedIndex = currentIndex;
  }

  @override
  Future<({List<Track> tracks, int currentIndex})?> restoreQueue() async {
    if (savedTracks == null) return null;
    return (tracks: savedTracks!, currentIndex: savedIndex ?? 0);
  }

  @override
  Future<void> clearSavedQueue() async {
    savedTracks = null;
    savedIndex = null;
  }
}

void main() {
  group('QueueController', () {
    late ProviderContainer container;
    late FakePlaybackRepository repo;

    setUp(() {
      repo = FakePlaybackRepository();
      container = ProviderContainer(
        overrides: [playbackRepositoryProvider.overrideWithValue(repo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    const t1 = Track(id: 't1', title: 'Track 1');
    const t2 = Track(id: 't2', title: 'Track 2');
    const t3 = Track(id: 't3', title: 'Track 3');

    test('initial state is empty', () {
      final queue = container.read(queueControllerProvider);
      expect(queue.isEmpty, isTrue);
      expect(queue.currentTrack, isNull);
    });

    test('setQueue populates items and current index', () {
      final controller = container.read(queueControllerProvider.notifier);
      controller.setQueue([t1, t2, t3], startIndex: 1);

      final queue = container.read(queueControllerProvider);
      expect(queue.length, equals(3));
      expect(queue.currentIndex, equals(1));
      expect(queue.currentTrack?.id, equals('t2'));
      expect(repo.savedTracks?.length, equals(3));
      expect(repo.savedIndex, equals(1));
    });

    test('playNext inserts track right after current index', () {
      final controller = container.read(queueControllerProvider.notifier);
      controller.setQueue([t1, t3], startIndex: 0);
      controller.playNext(t2);

      final queue = container.read(queueControllerProvider);
      expect(queue.items.map((t) => t.id).toList(), equals(['t1', 't2', 't3']));
      expect(queue.currentIndex, equals(0));
    });

    test('addToQueue appends track to end', () {
      final controller = container.read(queueControllerProvider.notifier);
      controller.setQueue([t1, t2], startIndex: 0);
      controller.addToQueue(t3);

      final queue = container.read(queueControllerProvider);
      expect(queue.items.last.id, equals('t3'));
      expect(queue.length, equals(3));
    });

    test('removeFromQueue removes item and adjusts currentIndex', () {
      final controller = container.read(queueControllerProvider.notifier);
      controller.setQueue([t1, t2, t3], startIndex: 2);

      // Remove item at index 0 (before current index)
      controller.removeFromQueue(0);
      var queue = container.read(queueControllerProvider);
      expect(queue.length, equals(2));
      expect(queue.currentIndex, equals(1));
      expect(queue.currentTrack?.id, equals('t3'));

      // Remove current item
      controller.removeFromQueue(1);
      queue = container.read(queueControllerProvider);
      expect(queue.length, equals(1));
      expect(queue.currentIndex, equals(0));
      expect(queue.currentTrack?.id, equals('t2'));
    });

    test(
      'reorderQueue moves item while maintaining active track reference',
      () {
        final controller = container.read(queueControllerProvider.notifier);
        controller.setQueue([t1, t2, t3], startIndex: 0); // t1 is active

        // Move t1 from index 0 to index 3 (end)
        controller.reorderQueue(0, 3);
        final queue = container.read(queueControllerProvider);
        expect(
          queue.items.map((t) => t.id).toList(),
          equals(['t2', 't3', 't1']),
        );
        expect(queue.currentTrack?.id, equals('t1'));
        expect(queue.currentIndex, equals(2));
      },
    );

    test('clearQueue retains only the currently active track', () {
      final controller = container.read(queueControllerProvider.notifier);
      controller.setQueue([t1, t2, t3], startIndex: 1);
      controller.clearQueue();

      final queue = container.read(queueControllerProvider);
      expect(queue.length, equals(1));
      expect(queue.currentTrack?.id, equals('t2'));
      expect(queue.currentIndex, equals(0));
    });

    test(
      'toggleShuffle maintains current track at position 0 in shuffle order',
      () {
        final controller = container.read(queueControllerProvider.notifier);
        controller.setQueue([t1, t2, t3], startIndex: 1); // t2 is current

        controller.toggleShuffle();
        final queue = container.read(queueControllerProvider);
        expect(queue.isShuffleEnabled, isTrue);
        expect(queue.effectiveIndices.first, equals(1));
        expect(queue.effectiveIndices.length, equals(3));
        expect(queue.currentTrack?.id, equals('t2'));
      },
    );

    test('advanceToNext and stepToPrevious traverse queue order', () {
      final controller = container.read(queueControllerProvider.notifier);
      controller.setQueue([t1, t2, t3], startIndex: 0);

      final next = controller.advanceToNext();
      expect(next?.id, equals('t2'));

      final next2 = controller.advanceToNext();
      expect(next2?.id, equals('t3'));

      final end = controller.advanceToNext(loop: false);
      expect(end, isNull);

      final prev = controller.stepToPrevious();
      expect(prev?.id, equals('t2'));
    });

    test(
      'Queue action semantics: Play Next inserts right after playing track (A -> X -> B -> C -> D)',
      () {
        const a = Track(id: 'A', title: 'Track A');
        const b = Track(id: 'B', title: 'Track B');
        const c = Track(id: 'C', title: 'Track C');
        const d = Track(id: 'D', title: 'Track D');
        const x = Track(id: 'X', title: 'Track X');

        final controller = container.read(queueControllerProvider.notifier);
        // A is actively playing at index 0
        controller.setQueue([a, b, c, d], startIndex: 0);

        // Selecting X -> Play Next
        controller.playNext(x);

        final queue = container.read(queueControllerProvider);
        expect(
          queue.items.map((t) => t.id).toList(),
          equals(['A', 'X', 'B', 'C', 'D']),
        );
        // Playing track A remains active at index 0
        expect(queue.currentIndex, equals(0));
        expect(queue.currentTrack?.id, equals('A'));
      },
    );

    test(
      'Queue action semantics: Add to Queue appends to queue end (A -> B -> C -> D -> X)',
      () {
        const a = Track(id: 'A', title: 'Track A');
        const b = Track(id: 'B', title: 'Track B');
        const c = Track(id: 'C', title: 'Track C');
        const d = Track(id: 'D', title: 'Track D');
        const x = Track(id: 'X', title: 'Track X');

        final controller = container.read(queueControllerProvider.notifier);
        controller.setQueue([a, b, c, d], startIndex: 0);

        // Selecting X -> Add to Queue
        controller.addToQueue(x);

        final queue = container.read(queueControllerProvider);
        expect(
          queue.items.map((t) => t.id).toList(),
          equals(['A', 'B', 'C', 'D', 'X']),
        );
        expect(queue.currentIndex, equals(0));
        expect(queue.currentTrack?.id, equals('A'));
      },
    );

    test(
      'Queue action semantics: Adding currently playing track appends duplicate at end without restarting playback',
      () {
        const a = Track(id: 'A', title: 'Track A');
        const b = Track(id: 'B', title: 'Track B');
        const c = Track(id: 'C', title: 'Track C');

        final controller = container.read(queueControllerProvider.notifier);
        controller.setQueue([a, b, c], startIndex: 0); // A is playing

        // Adding current track A to queue
        controller.addToQueue(a);

        final queue = container.read(queueControllerProvider);
        // Duplicate instance of A is at the end: [A, B, C, A]
        expect(
          queue.items.map((t) => t.id).toList(),
          equals(['A', 'B', 'C', 'A']),
        );
        // Current index remains 0, playing track unchanged
        expect(queue.currentIndex, equals(0));
        expect(queue.currentTrack?.id, equals('A'));
        expect(queue.items.length, equals(4));
      },
    );

    test(
      'reorderQueue maintains correct active track index with duplicate tracks',
      () {
        const a1 = Track(id: 'A', title: 'Track A (1)');
        const b = Track(id: 'B', title: 'Track B');
        const c = Track(id: 'C', title: 'Track C');
        const a2 = Track(id: 'A', title: 'Track A (2)');

        final controller = container.read(queueControllerProvider.notifier);
        // Suppose the second instance of A is playing at index 3
        controller.setQueue([a1, b, c, a2], startIndex: 3);

        // Reorder B (index 1) to after C (index 3) -> [a1, c, b, a2]
        controller.reorderQueue(1, 3);

        final queue = container.read(queueControllerProvider);
        // The active track was at index 3, and should remain at index 3
        expect(queue.currentIndex, equals(3));
        expect(queue.currentTrack?.title, equals('Track A (2)'));
      },
    );
  });
}
