import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../albums/domain/entities/album.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/entities/user_library.dart';
import '../../domain/repositories/library_repository.dart';

/// Riverpod controller managing the local user library and collections state.
class LibraryController extends Notifier<UserLibrary> {
  LibraryRepository get _repository => ref.read(libraryRepositoryProvider);

  @override
  UserLibrary build() {
    unawaited(_loadLibrary());
    return UserLibrary.empty;
  }

  Future<void> _loadLibrary() async {
    final lib = await _repository.getLibrary();
    if (state == UserLibrary.empty) {
      state = lib;
    } else {
      state = state.copyWith(
        likedTracks: [
          ...state.likedTracks,
          ...lib.likedTracks.where((lt) => !state.isTrackLiked(lt.id)),
        ],
        savedAlbums: [
          ...state.savedAlbums,
          ...lib.savedAlbums.where((sa) => !state.isAlbumSaved(sa.id)),
        ],
        savedPlaylists: [
          ...state.savedPlaylists,
          ...lib.savedPlaylists.where((sp) => !state.isPlaylistSaved(sp.id)),
        ],
        followedArtists: [
          ...state.followedArtists,
          ...lib.followedArtists.where((fa) => !state.isArtistFollowed(fa.id)),
        ],
      );
    }
  }

  /// Toggles like status for [track] with optimistic state mutation.
  Future<void> toggleLikeTrack(Track track) async {
    final exists = state.isTrackLiked(track.id);
    final updated = exists
        ? state.likedTracks.where((t) => t.id != track.id).toList()
        : [track, ...state.likedTracks.where((t) => t.id != track.id)];

    state = state.copyWith(likedTracks: updated);
    await _repository.toggleLikeTrack(track);
  }

  /// Toggles saved status for [album] with optimistic state mutation.
  Future<void> toggleSaveAlbum(Album album) async {
    final exists = state.isAlbumSaved(album.id);
    final updated = exists
        ? state.savedAlbums.where((a) => a.id != album.id).toList()
        : [album, ...state.savedAlbums.where((a) => a.id != album.id)];

    state = state.copyWith(savedAlbums: updated);
    await _repository.toggleSaveAlbum(album);
  }

  /// Toggles saved status for [playlist] with optimistic state mutation.
  Future<void> toggleSavePlaylist(Playlist playlist) async {
    final exists = state.isPlaylistSaved(playlist.id);
    final updated = exists
        ? state.savedPlaylists.where((p) => p.id != playlist.id).toList()
        : [playlist, ...state.savedPlaylists.where((p) => p.id != playlist.id)];

    state = state.copyWith(savedPlaylists: updated);
    await _repository.toggleSavePlaylist(playlist);
  }

  /// Toggles follow status for [artist] with optimistic state mutation.
  Future<void> toggleFollowArtist(User artist) async {
    final exists = state.isArtistFollowed(artist.id);
    final updated = exists
        ? state.followedArtists.where((u) => u.id != artist.id).toList()
        : [artist, ...state.followedArtists.where((u) => u.id != artist.id)];

    state = state.copyWith(followedArtists: updated);
    await _repository.toggleFollowArtist(artist);
  }

  /// Removes an individual liked track.
  Future<void> removeLikedTrack(String trackId) async {
    final track = state.likedTracks.where((t) => t.id == trackId).firstOrNull;
    if (track != null) {
      await toggleLikeTrack(track);
    }
  }

  /// Removes an individual saved album.
  Future<void> removeSavedAlbum(String albumId) async {
    final album = state.savedAlbums.where((a) => a.id == albumId).firstOrNull;
    if (album != null) {
      await toggleSaveAlbum(album);
    }
  }

  /// Removes an individual saved playlist.
  Future<void> removeSavedPlaylist(String playlistId) async {
    final playlist = state.savedPlaylists
        .where((p) => p.id == playlistId)
        .firstOrNull;
    if (playlist != null) {
      await toggleSavePlaylist(playlist);
    }
  }

  /// Unfollows an individual artist.
  Future<void> unfollowArtist(String artistId) async {
    final artist = state.followedArtists
        .where((u) => u.id == artistId)
        .firstOrNull;
    if (artist != null) {
      await toggleFollowArtist(artist);
    }
  }

  /// Clears all library items.
  Future<void> clearLibrary() async {
    state = UserLibrary.empty;
    await _repository.clearLibrary();
  }
}

/// Provider for [LibraryController].
final libraryControllerProvider =
    NotifierProvider<LibraryController, UserLibrary>(LibraryController.new);
