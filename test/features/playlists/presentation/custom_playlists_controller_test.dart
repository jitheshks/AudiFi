import 'package:audifi/core/storage/storage_providers.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playlists/presentation/controllers/custom_playlists_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/models/artwork.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomPlaylistsNotifier', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesAsyncProvider.overrideWithValue(Future.value(prefs)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    const t1 = Track(
      id: 't1',
      title: 'First Track',
      duration: 180,
      artwork: Artwork(
        small: 'https://audius.co/art1.jpg',
        medium: 'https://audius.co/art1.jpg',
        large: 'https://audius.co/art1.jpg',
      ),
      user: User(id: 'u1', name: 'Artist One', handle: 'art1'),
    );

    const t2 = Track(
      id: 't2',
      title: 'Second Track',
      duration: 220,
      user: User(id: 'u2', name: 'Artist Two', handle: 'art2'),
    );

    test('initial state loads empty list', () async {
      final container = createContainer();
      final playlists = container.read(customPlaylistsProvider);
      expect(playlists, isEmpty);
    });

    test('creates playlist with initial track and persists', () async {
      final container = createContainer();
      final notifier = container.read(customPlaylistsProvider.notifier);

      final created = await notifier.createPlaylist(
        'Chill Mix',
        description: 'Late night vibes',
        initialTracks: [t1],
      );

      expect(created.playlistName, 'Chill Mix');
      expect(created.description, 'Late night vibes');
      expect(created.trackCount, 1);
      expect(created.tracks?.first.id, 't1');
      expect(created.artwork?.primaryUrl, 'https://audius.co/art1.jpg');

      final state = container.read(customPlaylistsProvider);
      expect(state.length, 1);
      expect(state.first.id, created.id);
    });

    test('adds, removes and reorders tracks in custom playlist', () async {
      final container = createContainer();
      final notifier = container.read(customPlaylistsProvider.notifier);

      final playlist = await notifier.createPlaylist('Study Session');
      expect(playlist.trackCount, 0);

      // Add track 1
      final added1 = await notifier.addTrackToPlaylist(playlist.id, t1);
      expect(added1, isTrue);

      // Add duplicate track 1 (should return false)
      final addedDup = await notifier.addTrackToPlaylist(playlist.id, t1);
      expect(addedDup, isFalse);

      // Add track 2
      final added2 = await notifier.addTrackToPlaylist(playlist.id, t2);
      expect(added2, isTrue);

      var current = container.read(customPlaylistsProvider).first;
      expect(current.trackCount, 2);
      expect(current.tracks?[0].id, 't1');
      expect(current.tracks?[1].id, 't2');

      // Reorder: move t1 to index 1
      await notifier.reorderTracks(playlist.id, 0, 2);
      current = container.read(customPlaylistsProvider).first;
      expect(current.tracks?[0].id, 't2');
      expect(current.tracks?[1].id, 't1');

      // Remove t2
      await notifier.removeTrackFromPlaylist(playlist.id, 't2');
      current = container.read(customPlaylistsProvider).first;
      expect(current.trackCount, 1);
      expect(current.tracks?[0].id, 't1');
    });

    test('renames and deletes playlist', () async {
      final container = createContainer();
      final notifier = container.read(customPlaylistsProvider.notifier);

      final p = await notifier.createPlaylist('Old Title');
      expect(
        container.read(customPlaylistsProvider).first.playlistName,
        'Old Title',
      );

      await notifier.renamePlaylist(p.id, 'New Title');
      expect(
        container.read(customPlaylistsProvider).first.playlistName,
        'New Title',
      );

      await notifier.deletePlaylist(p.id);
      expect(container.read(customPlaylistsProvider), isEmpty);
    });
  });
}
