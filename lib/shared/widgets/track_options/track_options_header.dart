import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/tracks/domain/entities/track.dart';
import '../audifi_network_image.dart';

/// Top header widget displaying track artwork thumbnail, title, and artist name.
class TrackOptionsHeader extends StatelessWidget {
  const TrackOptionsHeader({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
      child: Row(
        children: [
          AudifiNetworkImage(
            imageUrl: track.artwork?.small ?? track.artwork?.primaryUrl,
            width: 48.0,
            height: 48.0,
            borderRadius: 8.0,
            fallbackIcon: Icons.music_note_rounded,
          ),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.vGap2,
                Text(
                  track.user?.name ?? 'Unknown Artist',
                  style: AppTypography.caption.copyWith(
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
