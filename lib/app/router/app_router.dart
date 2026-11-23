import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_motion.dart';
import '../../features/artists/presentation/views/artist_detail_view.dart';
import '../../features/discover/presentation/views/discover_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/library/presentation/views/library_view.dart';
import '../../features/playback/presentation/views/now_playing_view.dart';
import '../../features/playlists/presentation/views/playlist_detail_view.dart';
import '../../features/search/presentation/views/search_view.dart';
import '../../features/settings/presentation/views/about_view.dart';
import '../../features/settings/presentation/views/accent_color_view.dart';
import '../../features/settings/presentation/views/appearance_view.dart';
import '../../features/settings/presentation/views/audio_view.dart';
import '../../features/settings/presentation/views/music_view.dart';
import '../../features/settings/presentation/views/notifications_view.dart';
import '../../features/settings/presentation/views/playback_view.dart';
import '../../features/settings/presentation/views/privacy_view.dart';
import '../../features/settings/presentation/views/settings_view.dart';
import 'app_navigation_shell.dart';
import 'route_paths.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Provider for the application's declarative [GoRouter] configuration.
/// Integrates [AppMotion] for centralized, smooth transitions and reduced motion.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return AppNavigationShell(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),

          // Branch 1: Discover
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.discover,
                builder: (context, state) => const DiscoverView(),
              ),
            ],
          ),

          // Branch 2: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.search,
                builder: (context, state) => const SearchView(),
              ),
            ],
          ),

          // Branch 3: Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.library,
                builder: (context, state) {
                  final tabParam = state.uri.queryParameters['tab'];
                  final initialTab = switch (tabParam) {
                    'liked' || 'tracks' => LibraryCategory.liked,
                    'downloaded' || 'downloads' => LibraryCategory.downloads,
                    'local' || 'local_files' => LibraryCategory.localFiles,
                    'playlists' => LibraryCategory.playlists,
                    'artists' => LibraryCategory.artists,
                    'history' => LibraryCategory.history,
                    'all' => LibraryCategory.all,
                    _ => null,
                  };
                  return LibraryView(initialTab: initialTab);
                },
              ),
            ],
          ),

          // Branch 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                pageBuilder: (context, state) => AppMotion.createPage(
                  key: state.pageKey,
                  child: const SettingsView(),
                  type: AppTransitionType.fade,
                ),
                routes: [
                  GoRoute(
                    path: 'playback',
                    pageBuilder: (context, state) => AppMotion.createPage(
                      key: state.pageKey,
                      child: const PlaybackView(),
                      type: AppTransitionType.slideFade,
                    ),
                  ),
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (context, state) => AppMotion.createPage(
                      key: state.pageKey,
                      child: const NotificationsView(),
                      type: AppTransitionType.slideFade,
                    ),
                  ),
                  GoRoute(
                    path: 'audio',
                    pageBuilder: (context, state) => AppMotion.createPage(
                      key: state.pageKey,
                      child: const AudioView(),
                      type: AppTransitionType.slideFade,
                    ),
                  ),
                  GoRoute(
                    path: 'music',
                    pageBuilder: (context, state) => AppMotion.createPage(
                      key: state.pageKey,
                      child: const MusicView(),
                      type: AppTransitionType.slideFade,
                    ),
                  ),
                  GoRoute(
                    path: 'appearance',
                    pageBuilder: (context, state) => AppMotion.createPage(
                      key: state.pageKey,
                      child: const AppearanceView(),
                      type: AppTransitionType.slideFade,
                    ),
                    routes: [
                      GoRoute(
                        path: 'accent',
                        pageBuilder: (context, state) => AppMotion.createPage(
                          key: state.pageKey,
                          child: const AccentColorView(),
                          type: AppTransitionType.slideFade,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'privacy',
                    pageBuilder: (context, state) => AppMotion.createPage(
                      key: state.pageKey,
                      child: const PrivacyView(),
                      type: AppTransitionType.slideFade,
                    ),
                  ),
                  GoRoute(
                    path: 'about',
                    pageBuilder: (context, state) => AppMotion.createPage(
                      key: state.pageKey,
                      child: const AboutView(),
                      type: AppTransitionType.slideFade,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Full-screen overlay routes outside the tab navigation shell
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.artistDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AppMotion.createPage(
            key: state.pageKey,
            child: ArtistDetailView(artistId: id),
            type: AppTransitionType.slideFade,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.playlistDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AppMotion.createPage(
            key: state.pageKey,
            child: PlaylistDetailView(playlistId: id),
            type: AppTransitionType.slideFade,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: RoutePaths.nowPlaying,
        pageBuilder: (context, state) => AppMotion.createPage(
          key: state.pageKey,
          child: const NowPlayingView(),
          type: AppTransitionType.slideUp,
        ),
      ),
    ],
  );
});
