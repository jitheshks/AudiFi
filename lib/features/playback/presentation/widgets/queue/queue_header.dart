import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Modal grab handle and header row for the queue sheet.
class QueueHeader extends StatelessWidget {
  const QueueHeader({
    super.key,
    required this.trackCount,
    required this.onClear,
  });

  final int trackCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 16.0, 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill matching .grab in audifi.html
          Center(
            child: Container(
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: colors.surface2,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          AppSpacing.vGap16,
          Row(
            children: [
              Text(
                'Up Next',
                style: AppTypography.h3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.hGap8,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  '$trackCount',
                  style: AppTypography.micro.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (trackCount > 1)
                Semantics(
                  button: true,
                  label: 'Clear queue',
                  child: TextButton(
                    onPressed: onClear,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.accent,
                      minimumSize: const Size(48.0, 48.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    ),
                    child: Text(
                      'Clear',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
