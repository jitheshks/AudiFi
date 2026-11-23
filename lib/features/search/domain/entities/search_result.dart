import '../../../albums/domain/entities/album.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../playlists/domain/entities/playlist.dart';
import '../../../tracks/domain/entities/track.dart';

/// Pure domain entity aggregating catalog search results matching `search_model`.
class SearchResult {
  const SearchResult({
    this.tracks = const [],
    this.users = const [],
    this.playlists = const [],
    this.albums = const [],
  });

  /// Matching tracks.
  final List<Track> tracks;

  /// Matching users / artists.
  final List<User> users;

  /// Matching curated playlists.
  final List<Playlist> playlists;

  /// Matching commercial albums.
  final List<Album> albums;

  /// Whether no results were returned across all content types.
  bool get isEmpty =>
      tracks.isEmpty && users.isEmpty && playlists.isEmpty && albums.isEmpty;

  /// Whether at least one content type returned matches.
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          tracks.length == other.tracks.length &&
          users.length == other.users.length &&
          playlists.length == other.playlists.length &&
          albums.length == other.albums.length;

  @override
  int get hashCode =>
      Object.hash(tracks.length, users.length, playlists.length, albums.length);

  @override
  String toString() =>
      'SearchResult(tracks: ${tracks.length}, users: ${users.length}, playlists: ${playlists.length}, albums: ${albums.length})';
}
