import 'package:material_ui/material_ui.dart';

import '../../core/responsive/responsive_breakpoints.dart';
import '../../core/responsive/responsive_container.dart';
import '../../core/theme/app_colors.dart';

/// Wraps page content with standard background color, responsive max width,
/// and smooth scrolling behavior.
class AudifiPageContainer extends StatelessWidget {
  const AudifiPageContainer({
    super.key,
    required this.child,
    this.padding,
    this.scrollable = true,
    this.alignment,
    this.maxWidth,
  });

  /// Page content.
  final Widget child;

  /// Page padding override.
  final EdgeInsetsGeometry? padding;

  /// Whether the page wraps children in a scroll view.
  final bool scrollable;

  /// Alignment of child within parent when width exceeds [maxWidth].
  final AlignmentGeometry? alignment;

  /// Max width constraint for the responsive container.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    Widget content = ResponsiveContainer(
      padding: padding,
      alignment: alignment ?? Alignment.topCenter,
      maxWidth: maxWidth ?? ResponsiveBreakpoints.maxMobileContentWidth,
      child: child,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    return ColoredBox(
      color: colors.background,
      child: SafeArea(top: false, child: content),
    );
  }
}
