import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playlists/domain/entities/playlist.dart';
import 'package:audifi/features/playlists/presentation/controllers/custom_playlists_controller.dart';
import 'package:audifi/features/playlists/presentation/views/playlist_detail_view.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../test_helpers/stub_repositories.dart';

class TestCustomPlaylistsNotifier extends CustomPlaylistsNotifier {
  TestCustomPlaylistsNotifier(this.initialPlaylists);

  final List<Playlist> initialPlaylists;

  @override
  List<Playlist> build() {
    return initialPlaylists;
  }
}

void main() {
  group('PlaylistDetailView', () {
    const t1 = Track(
      id: 't1',
      title: 'Synth Dreams',
      duration: 195,
      user: User(id: 'u1', name: 'Synthwave Artist', handle: 'synthwave'),
    );

    final customPlaylist = Playlist(
      id: 'custom_123',
      playlistName: 'Neon Midnight',
      description: 'Night drive synth tracks',
      trackCount: 1,
      tracks: const [t1],
      user: const User(id: 'local_user', name: 'You', handle: 'you'),
    );

    testWidgets('renders custom playlist details and track listing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...createStubRepositoryOverrides(),
            customPlaylistsProvider.overrideWith(
              () => TestCustomPlaylistsNotifier([customPlaylist]),
            ),
          ],
          child: const MaterialApp(
            home: PlaylistDetailView(playlistId: 'custom_123'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Neon Midnight'), findsOneWidget);
      expect(find.text('By You'), findsOneWidget);
      expect(find.text('1 track'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Synth Dreams'), findsOneWidget);
    });

    testWidgets('renders empty state when custom playlist has no tracks', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final emptyPlaylist = Playlist(
        id: 'custom_empty',
        playlistName: 'Empty Playlist',
        trackCount: 0,
        tracks: const [],
        user: const User(id: 'local_user', name: 'You', handle: 'you'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...createStubRepositoryOverrides(),
            customPlaylistsProvider.overrideWith(
              () => TestCustomPlaylistsNotifier([emptyPlaylist]),
            ),
          ],
          child: const MaterialApp(
            home: PlaylistDetailView(playlistId: 'custom_empty'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Empty Playlist'), findsOneWidget);
      expect(find.text('0 tracks'), findsOneWidget);
      expect(
        find.textContaining('This playlist has no tracks yet'),
        findsOneWidget,
      );
      expect(find.text('Play All'), findsNothing);
    });
  });
}
