import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/artwork.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../data/datasources/playlist_local_data_source.dart';
import '../../domain/entities/playlist.dart';

/// Riverpod controller managing user-created custom playlists.
class CustomPlaylistsNotifier extends Notifier<List<Playlist>> {
  PlaylistLocalDataSource get _dataSource =>
      ref.read(playlistLocalDataSourceProvider);

  @override
  List<Playlist> build() {
    unawaited(_loadPlaylists());
    return const [];
  }

  Future<void> _loadPlaylists() async {
    final playlists = await _dataSource.getCustomPlaylists();
    if (state.isEmpty) {
      state = playlists;
    }
  }

  Artwork? _deriveArtwork(List<Track> tracks) {
    for (final track in tracks) {
      if (track.artwork != null &&
          track.artwork!.primaryUrl != null &&
          track.artwork!.primaryUrl!.isNotEmpty) {
        return track.artwork;
      }
    }
    return null;
  }

  /// Creates a new custom playlist and persists it to local storage.
  Future<Playlist> createPlaylist(
    String name, {
    String? description,
    List<Track>? initialTracks,
  }) async {
    final trimmedName = name.trim();
    final finalName = trimmedName.isNotEmpty ? trimmedName : 'My Playlist';
    final tracks = initialTracks != null
        ? List<Track>.from(initialTracks)
        : <Track>[];
    final artwork = _deriveArtwork(tracks);

    final newPlaylist = Playlist(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      playlistName: finalName,
      description: description?.trim().isNotEmpty == true
          ? description!.trim()
          : null,
      trackCount: tracks.length,
      tracks: tracks,
      artwork: artwork,
      user: const User(id: 'local_user', name: 'You', handle: 'you'),
    );

    state = [newPlaylist, ...state];
    await _dataSource.saveCustomPlaylists(state);
    return newPlaylist;
  }

  /// Renames an existing playlist with ID [playlistId].
  Future<void> renamePlaylist(String playlistId, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) return;

    state = state.map((p) {
      if (p.id == playlistId) {
        return Playlist(
          id: p.id,
          playlistName: trimmedName,
          description: p.description,
          trackCount: p.trackCount,
          tracks: p.tracks,
          artwork: p.artwork,
          user: p.user,
          isAlbum: p.isAlbum,
          isPrivate: p.isPrivate,
          totalPlayCount: p.totalPlayCount,
          favoriteCount: p.favoriteCount,
          repostCount: p.repostCount,
          permalink: p.permalink,
          releaseDate: p.releaseDate,
        );
      }
      return p;
    }).toList();

    await _dataSource.saveCustomPlaylists(state);
  }

  /// Permanently deletes the playlist with ID [playlistId].
  Future<void> deletePlaylist(String playlistId) async {
    state = state.where((p) => p.id != playlistId).toList();
    await _dataSource.saveCustomPlaylists(state);
  }

  /// Adds [track] to the custom playlist with [playlistId].
  /// Returns `true` if added, or `false` if already in the playlist.
  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    final index = state.indexWhere((p) => p.id == playlistId);
    if (index < 0) return false;

    final target = state[index];
    final currentTracks = List<Track>.from(target.tracks ?? const []);
    if (currentTracks.any((t) => t.id == track.id)) {
      return false; // Already in playlist
    }

    currentTracks.add(track);
    final updatedArtwork = target.artwork ?? _deriveArtwork(currentTracks);

    final updated = Playlist(
      id: target.id,
      playlistName: target.playlistName,
      description: target.description,
      trackCount: currentTracks.length,
      tracks: currentTracks,
      artwork: updatedArtwork,
      user: target.user,
      isAlbum: target.isAlbum,
      isPrivate: target.isPrivate,
      totalPlayCount: target.totalPlayCount,
      favoriteCount: target.favoriteCount,
      repostCount: target.repostCount,
      permalink: target.permalink,
      releaseDate: target.releaseDate,
    );

    final updatedList = List<Playlist>.from(state);
    updatedList[index] = updated;
    state = updatedList;

    await _dataSource.saveCustomPlaylists(state);
    return true;
  }

  /// Removes [trackId] from the playlist with [playlistId].
  Future<void> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    final index = state.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;

    final target = state[index];
    final currentTracks = List<Track>.from(target.tracks ?? const [])
      ..removeWhere((t) => t.id == trackId);
    final updatedArtwork = _deriveArtwork(currentTracks);

    final updated = Playlist(
      id: target.id,
      playlistName: target.playlistName,
      description: target.description,
      trackCount: currentTracks.length,
      tracks: currentTracks,
      artwork: updatedArtwork,
      user: target.user,
      isAlbum: target.isAlbum,
      isPrivate: target.isPrivate,
      totalPlayCount: target.totalPlayCount,
      favoriteCount: target.favoriteCount,
      repostCount: target.repostCount,
      permalink: target.permalink,
      releaseDate: target.releaseDate,
    );

    final updatedList = List<Playlist>.from(state);
    updatedList[index] = updated;
    state = updatedList;

    await _dataSource.saveCustomPlaylists(state);
  }

  /// Reorders a track within a custom playlist.
  Future<void> reorderTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final index = state.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;

    final target = state[index];
    final currentTracks = List<Track>.from(target.tracks ?? const []);
    if (oldIndex < 0 || oldIndex >= currentTracks.length) return;
    if (newIndex < 0 || newIndex > currentTracks.length) return;

    var dest = newIndex;
    if (dest > oldIndex) {
      dest -= 1;
    }

    final item = currentTracks.removeAt(oldIndex);
    currentTracks.insert(dest, item);
    final updatedArtwork = _deriveArtwork(currentTracks);

    final updated = Playlist(
      id: target.id,
      playlistName: target.playlistName,
      description: target.description,
      trackCount: currentTracks.length,
      tracks: currentTracks,
      artwork: updatedArtwork,
      user: target.user,
      isAlbum: target.isAlbum,
      isPrivate: target.isPrivate,
      totalPlayCount: target.totalPlayCount,
      favoriteCount: target.favoriteCount,
      repostCount: target.repostCount,
      permalink: target.permalink,
      releaseDate: target.releaseDate,
    );

    final updatedList = List<Playlist>.from(state);
    updatedList[index] = updated;
    state = updatedList;

    await _dataSource.saveCustomPlaylists(state);
  }
}

/// Provider managing custom user-created playlists.
final customPlaylistsProvider =
    NotifierProvider<CustomPlaylistsNotifier, List<Playlist>>(
      CustomPlaylistsNotifier.new,
    );
