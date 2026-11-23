import '../../../../shared/models/artwork.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../tracks/domain/entities/track.dart';

/// Pure domain entity representing a commercial album on Audius.
class Album {
  const Album({
    required this.id,
    String? title,
    String? albumName,
    this.description,
    this.trackCount = 0,
    this.totalPlayCount = 0,
    User? artist,
    User? user,
    this.artwork,
    this.tracks,
    this.releaseDate,
    this.permalink,
  }) : albumName = albumName ?? title ?? 'Untitled Album',
       user = user ?? artist;

  /// Unique album ID.
  final String id;

  /// Album title.
  final String albumName;

  /// Alias for [albumName].
  String get title => albumName;

  /// Album description or liner notes.
  final String? description;

  /// Number of tracks in album.
  final int trackCount;

  /// Total play count.
  final int totalPlayCount;

  /// Primary artist who published the album.
  final User? user;

  /// Alias for [user].
  User? get artist => user;

  /// Album artwork resolutions.
  final Artwork? artwork;

  /// Track listings if preloaded.
  final List<Track>? tracks;

  /// Release date string.
  final String? releaseDate;

  /// Canonical permalink URL path on Audius.
  final String? permalink;

  /// Formatted track count string.
  String get formattedTrackCount =>
      '$trackCount ${trackCount == 1 ? "track" : "tracks"}';

  /// Compact formatted play count.
  String get formattedPlayCount {
    if (totalPlayCount >= 1000000) {
      final val = (totalPlayCount / 1000000).toStringAsFixed(1);
      return '${val.replaceAll(".0", "")}M plays';
    }
    if (totalPlayCount >= 1000) {
      final val = (totalPlayCount / 1000).toStringAsFixed(1);
      return '${val.replaceAll(".0", "")}k plays';
    }
    return '$totalPlayCount plays';
  }

  /// Converts this [Album] representation into a [Playlist] entity.
  Playlist toPlaylist() {
    return Playlist(
      id: id,
      playlistName: albumName,
      description: description,
      isAlbum: true,
      trackCount: trackCount,
      totalPlayCount: totalPlayCount,
      user: user,
      artwork: artwork,
      tracks: tracks,
      permalink: permalink,
      releaseDate: releaseDate,
    );
  }

  /// Constructs an [Album] from a [Playlist] entity.
  factory Album.fromPlaylist(Playlist playlist) {
    return Album(
      id: playlist.id,
      albumName: playlist.playlistName,
      description: playlist.description,
      user: playlist.user,
      artwork: playlist.artwork,
      trackCount: playlist.trackCount,
      totalPlayCount: playlist.totalPlayCount,
      releaseDate: playlist.releaseDate,
      tracks: playlist.tracks,
      permalink: playlist.permalink,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Album(id: $id, title: $albumName, artist: ${user?.name})';
}
