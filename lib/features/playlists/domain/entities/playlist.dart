import '../../../../shared/models/artwork.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../tracks/domain/entities/track.dart';

/// Pure domain entity representing an Audius playlist or album collection.
class Playlist {
  const Playlist({
    required this.id,
    required this.playlistName,
    this.description,
    this.isAlbum = false,
    this.isPrivate = false,
    this.trackCount = 0,
    this.totalPlayCount = 0,
    this.favoriteCount = 0,
    this.repostCount = 0,
    this.user,
    this.artwork,
    this.tracks,
    this.permalink,
    this.releaseDate,
  });

  /// Unique playlist ID.
  final String id;

  /// Playlist title.
  final String playlistName;

  /// Playlist description.
  final String? description;

  /// Whether this collection represents a commercial album.
  final bool isAlbum;

  /// Privacy status.
  final bool isPrivate;

  /// Total number of tracks contained.
  final int trackCount;

  /// Cumulative play count.
  final int totalPlayCount;

  /// Total favorite / save count.
  final int favoriteCount;

  /// Total repost count.
  final int repostCount;

  /// Curator or artist who created the playlist.
  final User? user;

  /// Artwork resolutions.
  final Artwork? artwork;

  /// Optional track listing if preloaded with details.
  final List<Track>? tracks;

  /// Canonical permalink URL path on Audius.
  final String? permalink;

  /// Release date string if applicable.
  final String? releaseDate;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Playlist(id: $id, name: $playlistName, isAlbum: $isAlbum)';
}
