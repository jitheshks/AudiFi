import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/downloads/presentation/controllers/download_controller.dart';
import '../../features/library/presentation/controllers/library_controller.dart';
import '../../features/tracks/domain/entities/track.dart';
import 'audifi_favorite_button.dart';
import 'audifi_network_image.dart';
import 'audifi_track_options_sheet.dart';

/// Reusable track tile row styled strictly after `.li` in `audifi.html` and `discover.png`.
class AudifiTrackTile extends ConsumerWidget {
  const AudifiTrackTile({
    super.key,
    required this.track,
    this.index,
    this.onTap,
    this.trailing,
    this.onMoreTap,
  });

  /// Domain track entity.
  final Track track;

  /// Optional track listing index/rank (e.g. 1, 2, 3...).
  final int? index;

  /// Primary tap callback.
  final VoidCallback? onTap;

  /// Optional custom trailing widget.
  final Widget? trailing;

  /// Optional more options tap callback.
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final library = ref.watch(libraryControllerProvider);
    final isLiked = library.isTrackLiked(track.id);
    final isDownloaded = ref.watch(isTrackDownloadedProvider(track.id));

    final durationPlays = [
      if (track.duration > 0) track.formattedDuration,
      if (track.playCount > 0) '${track.formattedPlayCount} plays',
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: Row(
          children: [
            if (index != null) ...[
              SizedBox(
                width: 24.0,
                child: Text(
                  '$index',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSpacing.hGap8,
            ],
            AudifiNetworkImage(
              imageUrl: track.artwork?.thumbnailUrl,
              width: 48.0,
              height: 48.0,
              borderRadius: 8.0,
            ),
            AppSpacing.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          track.user?.name ?? 'Unknown Artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                      if (track.user?.isVerified == true) ...[
                        const SizedBox(width: 4.0),
                        Icon(
                          Icons.verified_rounded,
                          size: 13.0,
                          color: colors.accent,
                        ),
                      ],
                    ],
                  ),
                  if (isDownloaded || durationPlays.isNotEmpty) ...[
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        if (isDownloaded) ...[
                          Icon(
                            Icons.download_done_rounded,
                            size: 13.0,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 4.0),
                        ],
                        if (durationPlays.isNotEmpty)
                          Flexible(
                            child: Text(
                              durationPlays,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.0,
                                color: colors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              AudifiFavoriteButton(
                isFavorite: isLiked,
                size: 20.0,
                tooltip: isLiked ? 'Remove from favorites' : 'Favorite',
                constraints: const BoxConstraints(
                  minWidth: 44.0,
                  minHeight: 44.0,
                ),
                onToggle: () {
                  ref
                      .read(libraryControllerProvider.notifier)
                      .toggleLikeTrack(track);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: colors.textMuted.withValues(alpha: 0.8),
                  size: 22.0,
                ),
                tooltip: 'More options',
                constraints: const BoxConstraints(
                  minWidth: 44.0,
                  minHeight: 44.0,
                ),
                onPressed:
                    onMoreTap ??
                    () => AudifiTrackOptionsSheet.show(context, track),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
