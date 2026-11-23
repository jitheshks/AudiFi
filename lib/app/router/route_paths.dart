/// Centralized route paths for GoRouter navigation.
abstract final class RoutePaths {
  static const String home = '/';
  static const String discover = '/discover';
  static const String search = '/search';
  static const String library = '/library';
  static const String settings = '/settings';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsAccent = '/settings/appearance/accent';
  static const String settingsPlayback = '/settings/playback';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsAudio = '/settings/audio';
  static const String settingsMusic = '/settings/music';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsAbout = '/settings/about';
  static const String nowPlaying = '/now-playing';

  static const String artistDetail = '/artist/:id';
  static String artist(String id) => '/artist/$id';

  static const String playlistDetail = '/playlist/:id';
  static String playlist(String id) => '/playlist/$id';
}
