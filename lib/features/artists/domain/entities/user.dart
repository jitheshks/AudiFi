import '../../../../shared/models/artwork.dart';

/// Pure domain entity representing an Audius artist or user profile.
class User {
  const User({
    required this.id,
    required this.name,
    required this.handle,
    this.bio,
    this.location,
    this.isVerified = false,
    this.followerCount = 0,
    this.followeeCount = 0,
    this.trackCount = 0,
    this.playlistCount = 0,
    this.albumCount = 0,
    this.profilePicture,
    this.coverPhoto,
    this.doesFollowCurrentUser = false,
  });

  /// Unique Audius user identifier.
  final String id;

  /// Display name.
  final String name;

  /// User handle / username (without @).
  final String handle;

  /// Profile bio or description.
  final String? bio;

  /// Geographic location.
  final String? location;

  /// Verification badge status.
  final bool isVerified;

  /// Total number of followers.
  final int followerCount;

  /// Total number of followed accounts.
  final int followeeCount;

  /// Published track count.
  final int trackCount;

  /// Created playlist count.
  final int playlistCount;

  /// Published album count.
  final int albumCount;

  /// Profile picture resolutions.
  final Artwork? profilePicture;

  /// Cover photo / banner resolutions.
  final Artwork? coverPhoto;

  /// Whether currently logged-in user follows this profile.
  final bool doesFollowCurrentUser;

  /// Clean handle formatted with leading '@'.
  String get atHandle => '@$handle';

  /// Human-friendly formatted follower count (e.g. 1.3M, 50.0K).
  String get formattedFollowers {
    if (followerCount >= 1000000) {
      return '${(followerCount / 1000000).toStringAsFixed(1)}M';
    } else if (followerCount >= 1000) {
      return '${(followerCount / 1000).toStringAsFixed(1)}K';
    }
    return followerCount.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, handle: @$handle, name: $name)';
}
