import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/audifi_favorite_button.dart';
import '../../../../library/presentation/controllers/library_controller.dart';
import '../../../../tracks/domain/entities/track.dart';

/// Track title, artist row, and audio metadata for the Now Playing screen.
class NowPlayingTrackInfo extends StatelessWidget {
  const NowPlayingTrackInfo({
    super.key,
    required this.track,
    this.isBuffering = false,
  });

  final Track track;
  final bool isBuffering;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    final metadataItems = <String>[];
    if (track.genre != null && track.genre!.isNotEmpty) {
      metadataItems.add(track.genre!);
    }
    if (track.mood != null && track.mood!.isNotEmpty) {
      metadataItems.add(track.mood!);
    }
    if (track.playCount > 0) {
      metadataItems.add('${track.formattedPlayCount} plays');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Track Title
                  Semantics(
                    header: true,
                    child: Text(
                      track.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h2.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AppSpacing.vGap6,

                  // Artist row
                  Semantics(
                    button: track.user?.id != null,
                    label: track.user?.name != null
                        ? 'Artist: ${track.user!.name}${track.user!.isVerified ? ", verified" : ""}'
                        : null,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0),
                      child: InkWell(
                        onTap: track.user?.id != null
                            ? () => context.push(
                                RoutePaths.artist(track.user!.id),
                              )
                            : null,
                        borderRadius: BorderRadius.circular(8.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 4.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  track.user?.name ?? 'Unknown Artist',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body.copyWith(
                                    color: colors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (track.user?.isVerified == true) ...[
                                const SizedBox(width: 6.0),
                                ExcludeSemantics(
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 16.0,
                                    color: colors.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGap8,
            Consumer(
              builder: (context, ref, _) {
                final isLiked = ref
                    .watch(libraryControllerProvider)
                    .isTrackLiked(track.id);
                return AudifiFavoriteButton(
                  isFavorite: isLiked,
                  size: 28.0,
                  tooltip: isLiked ? 'Unlike track' : 'Like track',
                  onToggle: () {
                    ref
                        .read(libraryControllerProvider.notifier)
                        .toggleLikeTrack(track);
                  },
                );
              },
            ),
          ],
        ),
        AppSpacing.vGap8,

        // Metadata line or buffering announcement
        if (isBuffering)
          Semantics(
            container: true,
            liveRegion: true,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: 14.0,
                    height: 14.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    ),
                  ),
                ),
                AppSpacing.hGap8,
                Text(
                  'Buffering stream…',
                  style: AppTypography.caption.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else if (metadataItems.isNotEmpty)
          Text(
            metadataItems.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: colors.textMuted),
          ),
      ],
    );
  }
}
