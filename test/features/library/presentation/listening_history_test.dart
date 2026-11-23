import 'package:audifi/core/storage/storage_providers.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/library/presentation/controllers/listening_history_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListeningHistoryNotifier statistics and intelligence', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          ...createStubRepositoryOverrides(),
          sharedPreferencesAsyncProvider.overrideWithValue(Future.value(prefs)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    const t1 = Track(
      id: 't1',
      title: 'Neon Odyssey',
      genre: 'Electronic',
      user: User(id: 'u1', name: 'Synth Master', handle: 'synthmaster'),
    );

    const t2 = Track(
      id: 't2',
      title: 'Retro Sunset',
      genre: 'Electronic',
      user: User(id: 'u1', name: 'Synth Master', handle: 'synthmaster'),
    );

    const t3 = Track(
      id: 't3',
      title: 'Acoustic Morning',
      genre: 'Folk',
      user: User(id: 'u2', name: 'Acoustic Solo', handle: 'acousticsolo'),
    );

    test('increments play counts and calculates statistics correctly', () async {
      final container = createContainer();
      final notifier = container.read(listeningHistoryProvider.notifier);

      // Play t1 twice, t2 once, t3 three times
      await notifier.addTrack(t1);
      await notifier.addTrack(t1);
      await notifier.addTrack(t2);
      await notifier.addTrack(t3);
      await notifier.addTrack(t3);
      await notifier.addTrack(t3);

      expect(notifier.getPlayCount('t1'), 2);
      expect(notifier.getPlayCount('t2'), 1);
      expect(notifier.getPlayCount('t3'), 3);
      expect(notifier.totalPlays, 6);

      // Most played track should be t3
      final mostPlayed = notifier.getMostPlayedTracks();
      expect(mostPlayed.first.id, 't3');

      // Top genre should be Electronic (3 plays) vs Folk (3 plays)
      expect(notifier.getFavoriteGenre(), isNotNull);

      // Top artist should be Synth Master (3 plays) or Acoustic Solo (3 plays)
      final topArtists = notifier.getTopArtists();
      expect(topArtists.length, 2);
    });

    test('clearHistory clears both tracks and play counts', () async {
      final container = createContainer();
      final notifier = container.read(listeningHistoryProvider.notifier);

      await notifier.addTrack(t1);
      expect(notifier.totalPlays, 1);

      await notifier.clearHistory();
      expect(container.read(listeningHistoryProvider), isEmpty);
      expect(notifier.totalPlays, 0);
    });
  });
}
