import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../tracks/domain/entities/track.dart';

/// Text display row for the mini player showing track title and artist name.
class MiniPlayerInfo extends StatelessWidget {
  const MiniPlayerInfo({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.vGap2,
          Row(
            children: [
              Flexible(
                child: Text(
                  track.user?.name ?? 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
              if (track.user?.isVerified == true) ...[
                const SizedBox(width: 4.0),
                Icon(Icons.verified_rounded, size: 13.0, color: colors.accent),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
