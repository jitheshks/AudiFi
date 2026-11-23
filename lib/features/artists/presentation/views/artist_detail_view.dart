import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_app_bar.dart';
import '../../../../shared/widgets/audifi_button.dart';
import '../../../../shared/widgets/audifi_content_switcher.dart';
import '../../../../shared/widgets/audifi_error_view.dart';
import '../../../../shared/widgets/audifi_loading_indicator.dart';
import '../../../../shared/widgets/audifi_media_card.dart';
import '../../../../shared/widgets/audifi_network_image.dart';
import '../../../../shared/widgets/audifi_page_container.dart';
import '../../../../shared/widgets/audifi_section_header.dart';
import '../../../../shared/widgets/audifi_track_tile.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../playback/presentation/controllers/playback_controller.dart';
import '../controllers/artist_detail_controller.dart';

/// Detailed view showing an artist profile, bio, statistics, and published track catalog.
class ArtistDetailView extends ConsumerWidget {
  const ArtistDetailView({super.key, required this.artistId});

  /// The unique Audius user ID.
  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final artistAsync = ref.watch(artistDetailProvider(artistId));

    return Scaffold(
      appBar: AudifiAppBar(
        title: 'Artist',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: AudifiContentSwitcher(
        layoutBuilder: AnimatedSwitcher.defaultLayoutBuilder,
        child: artistAsync.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(
            key: ValueKey('artist_detail_loading'),
            child: AudifiLoadingIndicator(size: 36.0),
          ),
          error: (error, stack) => Center(
            key: const ValueKey('artist_detail_error'),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AudifiErrorView(
                message: error.toString(),
                title: 'Artist Unavailable',
                onRetry: () => ref.refresh(artistDetailProvider(artistId)),
              ),
            ),
          ),
          data: (detailState) {
            final user = detailState.user;
            final tracks = detailState.tracks;

            return AudifiPageContainer(
              key: const ValueKey('artist_detail_data'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Artist Header Section
                  Center(
                    child: Column(
                      children: [
                        AudifiNetworkImage(
                          imageUrl: user.profilePicture?.primaryUrl,
                          width: 100.0,
                          height: 100.0,
                          isCircle: true,
                          fallbackIcon: Icons.person_rounded,
                        ),
                        AppSpacing.vGap16,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: AppTypography.h1.copyWith(
                                  color: colors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 6.0),
                              Icon(
                                Icons.verified_rounded,
                                size: 20.0,
                                color: colors.accent,
                              ),
                            ],
                          ],
                        ),
                        AppSpacing.vGap4,
                        Text(
                          user.atHandle,
                          style: AppTypography.body.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        AppSpacing.vGap12,
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.formattedFollowers,
                              style: AppTypography.caption.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' · ${user.trackCount} tracks',
                              style: AppTypography.caption.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          AppSpacing.vGap12,
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              user.bio!,
                              style: AppTypography.caption.copyWith(
                                color: colors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        AppSpacing.vGap16,
                        Builder(
                          builder: (context) {
                            final isFollowed = ref
                                .watch(libraryControllerProvider)
                                .isArtistFollowed(user.id);
                            return AudifiButton(
                              text: isFollowed ? 'Following' : 'Follow',
                              icon: Icon(
                                isFollowed
                                    ? Icons.check_rounded
                                    : Icons.person_add_rounded,
                              ),
                              variant: isFollowed
                                  ? AudifiButtonVariant.inverted
                                  : AudifiButtonVariant.primary,
                              onPressed: () {
                                ref
                                    .read(libraryControllerProvider.notifier)
                                    .toggleFollowArtist(user);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.vGap24,

                  // Artist Tracks Catalog
                  const AudifiSectionHeader(title: 'Tracks'),
                  if (tracks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          'No published tracks yet.',
                          style: AppTypography.body.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tracks.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: colors.surface2, height: 1.0),
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
                    ),

                  // Similar Artists Section
                  Consumer(
                    builder: (context, ref, _) {
                      final relatedAsync = ref.watch(
                        relatedArtistsProvider(artistId),
                      );
                      return relatedAsync.maybeWhen(
                        data: (related) {
                          if (related.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppSpacing.vGap24,
                              const AudifiSectionHeader(
                                title: 'Fans Also Like',
                              ),
                              SizedBox(
                                height: 165.0,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  clipBehavior: Clip.none,
                                  itemCount: related.length,
                                  separatorBuilder: (context, index) =>
                                      AppSpacing.hGap12,
                                  itemBuilder: (context, index) {
                                    final relatedUser = related[index];
                                    return AudifiMediaCard(
                                      title: relatedUser.name,
                                      subtitle: '',
                                      imageUrl: relatedUser
                                          .profilePicture
                                          ?.thumbnailUrl,
                                      isCircle: true,
                                      width: 110.0,
                                      onTap: () {
                                        context.push(
                                          RoutePaths.artist(relatedUser.id),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
