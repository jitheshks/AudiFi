import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// Reusable branded loading indicator with smooth indeterminate circular spinner.
class AudifiLoadingIndicator extends StatelessWidget {
  const AudifiLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.5,
    this.color,
    this.semanticsLabel = 'Loading',
  });

  /// The width and height constraints of the spinner.
  final double size;

  /// The thickness of the spinning circular stroke.
  final double strokeWidth;

  /// Custom color override (defaults to theme accent blurple).
  final Color? color;

  /// Accessibility semantic description.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.audifiColors.accent;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}
