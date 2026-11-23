/// Strongly typed representation of Audius artwork resolutions.
/// Matches `track_artwork`, `profile_picture`, and `playlist_artwork` in `references/api/api.json`.
class Artwork {
  const Artwork({this.small, this.medium, this.large, this.mirrors = const []});

  /// 150x150 resolution thumbnail URL.
  final String? small;

  /// 480x480 standard resolution URL.
  final String? medium;

  /// 1000x1000 high resolution URL.
  final String? large;

  /// Optional IPFS/storage mirror hostnames.
  final List<String> mirrors;

  /// Aliases matching resolution names.
  String? get res150x150 => small;
  String? get res480x480 => medium;
  String? get res1000x1000 => large;

  /// Returns the most suitable resolution URL for standard displays.
  String? get primaryUrl => medium ?? large ?? small;

  /// Returns the thumbnail resolution URL.
  String? get thumbnailUrl => small ?? medium ?? large;

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      small: json['150x150'] as String?,
      medium: json['480x480'] as String?,
      large: json['1000x1000'] as String?,
      mirrors:
          (json['mirrors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (small != null) '150x150': small,
      if (medium != null) '480x480': medium,
      if (large != null) '1000x1000': large,
      'mirrors': mirrors,
    };
  }

  @override
  String toString() => 'Artwork(primaryUrl: $primaryUrl)';
}
