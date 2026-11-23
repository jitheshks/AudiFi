import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/widgets/audifi_network_image.dart';
import '../../../../tracks/domain/entities/track.dart';

/// Single item tile inside the queue sheet with drag and remove capabilities.
class QueueItemTile extends StatelessWidget {
  const QueueItemTile({
    super.key,
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
  });

  final Track track;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Semantics(
      button: true,
      label:
          '${isCurrent ? "Currently playing: " : ""}${track.title} by ${track.user?.name ?? "Unknown artist"}',
      child: Container(
        color: isCurrent
            ? colors.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Playing indicator or index
                SizedBox(
                  width: 24.0,
                  child: isCurrent
                      ? Icon(
                          Icons.equalizer_rounded,
                          color: colors.accent,
                          size: 18.0,
                        )
                      : Text(
                          '$index',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                ),
                AppSpacing.hGap8,

                // Artwork
                AudifiNetworkImage(
                  imageUrl: track.artwork?.thumbnailUrl,
                  width: 42.0,
                  height: 42.0,
                  borderRadius: 6.0,
                ),
                AppSpacing.hGap12,

                // Title and Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: isCurrent ? colors.accent : colors.textPrimary,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      AppSpacing.vGap2,
                      Text(
                        track.user?.name ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove button
                Semantics(
                  button: true,
                  label: 'Remove ${track.title} from queue',
                  child: SizedBox(
                    width: 48.0,
                    height: 48.0,
                    child: IconButton(
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18.0,
                        color: colors.textMuted,
                      ),
                      tooltip: 'Remove',
                    ),
                  ),
                ),

                // Drag handle icon for reordering
                ReorderableDragStartListener(
                  index: index - 1,
                  child: SizedBox(
                    width: 40.0,
                    height: 48.0,
                    child: Center(
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: colors.textMuted.withValues(alpha: 0.6),
                        size: 20.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
