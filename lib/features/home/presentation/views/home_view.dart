import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/responsive/responsive_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_button.dart';
import '../../../../shared/widgets/audifi_card.dart';
import '../../../../shared/widgets/audifi_media_card.dart';
import '../../../../shared/widgets/audifi_page_container.dart';
import '../../../downloads/presentation/controllers/download_controller.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../library/presentation/controllers/listening_history_controller.dart';
import '../../../local_files/presentation/controllers/local_files_controller.dart';
import '../../../playback/presentation/controllers/playback_controller.dart';

/// Home destination view providing personalized listening:
/// - Quick resume listening & personal collection shortcuts (Liked, Downloads, Local Files)
/// - Recently Played (Continue Listening)
/// - Frequently Played (Jump Back In based on local play statistics)
/// - Personalized Recommendations (based on user listening history)
///
/// Strictly personal; zero duplication of the global Discover catalog.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  static String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 17 || hour < 4) {
      return 'Good evening';
    } else if (hour >= 12) {
      return 'Good afternoon';
    } else {
      return 'Good morning';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final isWide = context.isWideScreen;
    final history = ref.watch(listeningHistoryProvider);
    final historyNotifier = ref.watch(listeningHistoryProvider.notifier);
    final recsState = ref.watch(localRecommendationsProvider);
    final library = ref.watch(libraryControllerProvider);
    final downloadedTracks = ref.watch(downloadedTracksProvider);
    final localTracks = ref.watch(localTracksProvider);

    // Personalized frequently played tracks (where play count > 1)
    final frequentlyPlayed = historyNotifier
        .getMostPlayedTracks(limit: 10)
        .where((t) => historyNotifier.getPlayCount(t.id) > 1)
        .toList();

    final isCompletelyFreshUser =
        history.isEmpty &&
        library.likedTracks.isEmpty &&
        downloadedTracks.isEmpty &&
        localTracks.isEmpty;

    final topInset = MediaQuery.paddingOf(context).top;
    final topSpacing = isWide
        ? (topInset > 0 ? topInset + 2.0 : 12.0)
        : topInset + 10.0;
    final horizontalPadding = isWide ? 24.0 : 20.0;

    return Scaffold(
      body: RefreshIndicator(
        color: colors.accent,
        backgroundColor: colors.surface1,
        onRefresh: () async {
          ref.invalidate(localRecommendationsProvider);
        },
        child: AudifiPageContainer(
          padding: EdgeInsets.zero,
          alignment: isWide
              ? AlignmentDirectional.topStart
              : Alignment.topCenter,
          maxWidth: isWide
              ? double.infinity
              : ResponsiveBreakpoints.maxMobileContentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Safe Area Top Padding
              SizedBox(height: topSpacing),

              // Greeting Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isWide ? 2.0 : 6.0,
                  horizontalPadding,
                  isWide ? 8.0 : 14.0,
                ),
                child: Text(
                  _greeting,
                  style: AppTypography.h1.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Hero Action & Quick Access Shortcuts Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Smart Primary Action Button
                    if (history.isNotEmpty)
                      AudifiButton(
                        text: 'Resume listening',
                        icon: const Icon(Icons.play_arrow_rounded),
                        variant: AudifiButtonVariant.primary,
                        onPressed: () {
                          final currentPlaying = ref
                              .read(playbackControllerProvider)
                              .currentTrack;
                          final targetTrack = currentPlaying ?? history.first;
                          ref
                              .read(playbackControllerProvider.notifier)
                              .playTrack(targetTrack, contextTracks: history);
                        },
                      )
                    else if (library.likedTracks.isNotEmpty)
                      AudifiButton(
                        text: 'Play Liked Songs',
                        icon: const Icon(Icons.favorite_rounded),
                        variant: AudifiButtonVariant.primary,
                        onPressed: () {
                          ref
                              .read(playbackControllerProvider.notifier)
                              .playTrack(
                                library.likedTracks.first,
                                contextTracks: library.likedTracks,
                              );
                        },
                      )
                    else if (localTracks.isNotEmpty)
                      AudifiButton(
                        text: 'Play Local Files',
                        icon: const Icon(Icons.folder_rounded),
                        variant: AudifiButtonVariant.primary,
                        onPressed: () {
                          ref
                              .read(playbackControllerProvider.notifier)
                              .playTrack(
                                localTracks.first,
                                contextTracks: localTracks,
                              );
                        },
                      )
                    else
                      AudifiButton(
                        text: 'Explore Discover',
                        icon: const Icon(Icons.explore_rounded),
                        variant: AudifiButtonVariant.primary,
                        onPressed: () => context.go(RoutePaths.discover),
                      ),

                    AppSpacing.vGap12,

                    // Quick Collection Shortcuts: Liked Songs, Downloads, Local Files
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 420.0 : double.infinity,
                      ),
                      child: Row(
                        children: [
                          // Liked Songs Shortcut
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  context.go('${RoutePaths.library}?tab=liked'),
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 10.0,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface1,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: colors.surface2.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      size: 18.0,
                                      color: colors.accent,
                                    ),
                                    AppSpacing.hGap4,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Liked',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${library.likedTracks.length}',
                                            style: AppTypography.micro.copyWith(
                                              color: colors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          AppSpacing.hGap8,

                          // Downloads Shortcut
                          Expanded(
                            child: InkWell(
                              onTap: () => context.go(
                                '${RoutePaths.library}?tab=downloaded',
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 10.0,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface1,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: colors.surface2.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.download_done_rounded,
                                      size: 18.0,
                                      color: colors.accent,
                                    ),
                                    AppSpacing.hGap4,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Offline',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${downloadedTracks.length}',
                                            style: AppTypography.micro.copyWith(
                                              color: colors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          AppSpacing.hGap8,

                          // Local Files Shortcut
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  context.go('${RoutePaths.library}?tab=local'),
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 10.0,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface1,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: colors.surface2.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.folder_rounded,
                                      size: 18.0,
                                      color: colors.accent,
                                    ),
                                    AppSpacing.hGap4,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Device',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${localTracks.length}',
                                            style: AppTypography.micro.copyWith(
                                              color: colors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Fresh User Welcome State
              if (isCompletelyFreshUser) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isWide ? 20.0 : 36.0,
                    horizontalPadding,
                    20.0,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 480.0 : double.infinity,
                      ),
                      child: AudifiCard(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.headphones_rounded,
                              size: 48.0,
                              color: colors.accent,
                            ),
                            AppSpacing.vGap12,
                            Text(
                              'Your Personal Music Dashboard',
                              textAlign: TextAlign.center,
                              style: AppTypography.h3.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.vGap8,
                            Text(
                              'As you play music, your listening history, favorite tracks, and personalized recommendations will automatically appear here.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.textMuted,
                                height: 1.4,
                              ),
                            ),
                            AppSpacing.vGap16,
                            AudifiButton(
                              text: 'Explore Discover Catalog',
                              variant: AudifiButtonVariant.primary,
                              onPressed: () => context.go(RoutePaths.discover),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Section 1: Recently Played (Continue Listening)
              if (history.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isWide ? 18.0 : 24.0,
                    horizontalPadding,
                    12.0,
                  ),
                  child: Text(
                    'Recently Played',
                    style: AppTypography.h2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: 185.0,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    itemCount: history.length.clamp(0, 10),
                    separatorBuilder: (context, index) => AppSpacing.hGap12,
                    itemBuilder: (context, index) {
                      final track = history[index];
                      return AudifiMediaCard(
                        title: track.title,
                        subtitle: track.user?.name ?? 'Unknown Artist',
                        imageUrl: track.artwork?.primaryUrl,
                        onTap: () {
                          ref
                              .read(playbackControllerProvider.notifier)
                              .playTrack(track, contextTracks: history);
                        },
                      );
                    },
                  ),
                ),
              ],

              // Section 2: Frequently Played (Jump Back In based on local play counts)
              if (frequentlyPlayed.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isWide ? 18.0 : 24.0,
                    horizontalPadding,
                    12.0,
                  ),
                  child: Text(
                    'Frequently Played',
                    style: AppTypography.h2.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: 185.0,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    itemCount: frequentlyPlayed.length,
                    separatorBuilder: (context, index) => AppSpacing.hGap12,
                    itemBuilder: (context, index) {
                      final track = frequentlyPlayed[index];
                      final count = historyNotifier.getPlayCount(track.id);
                      return AudifiMediaCard(
                        title: track.title,
                        subtitle:
                            '${track.user?.name ?? "Artist"} · $count plays',
                        imageUrl: track.artwork?.primaryUrl,
                        onTap: () {
                          ref
                              .read(playbackControllerProvider.notifier)
                              .playTrack(
                                track,
                                contextTracks: frequentlyPlayed,
                              );
                        },
                      );
                    },
                  ),
                ),
              ],

              // Section 3: Personalized Recommendations (Recommended for You)
              recsState.maybeWhen(
                data: (recs) {
                  if (recs.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isWide ? 18.0 : 24.0,
                          horizontalPadding,
                          12.0,
                        ),
                        child: Text(
                          'Recommended for You',
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
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          itemCount: recs.length,
                          separatorBuilder: (context, index) =>
                              AppSpacing.hGap12,
                          itemBuilder: (context, index) {
                            final track = recs[index];
                            return AudifiMediaCard(
                              title: track.title,
                              subtitle: track.user?.name ?? 'Unknown Artist',
                              imageUrl: track.artwork?.primaryUrl,
                              onTap: () {
                                ref
                                    .read(playbackControllerProvider.notifier)
                                    .playTrack(track, contextTracks: recs);
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

              SizedBox(height: isWide ? 24.0 : 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
