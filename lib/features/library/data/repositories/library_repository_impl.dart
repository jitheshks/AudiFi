import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../albums/domain/entities/album.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../domain/entities/user_library.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_local_data_source.dart';

/// Concrete [LibraryRepository] managing local user collections via [LibraryLocalDataSource].
class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl({required this.localDataSource});

  final LibraryLocalDataSource localDataSource;

  @override
  Future<UserLibrary> getLibrary() async {
    final results = await Future.wait([
      localDataSource.getLikedTracks(),
      localDataSource.getSavedAlbums(),
      localDataSource.getSavedPlaylists(),
      localDataSource.getFollowedArtists(),
    ]);

    return UserLibrary(
      likedTracks: results[0] as List<Track>,
      savedAlbums: results[1] as List<Album>,
      savedPlaylists: results[2] as List<Playlist>,
      followedArtists: results[3] as List<User>,
    );
  }

  @override
  Future<void> toggleLikeTrack(Track track) async {
    final tracks = await localDataSource.getLikedTracks();
    final exists = tracks.any((t) => t.id == track.id);
    final updated = exists
        ? tracks.where((t) => t.id != track.id).toList()
        : [track, ...tracks];

    AppLogger.info(
      '${exists ? "Unliked" : "Liked"} track: "${track.title}"',
      tag: 'LibraryRepository',
    );
    await localDataSource.saveLikedTracks(updated);
  }

  @override
  Future<void> toggleSaveAlbum(Album album) async {
    final albums = await localDataSource.getSavedAlbums();
    final exists = albums.any((a) => a.id == album.id);
    final updated = exists
        ? albums.where((a) => a.id != album.id).toList()
        : [album, ...albums];

    AppLogger.info(
      '${exists ? "Removed" : "Saved"} album: "${album.title}"',
      tag: 'LibraryRepository',
    );
    await localDataSource.saveSavedAlbums(updated);
  }

  @override
  Future<void> toggleSavePlaylist(Playlist playlist) async {
    final playlists = await localDataSource.getSavedPlaylists();
    final exists = playlists.any((p) => p.id == playlist.id);
    final updated = exists
        ? playlists.where((p) => p.id != playlist.id).toList()
        : [playlist, ...playlists];

    AppLogger.info(
      '${exists ? "Removed" : "Saved"} playlist: "${playlist.playlistName}"',
      tag: 'LibraryRepository',
    );
    await localDataSource.saveSavedPlaylists(updated);
  }

  @override
  Future<void> toggleFollowArtist(User artist) async {
    final artists = await localDataSource.getFollowedArtists();
    final exists = artists.any((u) => u.id == artist.id);
    final updated = exists
        ? artists.where((u) => u.id != artist.id).toList()
        : [artist, ...artists];

    AppLogger.info(
      '${exists ? "Unfollowed" : "Followed"} artist: "${artist.name}"',
      tag: 'LibraryRepository',
    );
    await localDataSource.saveFollowedArtists(updated);
  }

  @override
  Future<void> clearLibrary() async {
    AppLogger.info('Clearing all local library data', tag: 'LibraryRepository');
    await localDataSource.clearAll();
  }
}

/// Provider for [LibraryRepository].
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final localDataSource = ref.watch(libraryLocalDataSourceProvider);
  return LibraryRepositoryImpl(localDataSource: localDataSource);
});
