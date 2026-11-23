import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'audifi_button.dart';

/// Reusable empty state view matching `.note` specification in `audifi.html`.
class AudifiEmptyState extends StatelessWidget {
  const AudifiEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.music_off_rounded,
    this.actionText,
    this.actionLabel,
    this.onAction,
  });

  /// Primary empty message title.
  final String title;

  /// Explanatory guidance or secondary text.
  final String? description;

  /// Visual icon representation.
  final IconData icon;

  /// Optional action button text.
  final String? actionText;

  /// Optional alias for [actionText].
  final String? actionLabel;

  /// Callback when action button is tapped.
  final VoidCallback? onAction;

  String? get _effectiveActionText => actionLabel ?? actionText;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final text = _effectiveActionText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                color: colors.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32.0, color: colors.textMuted),
            ),
            AppSpacing.vGap16,
            Text(
              title,
              style: AppTypography.h3.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              AppSpacing.vGap8,
              Text(
                description!,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (text != null && onAction != null) ...[
              AppSpacing.vGap24,
              AudifiButton(
                text: text,
                onPressed: onAction,
                type: AudifiButtonType.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
