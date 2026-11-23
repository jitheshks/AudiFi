import '../../../albums/data/models/album_model.dart';
import '../../../artists/data/models/user_model.dart';
import '../../../playlists/data/models/playlist_model.dart';
import '../../../tracks/data/models/track_model.dart';
import '../../domain/entities/search_result.dart';

/// Data transfer model for [SearchResult], providing JSON serialization.
class SearchResultModel extends SearchResult {
  const SearchResultModel({
    super.tracks,
    super.users,
    super.playlists,
    super.albums,
  });

  factory SearchResultModel.fromEntity(SearchResult result) {
    return SearchResultModel(
      tracks: result.tracks,
      users: result.users,
      playlists: result.playlists,
      albums: result.albums,
    );
  }

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    final tracksList =
        (json['tracks'] as List<dynamic>?)
            ?.map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final usersList =
        (json['users'] as List<dynamic>?)
            ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final playlistsList =
        (json['playlists'] as List<dynamic>?)
            ?.map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final albumsList =
        (json['albums'] as List<dynamic>?)
            ?.map((e) => AlbumModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return SearchResultModel(
      tracks: tracksList,
      users: usersList,
      playlists: playlistsList,
      albums: albumsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tracks': tracks.map((t) {
        if (t is TrackModel) return t.toJson();
        return TrackModel.fromEntity(t).toJson();
      }).toList(),
      'users': users.map((u) {
        if (u is UserModel) return u.toJson();
        return UserModel.fromEntity(u).toJson();
      }).toList(),
      'playlists': playlists.map((p) {
        if (p is PlaylistModel) return p.toJson();
        return PlaylistModel.fromEntity(p).toJson();
      }).toList(),
      'albums': albums.map((a) {
        if (a is AlbumModel) return a.toJson();
        return AlbumModel.fromEntity(a).toJson();
      }).toList(),
    };
  }
}
