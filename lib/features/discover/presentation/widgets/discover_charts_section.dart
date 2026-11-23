import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_content_switcher.dart';
import '../../../../shared/widgets/audifi_empty_state.dart';
import '../../../../shared/widgets/audifi_error_view.dart';
import '../../../../shared/widgets/audifi_loading_indicator.dart';
import '../../../../shared/widgets/audifi_network_image.dart';
import '../../../../shared/widgets/audifi_track_tile.dart';
import '../../../../shared/widgets/audifi_underlined_tabs.dart';
import '../../../artists/presentation/controllers/top_artists_controller.dart';
import '../../../playback/presentation/controllers/playback_controller.dart';
import '../controllers/discover_genre_controller.dart';
import '../controllers/trending_playlists_controller.dart';
import '../controllers/underground_tracks_controller.dart';

enum ChartCategory { topTracks, underground, topArtists, popularPlaylists }

/// Charts tab section displaying Top Tracks, Underground Trending, Top Artists, and Popular Playlists
/// with underlined tabs matching `discover.png`.
class DiscoverChartsSection extends ConsumerStatefulWidget {
  const DiscoverChartsSection({super.key});

  @override
  ConsumerState<DiscoverChartsSection> createState() =>
      _DiscoverChartsSectionState();
}

class _DiscoverChartsSectionState extends ConsumerState<DiscoverChartsSection> {
  ChartCategory _activeTab = ChartCategory.topTracks;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 8.0),
          child: Text(
            'Charts',
            style: AppTypography.h2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Underlined Tabs matching discover.png
        AudifiUnderlinedTabs<ChartCategory>(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          tabs: const [
            AudifiTabItem(value: ChartCategory.topTracks, label: 'Top Tracks'),
            AudifiTabItem(
              value: ChartCategory.underground,
              label: 'Underground',
            ),
            AudifiTabItem(
              value: ChartCategory.topArtists,
              label: 'Top Artists',
            ),
            AudifiTabItem(
              value: ChartCategory.popularPlaylists,
              label: 'Popular Playlists',
            ),
          ],
          selectedValue: _activeTab,
          onTabSelected: (category) {
            setState(() => _activeTab = category);
          },
        ),

        AppSpacing.vGap12,

        // Tab Content
        AudifiContentSwitcher(
          child: switch (_activeTab) {
            ChartCategory.topTracks => _buildTopTracks(context, colors),
            ChartCategory.underground => _buildUndergroundTracks(
              context,
              colors,
            ),
            ChartCategory.topArtists => _buildTopArtists(context, colors),
            ChartCategory.popularPlaylists => _buildPopularPlaylists(
              context,
              colors,
            ),
          },
        ),
      ],
    );
  }

  Widget _buildTopTracks(BuildContext context, AudifiThemeColors colors) {
    final state = ref.watch(discoverTrendingTracksProvider);

    return state.when(
      skipLoadingOnRefresh: true,
      loading: () => const Padding(
        key: ValueKey('top_tracks_loading'),
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: AudifiLoadingIndicator(size: 28.0)),
      ),
      error: (e, _) => Padding(
        key: const ValueKey('top_tracks_error'),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: AudifiErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(discoverTrendingTracksProvider),
        ),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const AudifiEmptyState(
            key: ValueKey('top_tracks_empty'),
            title: 'No Tracks',
            description: 'Top tracks are not available right now.',
            icon: Icons.music_off_rounded,
          );
        }

        return ListView.separated(
          key: const ValueKey('top_tracks_list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: tracks.take(15).length,
          separatorBuilder: (context, index) => Divider(
            color: colors.surface2.withValues(alpha: 0.5),
            height: 1.0,
          ),
          itemBuilder: (context, index) {
            final track = tracks[index];
            return AudifiTrackTile(
              track: track,
              onTap: () {
                ref
                    .read(playbackControllerProvider.notifier)
                    .playTrack(track, contextTracks: tracks);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUndergroundTracks(
    BuildContext context,
    AudifiThemeColors colors,
  ) {
    final state = ref.watch(undergroundTracksProvider);

    return state.when(
      skipLoadingOnRefresh: true,
      loading: () => const Padding(
        key: ValueKey('underground_tracks_loading'),
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: AudifiLoadingIndicator(size: 28.0)),
      ),
      error: (err, stack) => Padding(
        key: const ValueKey('underground_tracks_error'),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: AudifiErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(undergroundTracksProvider),
        ),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Padding(
            key: ValueKey('underground_tracks_empty'),
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: AudifiEmptyState(
              title: 'No Underground Tracks',
              description:
                  'Underground trending tracks are currently unavailable.',
              icon: Icons.music_off_rounded,
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: tracks.take(15).length,
          separatorBuilder: (context, index) => Divider(
            color: colors.surface2.withValues(alpha: 0.5),
            height: 1.0,
          ),
          itemBuilder: (context, index) {
            final track = tracks[index];
            return AudifiTrackTile(
              track: track,
              index: index + 1,
              onTap: () {
                ref
                    .read(playbackControllerProvider.notifier)
                    .playTrack(track, contextTracks: tracks);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTopArtists(BuildContext context, AudifiThemeColors colors) {
    final state = ref.watch(topArtistsControllerProvider);

    return state.when(
      skipLoadingOnRefresh: true,
      loading: () => const Padding(
        key: ValueKey('top_artists_loading'),
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: AudifiLoadingIndicator(size: 28.0)),
      ),
      error: (e, _) => Padding(
        key: const ValueKey('top_artists_error'),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: AudifiErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(topArtistsControllerProvider.notifier).refresh(),
        ),
      ),
      data: (artists) {
        if (artists.isEmpty) {
          return const AudifiEmptyState(
            key: ValueKey('top_artists_empty'),
            title: 'No Artists',
            description: 'Top artists are not available right now.',
            icon: Icons.person_off_rounded,
          );
        }

        return ListView.separated(
          key: const ValueKey('top_artists_list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: artists.length,
          separatorBuilder: (context, index) =>
              Divider(color: colors.surface2, height: 1.0),
          itemBuilder: (context, index) {
            final artist = artists[index];
            return Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                leading: SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: AudifiNetworkImage(
                    imageUrl: artist.profilePicture?.thumbnailUrl,
                    isCircle: true,
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        artist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (artist.isVerified) ...[
                      AppSpacing.hGap4,
                      Icon(
                        Icons.verified_rounded,
                        color: colors.accent,
                        size: 16.0,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${artist.atHandle} · ${artist.followerCount} followers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  context.push(RoutePaths.artist(artist.id));
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPopularPlaylists(
    BuildContext context,
    AudifiThemeColors colors,
  ) {
    final state = ref.watch(trendingPlaylistsControllerProvider);

    return state.when(
      skipLoadingOnRefresh: true,
      loading: () => const Padding(
        key: ValueKey('popular_playlists_loading'),
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: AudifiLoadingIndicator(size: 28.0)),
      ),
      error: (e, _) => Padding(
        key: const ValueKey('popular_playlists_error'),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: AudifiErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(trendingPlaylistsControllerProvider.notifier).refresh(),
        ),
      ),
      data: (playlists) {
        if (playlists.isEmpty) {
          return const AudifiEmptyState(
            key: ValueKey('popular_playlists_empty'),
            title: 'No Playlists',
            description: 'Popular playlists are not available right now.',
            icon: Icons.queue_music_rounded,
          );
        }

        return ListView.separated(
          key: const ValueKey('popular_playlists_list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: playlists.take(10).length,
          separatorBuilder: (context, index) =>
              Divider(color: colors.surface2, height: 1.0),
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                leading: SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: AudifiNetworkImage(
                    imageUrl: playlist.artwork?.thumbnailUrl,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                title: Text(
                  playlist.playlistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${playlist.user?.name ?? "Curator"} · ${playlist.trackCount} tracks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  context.push(RoutePaths.playlist(playlist.id));
                },
              ),
            );
          },
        );
      },
    );
  }
}
