/// Verified API endpoint paths strictly reflecting `references/api/api.json`.
abstract final class ApiEndpoints {
  // Tracks Endpoints
  static const String tracks = '/tracks';
  static const String trendingTracks = '/tracks/trending';
  static const String trendingUndergroundTracks =
      '/tracks/trending/underground';
  static const String recommendedTracks = '/tracks/recommended';
  static const String latestTracks = '/tracks/latest';

  static String trackDetails(String trackId) => '/tracks/$trackId';
  static String trackStream(String trackId) => '/tracks/$trackId/stream';
  static String trackDownload(String trackId) => '/tracks/$trackId/download';

  // Playlists Endpoints
  static const String playlists = '/playlists';
  static const String trendingPlaylists = '/playlists/trending';
  static const String newReleasesPlaylists = '/playlists/new-releases';

  static String playlistDetails(String playlistId) => '/playlists/$playlistId';
  static String playlistTracks(String playlistId) =>
      '/playlists/$playlistId/tracks';

  // Users Endpoints
  static const String users = '/users';
  static const String usersSearch = '/users/search';
  static const String usersTop = '/users/top';

  static String userDetails(String userId) => '/users/$userId';
  static String userByHandle(String handle) => '/users/handle/$handle';
  static String userTracks(String userId) => '/users/$userId/tracks';
  static String userAlbums(String userId) => '/users/$userId/albums';

  // Search Endpoints
  static const String searchFull = '/search/full';
  static const String searchAutocomplete = '/search/autocomplete';
  static const String searchTags = '/search/tags';

  // Content Resolution
  static const String resolve = '/resolve';
}
