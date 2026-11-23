import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import 'custom_playlists_controller.dart';

/// Aggregated state containing playlist metadata and its track listing.
class PlaylistDetailState {
  const PlaylistDetailState({required this.playlist, required this.tracks});

  /// Metadata for the playlist.
  final Playlist playlist;

  /// Ordered list of tracks contained within the playlist.
  final List<Track> tracks;
}

/// Riverpod FutureProvider family fetching playlist details and track listing.
final playlistDetailProvider = FutureProvider.autoDispose
    .family<PlaylistDetailState, String>((ref, playlistId) async {
      // 1. Check user-created custom playlists first.
      final customPlaylists = ref.watch(customPlaylistsProvider);
      final customMatch = customPlaylists
          .where((p) => p.id == playlistId)
          .firstOrNull;
      if (customMatch != null) {
        return PlaylistDetailState(
          playlist: customMatch,
          tracks: customMatch.tracks ?? const [],
        );
      }

      // 2. Otherwise query remote repository.
      final PlaylistRepository repository = ref.watch(
        playlistRepositoryProvider,
      );

      final playlist = await repository.getPlaylist(playlistId);
      if (playlist == null) {
        throw const ApiException(
          message: 'Playlist not found',
          type: ApiExceptionType.notFound,
          statusCode: 404,
        );
      }

      final tracks = (playlist.tracks != null && playlist.tracks!.isNotEmpty)
          ? playlist.tracks!
          : await repository.getPlaylistTracks(playlistId);

      return PlaylistDetailState(playlist: playlist, tracks: tracks);
    });
