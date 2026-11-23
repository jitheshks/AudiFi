import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/data/datasources/queue_local_data_source.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/models/artwork.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('QueueLocalDataSource', () {
    late QueueLocalDataSource dataSource;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dataSource = QueueLocalDataSource(
        prefsAsync: SharedPreferences.getInstance(),
      );
    });

    test('saves and restores queue tracks and current index', () async {
      final tracks = [
        const Track(
          id: 't1',
          title: 'Track 1',
          duration: 180,
          user: User(
            id: 'u1',
            name: 'Artist 1',
            handle: 'art1',
            isVerified: true,
          ),
          artwork: Artwork(small: 'https://img.com/t1.jpg'),
        ),
        const Track(
          id: 't2',
          title: 'Track 2',
          duration: 240,
          user: User(id: 'u2', name: 'Artist 2', handle: 'art2'),
        ),
      ];

      await dataSource.saveQueue(tracks: tracks, currentIndex: 1);

      final restored = await dataSource.restoreQueue();
      expect(restored, isNotNull);
      expect(restored!.currentIndex, equals(1));
      expect(restored.tracks.length, equals(2));
      expect(restored.tracks[0].id, equals('t1'));
      expect(restored.tracks[0].title, equals('Track 1'));
      expect(restored.tracks[0].user?.isVerified, isTrue);
      expect(restored.tracks[1].id, equals('t2'));
    });

    test('clearing queue removes persistent entry', () async {
      final tracks = [const Track(id: 't1', title: 'Track 1')];

      await dataSource.saveQueue(tracks: tracks, currentIndex: 0);
      await dataSource.clearQueue();

      final restored = await dataSource.restoreQueue();
      expect(restored, isNull);
    });

    test('returns null when storage is empty', () async {
      final restored = await dataSource.restoreQueue();
      expect(restored, isNull);
    });
  });
}
