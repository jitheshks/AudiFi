/// Domain entity representing a parent album backlink from the Audius API.
class AlbumBacklink {
  const AlbumBacklink({
    required this.playlistId,
    required this.playlistName,
    this.permalink,
  });

  /// Unique playlist/album identifier.
  final int playlistId;

  /// Display name of the parent album or playlist.
  final String playlistName;

  /// Canonical permalink path on audius.co.
  final String? permalink;

  factory AlbumBacklink.fromJson(Map<String, dynamic> json) {
    return AlbumBacklink(
      playlistId: (json['playlist_id'] as num?)?.toInt() ?? 0,
      playlistName: json['playlist_name'] as String? ?? '',
      permalink: json['permalink'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'playlist_id': playlistId,
    'playlist_name': playlistName,
    if (permalink != null) 'permalink': permalink,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumBacklink &&
          runtimeType == other.runtimeType &&
          playlistId == other.playlistId;

  @override
  int get hashCode => playlistId.hashCode;
}
