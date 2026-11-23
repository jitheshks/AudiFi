import '../../../albums/domain/entities/album.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../tracks/domain/entities/track.dart';

/// Pure domain entity modeling the user's personal collection of liked tracks,
/// saved albums, saved playlists, and followed artists.
class UserLibrary {
  const UserLibrary({
    this.likedTracks = const [],
    this.savedAlbums = const [],
    this.savedPlaylists = const [],
    this.followedArtists = const [],
  });

  final List<Track> likedTracks;
  final List<Album> savedAlbums;
  final List<Playlist> savedPlaylists;
  final List<User> followedArtists;

  static const UserLibrary empty = UserLibrary();

  bool isTrackLiked(String trackId) => likedTracks.any((t) => t.id == trackId);

  bool isAlbumSaved(String albumId) => savedAlbums.any((a) => a.id == albumId);

  bool isPlaylistSaved(String playlistId) =>
      savedPlaylists.any((p) => p.id == playlistId);

  bool isArtistFollowed(String artistId) =>
      followedArtists.any((u) => u.id == artistId);

  UserLibrary copyWith({
    List<Track>? likedTracks,
    List<Album>? savedAlbums,
    List<Playlist>? savedPlaylists,
    List<User>? followedArtists,
  }) {
    return UserLibrary(
      likedTracks: likedTracks ?? this.likedTracks,
      savedAlbums: savedAlbums ?? this.savedAlbums,
      savedPlaylists: savedPlaylists ?? this.savedPlaylists,
      followedArtists: followedArtists ?? this.followedArtists,
    );
  }
}
