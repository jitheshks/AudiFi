import '../../../albums/domain/entities/album.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../tracks/domain/entities/track.dart';
import '../entities/user_library.dart';

/// Pure domain repository contract abstracting user library and personal collection operations.
/// Designed for guest local persistence and ready for future account-synchronized backends.
abstract interface class LibraryRepository {
  /// Loads the entire stored library collection.
  Future<UserLibrary> getLibrary();

  /// Toggles like state for a track.
  Future<void> toggleLikeTrack(Track track);

  /// Toggles save state for an album.
  Future<void> toggleSaveAlbum(Album album);

  /// Toggles save state for a playlist.
  Future<void> toggleSavePlaylist(Playlist playlist);

  /// Toggles follow state for an artist.
  Future<void> toggleFollowArtist(User artist);

  /// Clears all local library content.
  Future<void> clearLibrary();
}
