import 'package:flutter/widgets.dart';

import 'responsive_breakpoints.dart';

/// Callback type for builder functions receiving [BoxConstraints].
typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
);

/// A widget that builds different UI layouts based on the parent [BoxConstraints].
/// Follows the recommended Flutter architecture for adaptive layouts.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Builder invoked when width is mobile (< 600 dp).
  final ResponsiveWidgetBuilder mobile;

  /// Optional builder invoked when width is tablet (>= 600 dp and < 900 dp).
  /// If null, falls back to [desktop] if present, or [mobile].
  final ResponsiveWidgetBuilder? tablet;

  /// Optional builder invoked when width is desktop (>= 900 dp).
  /// If null, falls back to [tablet] if present, or [mobile].
  final ResponsiveWidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= ResponsiveBreakpoints.desktop) {
          if (desktop != null) return desktop!(context, constraints);
          if (tablet != null) return tablet!(context, constraints);
          return mobile(context, constraints);
        }

        if (width >= ResponsiveBreakpoints.tablet) {
          if (tablet != null) return tablet!(context, constraints);
          return mobile(context, constraints);
        }

        return mobile(context, constraints);
      },
    );
  }
}

/// Helper utility to select responsive values based on current screen width.
abstract final class ResponsiveValue {
  /// Selects a value of type [T] depending on the screen width.
  static T select<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= ResponsiveBreakpoints.desktop && desktop != null) {
      return desktop;
    }
    if (width >= ResponsiveBreakpoints.tablet && tablet != null) {
      return tablet;
    }
    return mobile;
  }
}
