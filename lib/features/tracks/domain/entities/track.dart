import '../../../../shared/models/artwork.dart';
import '../../../artists/domain/entities/user.dart';

/// Pure domain entity representing an Audius track.
class Track {
  const Track({
    required this.id,
    required this.title,
    this.description,
    this.genre,
    this.mood,
    this.releaseDate,
    this.duration = 0,
    this.playCount = 0,
    this.favoriteCount = 0,
    this.repostCount = 0,
    this.commentCount = 0,
    this.artwork,
    this.user,
    this.permalink,
    this.isStreamable = true,
    this.isDownloadable,
    this.isDownloadGated = false,
    this.downloadUrl,
  });

  /// Unique Audius track identifier.
  final String id;

  /// Track title.
  final String title;

  /// Track description.
  final String? description;

  /// Primary genre.
  final String? genre;

  /// Track mood classification.
  final String? mood;

  /// Release date string.
  final String? releaseDate;

  /// Duration in seconds.
  final int duration;

  /// Total play count.
  final int playCount;

  /// Total favorite / like count.
  final int favoriteCount;

  /// Total repost count.
  final int repostCount;

  /// Total comment count.
  final int commentCount;

  /// Artwork resolutions.
  final Artwork? artwork;

  /// Publishing artist profile.
  final User? user;

  /// Canonical permalink path on audius.co.
  final String? permalink;

  /// Whether the track is streamable.
  final bool isStreamable;

  /// Whether the track creator has enabled downloads in track permissions.
  /// If null, permission is unknown and must be verified against official API.
  final bool? isDownloadable;

  /// Whether the download is restricted behind an access gate (purchase/NFT/follow).
  final bool isDownloadGated;

  /// Direct creator-authorized download URL, if exposed in track metadata.
  final String? downloadUrl;

  /// Whether the creator has explicitly authorized free public downloads.
  bool get isDownloadAuthorized => isDownloadable == true && !isDownloadGated;

  /// Formatted duration string as `m:ss` (e.g. `3:45`).
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Compact formatted play count string (e.g. 1.2k, 50k, 1.4M).
  String get formattedPlayCount {
    if (playCount >= 1000000) {
      final val = (playCount / 1000000).toStringAsFixed(1);
      return '${val.replaceAll(".0", "")}M';
    }
    if (playCount >= 1000) {
      final val = (playCount / 1000).toStringAsFixed(1);
      return '${val.replaceAll(".0", "")}k';
    }
    return '$playCount';
  }

  /// Formatted play count string (e.g. "452.0K").
  String get formattedPlays {
    if (playCount >= 1000000) {
      return '${(playCount / 1000000).toStringAsFixed(1)}M';
    } else if (playCount >= 1000) {
      return '${(playCount / 1000).toStringAsFixed(1)}K';
    }
    return playCount.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Track(id: $id, title: $title)';
}
