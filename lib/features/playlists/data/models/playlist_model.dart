import '../../../../shared/models/artwork.dart';
import '../../../artists/data/models/user_model.dart';
import '../../../tracks/data/models/track_model.dart';
import '../../domain/entities/playlist.dart';

/// Data transfer model for [Playlist], providing JSON serialization.
class PlaylistModel extends Playlist {
  const PlaylistModel({
    required super.id,
    required super.playlistName,
    super.description,
    super.isAlbum,
    super.isPrivate,
    super.trackCount,
    super.totalPlayCount,
    super.favoriteCount,
    super.repostCount,
    super.user,
    super.artwork,
    super.tracks,
    super.permalink,
    super.releaseDate,
  });

  factory PlaylistModel.fromEntity(Playlist playlist) {
    return PlaylistModel(
      id: playlist.id,
      playlistName: playlist.playlistName,
      description: playlist.description,
      isAlbum: playlist.isAlbum,
      isPrivate: playlist.isPrivate,
      trackCount: playlist.trackCount,
      totalPlayCount: playlist.totalPlayCount,
      favoriteCount: playlist.favoriteCount,
      repostCount: playlist.repostCount,
      user: playlist.user,
      artwork: playlist.artwork,
      tracks: playlist.tracks,
      permalink: playlist.permalink,
      releaseDate: playlist.releaseDate,
    );
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: (json['id'] ?? '').toString(),
      playlistName:
          (json['playlist_name'] as String?)?.trim().isNotEmpty == true
          ? json['playlist_name'] as String
          : 'Untitled Playlist',
      description: json['description'] as String?,
      isAlbum: json['is_album'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      trackCount:
          (json['track_count'] as num?)?.toInt() ??
          (json['total_tracks'] as num?)?.toInt() ??
          (json['tracks'] is List ? (json['tracks'] as List).length : 0),
      totalPlayCount: (json['total_play_count'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favorite_count'] as num?)?.toInt() ?? 0,
      repostCount: (json['repost_count'] as num?)?.toInt() ?? 0,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      artwork: json['artwork'] is Map<String, dynamic>
          ? Artwork.fromJson(json['artwork'] as Map<String, dynamic>)
          : null,
      tracks: (json['tracks'] as List<dynamic>?)
          ?.map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      permalink: json['permalink'] as String?,
      releaseDate: json['release_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playlist_name': playlistName,
      if (description != null) 'description': description,
      'is_album': isAlbum,
      'is_private': isPrivate,
      'track_count': trackCount,
      'total_play_count': totalPlayCount,
      'favorite_count': favoriteCount,
      'repost_count': repostCount,
      if (artwork != null) 'artwork': artwork!.toJson(),
      if (user != null)
        'user': user is UserModel
            ? (user! as UserModel).toJson()
            : UserModel.fromEntity(user!).toJson(),
      if (tracks != null)
        'tracks': tracks!.map((t) {
          if (t is TrackModel) return t.toJson();
          return TrackModel.fromEntity(t).toJson();
        }).toList(),
      if (permalink != null) 'permalink': permalink,
      if (releaseDate != null) 'release_date': releaseDate,
    };
  }
}
