import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

/// Reusable container card matching Audifi UI group styling (`.grp`).
class AudifiCard extends StatelessWidget {
  const AudifiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.backgroundColor,
    this.useSurface2 = false,
    this.hasShadow = true,
  });

  /// The widget content inside the card.
  final Widget child;

  /// Internal padding. Defaults to 16 dp.
  final EdgeInsetsGeometry padding;

  /// Optional tap handler making the card interactive.
  final VoidCallback? onTap;

  /// Background color override.
  final Color? backgroundColor;

  /// Whether to use surface2 background color instead of surface1.
  final bool useSurface2;

  /// Whether to render standard card drop shadow.
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final effectiveBg =
        backgroundColor ?? (useSurface2 ? colors.surface2 : colors.surface1);

    Widget card = Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: AppRadius.cardBorder,
        boxShadow: hasShadow ? AppShadows.card(colors) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.cardBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardBorder,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return card;
  }
}
