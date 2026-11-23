import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../playlists/data/repositories/playlist_repository_impl.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../playlists/domain/repositories/playlist_repository.dart';

/// Riverpod controller managing trending playlists on Audius.
class TrendingPlaylistsController extends AsyncNotifier<List<Playlist>> {
  @override
  FutureOr<List<Playlist>> build() {
    return _fetchTrending();
  }

  Future<List<Playlist>> _fetchTrending() async {
    try {
      final PlaylistRepository repository = ref.watch(
        playlistRepositoryProvider,
      );
      return await repository.getTrendingPlaylists(limit: 20);
    } catch (error) {
      throw ErrorMapper.mapToFailure(error);
    }
  }

  /// Forces a fresh reload of trending playlists.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTrending());
  }
}

/// Provider for [TrendingPlaylistsController].
final trendingPlaylistsControllerProvider =
    AsyncNotifierProvider<TrendingPlaylistsController, List<Playlist>>(
      TrendingPlaylistsController.new,
    );
