import 'package:flutter/widgets.dart';

/// Categorization of device form factors according to available screen width.
enum DeviceType {
  /// Small compact mobile screens (width < 360 logical pixels, e.g. 320dp).
  compactMobile,

  /// Standard mobile screens (360 <= width < 600 logical pixels, e.g. 360, 375, 390, 430).
  mobile,

  /// Tablet / Medium screens (600 <= width < 900 logical pixels).
  tablet,

  /// Desktop / Large screens (width >= 900 logical pixels).
  desktop,
}

/// Breakpoint thresholds and dimension constants for Audifi.
abstract final class ResponsiveBreakpoints {
  /// Breakpoint threshold below which a device is considered compact mobile.
  static const double compactMobile = 360.0;

  /// Breakpoint threshold at and above which a device is considered a tablet.
  static const double tablet = 600.0;

  /// Breakpoint threshold at and above which a device is considered desktop/expanded.
  static const double desktop = 900.0;

  /// Maximum content constraint for mobile viewports, matching `.app { max-width: 430px }`
  /// in the Audifi reference design.
  static const double maxMobileContentWidth = 430.0;

  /// Maximum content constraint for tablet layouts.
  static const double maxTabletContentWidth = 840.0;
}

/// Convenience extensions on [BuildContext] for responsive queries.
extension ResponsiveContext on BuildContext {
  /// Total width of the current window/media query.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Total height of the current window/media query.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Resolves the current [DeviceType] based on [screenWidth].
  DeviceType get deviceType {
    final width = screenWidth;
    if (width < ResponsiveBreakpoints.compactMobile) {
      return DeviceType.compactMobile;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return DeviceType.mobile;
    } else if (width < ResponsiveBreakpoints.desktop) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Whether the current screen is a compact mobile device (e.g. 320dp width).
  bool get isCompactMobile => screenWidth < ResponsiveBreakpoints.compactMobile;

  /// Whether the screen is mobile-sized (< 600dp width).
  bool get isMobile => screenWidth < ResponsiveBreakpoints.tablet;

  /// Whether the screen is tablet-sized (>= 600dp and < 900dp).
  bool get isTablet =>
      screenWidth >= ResponsiveBreakpoints.tablet &&
      screenWidth < ResponsiveBreakpoints.desktop;

  /// Whether the screen is desktop-sized (>= 900dp).
  bool get isDesktop => screenWidth >= ResponsiveBreakpoints.desktop;

  /// Whether the layout qualifies as wide-screen (tablet or desktop, >= 600dp).
  bool get isWideScreen => screenWidth >= ResponsiveBreakpoints.tablet;

  /// Current text scale factor to verify or adapt font sizes.
  double get textScaleFactor => MediaQuery.textScalerOf(this).scale(1.0);
}
