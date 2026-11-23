import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Centralized elevation and shadow definitions for Audifi.
abstract final class AppShadows {
  /// Standard light card and container shadow: `0 8px 24px rgba(40,30,20,.12)`
  static const List<BoxShadow> light = [
    BoxShadow(
      color: AppColors.lightShadow,
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  /// Standard dark card and container shadow: `0 10px 30px rgba(0,0,0,.55)`
  static const List<BoxShadow> dark = [
    BoxShadow(
      color: AppColors.darkShadow,
      offset: Offset(0, 10),
      blurRadius: 30,
      spreadRadius: 0,
    ),
  ];

  /// Subtle component shadow (e.g. for artwork or small chips)
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x26000000), // rgba(0,0,0,.15)
      offset: Offset(0, 4),
      blurRadius: 14,
      spreadRadius: 0,
    ),
  ];

  /// Resolves the appropriate shadow according to theme brightness.
  static List<BoxShadow> of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// Resolves the appropriate shadow for card containers based on theme colors.
  static List<BoxShadow> card(AudifiThemeColors colors) {
    return colors.shadow == AppColors.darkShadow ? dark : light;
  }
}
