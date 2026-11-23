import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// Reusable icon button conforming to the Audifi web UI `.ibtn` design specs
/// and Android 48x48 dp minimum touch target requirements.
class AudifiIconButton extends StatelessWidget {
  const AudifiIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.color,
    this.size = 24.0,
  });

  /// The icon widget or IconData to display.
  final dynamic icon;

  /// Callback when tapped.
  final VoidCallback? onPressed;

  /// Tooltip message.
  final String? tooltip;

  /// Accessibility semantic description.
  final String? semanticLabel;

  /// Optional icon color override.
  final Color? color;

  /// Icon size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final iconColor = color ?? colors.textMuted;

    Widget iconWidget;
    if (icon is IconData) {
      iconWidget = Icon(icon as IconData, size: size, color: iconColor);
    } else if (icon is Widget) {
      iconWidget = icon as Widget;
    } else {
      iconWidget = const SizedBox.shrink();
    }

    return Semantics(
      label: semanticLabel ?? tooltip,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
        child: IconButton(
          icon: iconWidget,
          onPressed: onPressed,
          tooltip: tooltip,
          splashRadius: 24.0,
        ),
      ),
    );
  }
}
