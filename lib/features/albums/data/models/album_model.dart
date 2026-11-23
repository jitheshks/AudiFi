import '../../../../shared/models/artwork.dart';
import '../../../artists/data/models/user_model.dart';
import '../../../tracks/data/models/track_model.dart';
import '../../domain/entities/album.dart';

/// Data transfer model for [Album], providing JSON serialization.
class AlbumModel extends Album {
  const AlbumModel({
    required super.id,
    super.title,
    super.albumName,
    super.description,
    super.trackCount,
    super.totalPlayCount,
    super.artist,
    super.user,
    super.artwork,
    super.tracks,
    super.releaseDate,
    super.permalink,
  });

  factory AlbumModel.fromEntity(Album album) {
    return AlbumModel(
      id: album.id,
      albumName: album.albumName,
      title: album.title,
      description: album.description,
      trackCount: album.trackCount,
      totalPlayCount: album.totalPlayCount,
      user: album.user,
      artwork: album.artwork,
      tracks: album.tracks,
      releaseDate: album.releaseDate,
      permalink: album.permalink,
    );
  }

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    final title =
        json['title'] as String? ??
        json['playlist_name'] as String? ??
        json['album_name'] as String? ??
        'Untitled Album';

    return AlbumModel(
      id: (json['id'] ?? '').toString(),
      albumName: title,
      title: title,
      description: json['description'] as String?,
      trackCount:
          (json['track_count'] as num?)?.toInt() ??
          (json['total_tracks'] as num?)?.toInt() ??
          0,
      totalPlayCount: (json['total_play_count'] as num?)?.toInt() ?? 0,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      artwork: json['artwork'] is Map<String, dynamic>
          ? Artwork.fromJson(json['artwork'] as Map<String, dynamic>)
          : null,
      tracks: (json['tracks'] as List<dynamic>?)
          ?.map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      releaseDate: json['release_date'] as String?,
      permalink: json['permalink'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'album_name': albumName,
      'playlist_name': albumName,
      'is_album': true,
      if (description != null) 'description': description,
      'track_count': trackCount,
      'total_play_count': totalPlayCount,
      if (user != null)
        'user': user is UserModel
            ? (user! as UserModel).toJson()
            : UserModel.fromEntity(user!).toJson(),
      if (artwork != null) 'artwork': artwork!.toJson(),
      if (tracks != null)
        'tracks': tracks!.map((t) {
          if (t is TrackModel) return t.toJson();
          return TrackModel.fromEntity(t).toJson();
        }).toList(),
      if (releaseDate != null) 'release_date': releaseDate,
      if (permalink != null) 'permalink': permalink,
    };
  }
}
