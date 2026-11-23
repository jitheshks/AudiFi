import '../../../../shared/models/artwork.dart';
import '../../domain/entities/user.dart';

/// Data transfer model for [User], providing JSON serialization.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.handle,
    super.bio,
    super.location,
    super.isVerified,
    super.followerCount,
    super.followeeCount,
    super.trackCount,
    super.playlistCount,
    super.albumCount,
    super.profilePicture,
    super.coverPhoto,
    super.doesFollowCurrentUser,
  });

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      handle: user.handle,
      bio: user.bio,
      location: user.location,
      isVerified: user.isVerified,
      followerCount: user.followerCount,
      followeeCount: user.followeeCount,
      trackCount: user.trackCount,
      playlistCount: user.playlistCount,
      albumCount: user.albumCount,
      profilePicture: user.profilePicture,
      coverPhoto: user.coverPhoto,
      doesFollowCurrentUser: user.doesFollowCurrentUser,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : (json['handle'] as String? ?? 'Unknown Artist'),
      handle: (json['handle'] as String?) ?? '',
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      followeeCount: (json['followee_count'] as num?)?.toInt() ?? 0,
      trackCount: (json['track_count'] as num?)?.toInt() ?? 0,
      playlistCount: (json['playlist_count'] as num?)?.toInt() ?? 0,
      albumCount: (json['album_count'] as num?)?.toInt() ?? 0,
      profilePicture: json['profile_picture'] is Map<String, dynamic>
          ? Artwork.fromJson(json['profile_picture'] as Map<String, dynamic>)
          : null,
      coverPhoto: json['cover_photo'] is Map<String, dynamic>
          ? Artwork.fromJson(json['cover_photo'] as Map<String, dynamic>)
          : null,
      doesFollowCurrentUser: json['does_current_user_follow'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
      'is_verified': isVerified,
      'follower_count': followerCount,
      'followee_count': followeeCount,
      'track_count': trackCount,
      'playlist_count': playlistCount,
      'album_count': albumCount,
      if (profilePicture != null) 'profile_picture': profilePicture!.toJson(),
      if (coverPhoto != null) 'cover_photo': coverPhoto!.toJson(),
    };
  }
}
