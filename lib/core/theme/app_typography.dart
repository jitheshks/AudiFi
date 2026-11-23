import 'package:material_ui/material_ui.dart';

/// Centralized typography specifications for Audifi.
/// Faithfully reflects the typography scale defined in the Audifi reference UI.
abstract final class AppTypography {
  /// Heading 1 — 32px, bold, tight tracking.
  static const TextStyle h1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
  );

  /// Heading 2 — 20px, semi-bold.
  static const TextStyle h2 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
  );

  /// Heading 3 — 18px, semi-bold.
  static const TextStyle h3 = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  /// Standard Body Text — 15px, regular.
  static const TextStyle body = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.35,
  );

  /// Body Medium — 15px, medium weight.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.35,
  );

  /// Body Bold — 15px, semi-bold.
  static const TextStyle bodyBold = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  /// Pill / Button Text — 14px, medium-bold.
  static const TextStyle pill = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.2,
  );

  /// Subtitle / Secondary Muted Text — 13px.
  static const TextStyle subtitle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.3,
  );

  /// Caption / Small Label — 12px.
  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
    height: 1.25,
  );

  /// Navigation Bar Label — 11px.
  static const TextStyle nav = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.2,
  );

  /// Micro / Uppercase Source Label — 10px, wide tracking.
  static const TextStyle micro = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.2,
  );

  /// Section Header uppercase title style.
  static const TextStyle sectionHeader = micro;

  /// Button text style.
  static const TextStyle button = pill;

  /// Small Body text alias for subtitle style.
  static const TextStyle bodySmall = subtitle;

  /// Builds a [TextTheme] for the application given the primary and muted colors.
  static TextTheme createTextTheme({
    required Color primaryColor,
    required Color mutedColor,
  }) {
    return TextTheme(
      headlineLarge: h1.copyWith(color: primaryColor),
      headlineMedium: h2.copyWith(color: primaryColor),
      headlineSmall: h3.copyWith(color: primaryColor),
      titleLarge: h3.copyWith(color: primaryColor),
      titleMedium: bodyBold.copyWith(color: primaryColor),
      titleSmall: pill.copyWith(color: primaryColor),
      bodyLarge: body.copyWith(color: primaryColor),
      bodyMedium: body.copyWith(color: primaryColor),
      bodySmall: subtitle.copyWith(color: mutedColor),
      labelLarge: pill.copyWith(color: primaryColor),
      labelMedium: caption.copyWith(color: mutedColor),
      labelSmall: micro.copyWith(color: mutedColor),
    );
  }
}
