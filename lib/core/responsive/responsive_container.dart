import 'package:flutter/widgets.dart';

import 'responsive_breakpoints.dart';

/// A container widget that centers its child and applies an adaptive maximum width
/// constraint on larger screens (tablets, foldables, and desktop displays) to prevent
/// horizontal stretching and maintain optimal readability.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxMobileContentWidth,
    this.alignment = Alignment.topCenter,
    this.padding,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// The maximum width allowed for [child].
  /// Defaults to [ResponsiveBreakpoints.maxMobileContentWidth] (430 dp).
  final double maxWidth;

  /// How to align the child within the parent when space exceeds [maxWidth].
  final AlignmentGeometry alignment;

  /// Optional padding applied outside the constrained box.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return content;
  }
}
