import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Reusable section title header conforming to `.sh` in `audifi.html`.
class AudifiSectionHeader extends StatelessWidget {
  const AudifiSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.actionLabel,
    this.onActionTap,
    this.onAction,
  });

  /// The section header title text.
  final String title;

  /// Optional text for trailing action link.
  final String? actionText;

  /// Optional alias for [actionText].
  final String? actionLabel;

  /// Callback when trailing action is tapped.
  final VoidCallback? onActionTap;

  /// Optional alias for [onActionTap].
  final VoidCallback? onAction;

  String? get _effectiveActionText => actionLabel ?? actionText;
  VoidCallback? get _effectiveOnAction => onAction ?? onActionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final text = _effectiveActionText;
    final callback = _effectiveOnAction;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.sectionHeader.copyWith(
              color: colors.textMuted,
            ),
          ),
          if (text != null && callback != null)
            GestureDetector(
              onTap: callback,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  text,
                  style: AppTypography.caption.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
