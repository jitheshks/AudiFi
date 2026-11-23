import 'package:material_ui/material_ui.dart';

/// Centralized color palette for the Audifi application.
/// Derived strictly from the Audifi reference design (`references/UI/audifi.html`).
abstract final class AppColors {
  // Brand Accent (Purple matching Audius protocol branding, #8B5CF6)
  static const Color accent = Color(0xFF8B5CF6);
  static const Color accentLight = Color(0xFFA78BFA);
  static const Color accentDark = Color(0xFF7C3AED);

  /// All selectable accent color options conforming to `audifi.html` and `accent_colour.png`.
  static const List<AudifiAccent> accentOptions = AudifiAccent.options;

  // Light Palette
  static const Color lightBackground = Color(0xFFF4F1EC);
  static const Color lightSurface1 = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEAE6DF);
  static const Color lightTextPrimary = Color(0xFF16151A);
  static const Color lightTextMuted = Color(0xFF615E69);
  static const Color lightShadow = Color(0x1F281E14); // rgba(40,30,20,.12)
  static const Color lightGlass = Color(0xC7FFFFFF); // rgba(255,255,255,.78)

  // Dark Palette
  static const Color darkBackground = Color(0xFF0B0B0D);
  static const Color darkSurface1 = Color(0xFF141418);
  static const Color darkSurface2 = Color(0xFF1D1D24);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextMuted = Color(0xFFA7A7B0);
  static const Color darkShadow = Color(0x8C000000); // rgba(0,0,0,.55)
  static const Color darkGlass = Color(0xCC1B1B21); // rgba(27,27,33,.80)

  // OLED Dark Palette
  static const Color oledBackground = Color(0xFF000000);

  // Status & Semantic Colors
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF5856D6);
}

/// ThemeExtension for Audifi-specific tokens to seamlessly adapt
/// between light, dark, and OLED modes.
class AudifiThemeColors extends ThemeExtension<AudifiThemeColors> {
  const AudifiThemeColors({
    required this.background,
    required this.surface1,
    required this.surface2,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.glass,
    required this.shadow,
    required this.error,
    required this.success,
  });

  final Color background;
  final Color surface1;
  final Color surface2;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  /// Secondary text color alias.
  Color get textSecondary => textMuted;
  final Color glass;
  final Color shadow;
  final Color error;
  final Color success;

  /// Default Light Theme Tokens
  static const AudifiThemeColors light = AudifiThemeColors(
    background: AppColors.lightBackground,
    surface1: AppColors.lightSurface1,
    surface2: AppColors.lightSurface2,
    textPrimary: AppColors.lightTextPrimary,
    textMuted: AppColors.lightTextMuted,
    accent: AppColors.accent,
    glass: AppColors.lightGlass,
    shadow: AppColors.lightShadow,
    error: AppColors.error,
    success: AppColors.success,
  );

  /// Default Dark Theme Tokens
  static const AudifiThemeColors dark = AudifiThemeColors(
    background: AppColors.darkBackground,
    surface1: AppColors.darkSurface1,
    surface2: AppColors.darkSurface2,
    textPrimary: AppColors.darkTextPrimary,
    textMuted: AppColors.darkTextMuted,
    accent: AppColors.accent,
    glass: AppColors.darkGlass,
    shadow: AppColors.darkShadow,
    error: AppColors.error,
    success: AppColors.success,
  );

  /// OLED Pure Black Dark Theme Tokens
  static const AudifiThemeColors oled = AudifiThemeColors(
    background: AppColors.oledBackground,
    surface1: AppColors.darkSurface1,
    surface2: AppColors.darkSurface2,
    textPrimary: AppColors.darkTextPrimary,
    textMuted: AppColors.darkTextMuted,
    accent: AppColors.accent,
    glass: AppColors.darkGlass,
    shadow: AppColors.darkShadow,
    error: AppColors.error,
    success: AppColors.success,
  );

  @override
  AudifiThemeColors copyWith({
    Color? background,
    Color? surface1,
    Color? surface2,
    Color? textPrimary,
    Color? textMuted,
    Color? accent,
    Color? glass,
    Color? shadow,
    Color? error,
    Color? success,
  }) {
    return AudifiThemeColors(
      background: background ?? this.background,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      glass: glass ?? this.glass,
      shadow: shadow ?? this.shadow,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  AudifiThemeColors lerp(ThemeExtension<AudifiThemeColors>? other, double t) {
    if (other is! AudifiThemeColors) return this;
    if (identical(this, other)) return this;
    return AudifiThemeColors(
      background: background == other.background
          ? background
          : (Color.lerp(background, other.background, t) ?? background),
      surface1: surface1 == other.surface1
          ? surface1
          : (Color.lerp(surface1, other.surface1, t) ?? surface1),
      surface2: surface2 == other.surface2
          ? surface2
          : (Color.lerp(surface2, other.surface2, t) ?? surface2),
      textPrimary: textPrimary == other.textPrimary
          ? textPrimary
          : (Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary),
      textMuted: textMuted == other.textMuted
          ? textMuted
          : (Color.lerp(textMuted, other.textMuted, t) ?? textMuted),
      accent: accent == other.accent
          ? accent
          : (Color.lerp(accent, other.accent, t) ?? accent),
      glass: glass == other.glass
          ? glass
          : (Color.lerp(glass, other.glass, t) ?? glass),
      shadow: shadow == other.shadow
          ? shadow
          : (Color.lerp(shadow, other.shadow, t) ?? shadow),
      error: error == other.error
          ? error
          : (Color.lerp(error, other.error, t) ?? error),
      success: success == other.success
          ? success
          : (Color.lerp(success, other.success, t) ?? success),
    );
  }
}

/// Convenience extension on [BuildContext] to access [AudifiThemeColors].
extension AudifiThemeColorsExtension on BuildContext {
  AudifiThemeColors get audifiColors =>
      Theme.of(this).extension<AudifiThemeColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AudifiThemeColors.dark
          : AudifiThemeColors.light);
}

/// Selectable accent color definition matching the 6 options in `accent_colour.png` and `audifi.html`.
class AudifiAccent {
  const AudifiAccent({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;

  static const AudifiAccent defaultPurple = AudifiAccent(
    id: 'purple',
    name: 'Default (Purple)',
    color: Color(0xFF8B5CF6),
  );

  static const AudifiAccent red = AudifiAccent(
    id: 'red',
    name: 'Red',
    color: Color(0xFFBD3535),
  );

  static const AudifiAccent indigo = AudifiAccent(
    id: 'indigo',
    name: 'Indigo',
    color: Color(0xFF4F5BFF),
  );

  static const AudifiAccent purple = defaultPurple;

  static const AudifiAccent cyan = AudifiAccent(
    id: 'cyan',
    name: 'Cyan',
    color: Color(0xFF06B6D4),
  );

  static const AudifiAccent green = AudifiAccent(
    id: 'green',
    name: 'Green',
    color: Color(0xFF22C55E),
  );

  static const AudifiAccent orange = AudifiAccent(
    id: 'orange',
    name: 'Orange',
    color: Color(0xFFF97316),
  );

  /// Backward-compatible alias for [red].
  static const AudifiAccent defaultRed = red;

  /// Backward-compatible alias for [indigo].
  static const AudifiAccent defaultIndigo = indigo;

  static const List<AudifiAccent> options = [
    defaultPurple,
    red,
    indigo,
    cyan,
    green,
    orange,
  ];

  static AudifiAccent fromId(String id) {
    return options.firstWhere((a) => a.id == id, orElse: () => defaultPurple);
  }
}
