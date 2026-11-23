import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Standard top application bar across Audifi screens.
class AudifiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AudifiAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton,
  });

  /// Screen primary title text.
  final String title;

  /// Optional contextual subtitle.
  final String? subtitle;

  /// Optional trailing action widgets.
  final List<Widget>? actions;

  /// Optional leading navigation widget.
  final Widget? leading;

  /// Whether to show a standard back button when [leading] is null.
  final bool? showBackButton;

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? 68.0 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && (showBackButton ?? false)) {
      effectiveLeading = const BackButton();
    }

    return AppBar(
      backgroundColor: colors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: effectiveLeading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          if (subtitle != null) ...[
            AppSpacing.vGap4,
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }
}
