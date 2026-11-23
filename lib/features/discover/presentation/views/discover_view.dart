import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_media_card.dart';
import '../../../../shared/widgets/audifi_page_container.dart';
import '../../../artists/presentation/controllers/top_artists_controller.dart';
import '../../../home/presentation/controllers/latest_releases_controller.dart';
import '../../../playback/presentation/controllers/playback_controller.dart';
import '../controllers/discover_genre_controller.dart';
import '../controllers/trending_playlists_controller.dart';
import '../controllers/underground_tracks_controller.dart';
import '../widgets/discover_charts_section.dart';
import '../widgets/discover_genres_section.dart';
import '../widgets/discover_moods_section.dart';

/// Discover destination view showcasing genre exploration, mood exploration,
/// ranked charts (Top Tracks, Underground, Top Artists), popular playlists, and new releases.
/// Zero duplication with Home or across internal sections.
class DiscoverView extends ConsumerWidget {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final releasesState = ref.watch(latestReleasesControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: colors.accent,
        backgroundColor: colors.surface1,
        onRefresh: () async {
          ref.invalidate(discoverTrendingTracksProvider);
          ref.invalidate(undergroundTracksProvider);
          await Future.wait<void>([
            ref.read(topArtistsControllerProvider.notifier).refresh(),
            ref.read(trendingPlaylistsControllerProvider.notifier).refresh(),
            ref.read(latestReleasesControllerProvider.notifier).refresh(),
          ]);
        },
        child: AudifiPageContainer(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Safe Area Top Padding
              SizedBox(height: MediaQuery.paddingOf(context).top + 10.0),

              // Discover Heading
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 4.0),
                child: Text(
                  'Discover',
                  style: AppTypography.h1.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 14.0),
                child: Text(
                  'Explore music across the Audius catalog',
                  style: TextStyle(fontSize: 13.0, color: colors.textMuted),
                ),
              ),

              // Genres Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Genres',
                  style: AppTypography.h2.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSpacing.vGap12,
              const DiscoverGenresSection(),

              AppSpacing.vGap16,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Moods',
                  style: AppTypography.h2.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSpacing.vGap12,
              const DiscoverMoodsSection(),

              AppSpacing.vGap8,

              // Charts Section (Top Tracks, Underground, Top Artists, Popular Playlists)
              const DiscoverChartsSection(),

              // New Releases Section
              releasesState.maybeWhen(
                data: (tracks) {
                  if (tracks.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          28.0,
                          20.0,
                          12.0,
                        ),
                        child: Text(
                          'New releases',
                          style: AppTypography.h2.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 195.0,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          itemCount: tracks.length,
                          separatorBuilder: (context, index) =>
                              AppSpacing.hGap12,
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            return AudifiMediaCard(
                              title: track.title,
                              subtitle: track.user?.name ?? 'Unknown Artist',
                              imageUrl: track.artwork?.primaryUrl,
                              onTap: () {
                                ref
                                    .read(playbackControllerProvider.notifier)
                                    .playTrack(track, contextTracks: tracks);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
