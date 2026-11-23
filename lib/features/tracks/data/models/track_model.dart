import '../../../../shared/models/artwork.dart';
import '../../../artists/data/models/user_model.dart';
import '../../domain/entities/track.dart';

/// Data transfer model for [Track], providing JSON serialization.
class TrackModel extends Track {
  const TrackModel({
    required super.id,
    required super.title,
    super.description,
    super.genre,
    super.mood,
    super.releaseDate,
    super.duration,
    super.playCount,
    super.favoriteCount,
    super.repostCount,
    super.commentCount,
    super.artwork,
    super.user,
    super.permalink,
    super.isStreamable,
    super.isDownloadable,
    super.isDownloadGated,
    super.downloadUrl,
  });

  factory TrackModel.fromEntity(Track track) {
    return TrackModel(
      id: track.id,
      title: track.title,
      description: track.description,
      genre: track.genre,
      mood: track.mood,
      releaseDate: track.releaseDate,
      duration: track.duration,
      playCount: track.playCount,
      favoriteCount: track.favoriteCount,
      repostCount: track.repostCount,
      commentCount: track.commentCount,
      artwork: track.artwork,
      user: track.user,
      permalink: track.permalink,
      isStreamable: track.isStreamable,
      isDownloadable: track.isDownloadable,
      isDownloadGated: track.isDownloadGated,
      downloadUrl: track.downloadUrl,
    );
  }

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Untitled Track',
      description: json['description'] as String?,
      genre: json['genre'] as String?,
      mood: json['mood'] as String?,
      releaseDate: json['release_date'] as String?,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      playCount: (json['play_count'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favorite_count'] as num?)?.toInt() ?? 0,
      repostCount: (json['repost_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      artwork: json['artwork'] is Map<String, dynamic>
          ? Artwork.fromJson(json['artwork'] as Map<String, dynamic>)
          : null,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      permalink: json['permalink'] as String?,
      isStreamable: json['is_streamable'] as bool? ?? true,
      isDownloadable: json['is_downloadable'] as bool?,
      isDownloadGated: json['is_download_gated'] as bool? ?? false,
      downloadUrl: json['download'] is Map<String, dynamic>
          ? (json['download'] as Map<String, dynamic>)['url'] as String?
          : (json['download_url'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (genre != null) 'genre': genre,
      if (mood != null) 'mood': mood,
      if (releaseDate != null) 'release_date': releaseDate,
      'duration': duration,
      'play_count': playCount,
      'favorite_count': favoriteCount,
      'repost_count': repostCount,
      'comment_count': commentCount,
      if (artwork != null) 'artwork': artwork!.toJson(),
      if (user != null)
        'user': user is UserModel
            ? (user! as UserModel).toJson()
            : UserModel.fromEntity(user!).toJson(),
      if (permalink != null) 'permalink': permalink,
      'is_streamable': isStreamable,
      'is_downloadable': isDownloadable,
      'is_download_gated': isDownloadGated,
      if (downloadUrl != null) 'download_url': downloadUrl,
    };
  }
}
