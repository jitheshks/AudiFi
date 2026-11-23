import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Centralized Material 3 ThemeData configuration for Audifi.
abstract final class AppTheme {
  static final Map<Color, ThemeData> _lightThemeCache = {};
  static final Map<Color, ThemeData> _darkThemeCache = {};
  static final Map<Color, ThemeData> _oledThemeCache = {};

  /// Audifi Light Theme getter
  static ThemeData get lightTheme => lightThemeWith();

  /// Audifi Dark Theme getter
  static ThemeData get darkTheme => darkThemeWith();

  /// Audifi OLED Pure Black Dark Theme getter
  static ThemeData get oledTheme => oledThemeWith();

  /// Audifi Light Theme with optional accent color
  static ThemeData lightThemeWith([Color? accent]) {
    final effectiveAccent = accent ?? AppColors.accent;
    return _lightThemeCache.putIfAbsent(
      effectiveAccent,
      () => _buildLightTheme(effectiveAccent),
    );
  }

  static ThemeData _buildLightTheme(Color effectiveAccent) {
    final textTheme = AppTypography.createTextTheme(
      primaryColor: AppColors.lightTextPrimary,
      mutedColor: AppColors.lightTextMuted,
    );

    final colorScheme = const ColorScheme.light().copyWith(
      primary: effectiveAccent,
      onPrimary: Colors.white,
      secondary: AppColors.lightSurface2,
      onSecondary: AppColors.lightTextPrimary,
      surface: AppColors.lightSurface1,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        AudifiThemeColors.light.copyWith(accent: effectiveAccent),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h2.copyWith(
          color: AppColors.lightTextPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface1,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface1,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusLg,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusLg,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusLg,
          borderSide: BorderSide(color: effectiveAccent, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.lightTextMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: effectiveAccent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.nav.copyWith(
              color: effectiveAccent,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.nav.copyWith(color: AppColors.lightTextMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: effectiveAccent, size: 24);
          }
          return const IconThemeData(color: AppColors.lightTextMuted, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightSurface2,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Audifi Dark Theme with optional accent color
  static ThemeData darkThemeWith([Color? accent]) {
    final effectiveAccent = accent ?? AppColors.accent;
    return _darkThemeCache.putIfAbsent(
      effectiveAccent,
      () => _buildDarkTheme(effectiveAccent),
    );
  }

  static ThemeData _buildDarkTheme(Color effectiveAccent) {
    final textTheme = AppTypography.createTextTheme(
      primaryColor: AppColors.darkTextPrimary,
      mutedColor: AppColors.darkTextMuted,
    );

    final colorScheme = const ColorScheme.dark().copyWith(
      primary: effectiveAccent,
      onPrimary: Colors.white,
      secondary: AppColors.darkSurface2,
      onSecondary: AppColors.darkTextPrimary,
      surface: AppColors.darkSurface1,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        AudifiThemeColors.dark.copyWith(accent: effectiveAccent),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h2.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface1,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface1,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusLg,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusLg,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusLg,
          borderSide: BorderSide(color: effectiveAccent, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.darkTextMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: effectiveAccent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.nav.copyWith(
              color: effectiveAccent,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.nav.copyWith(color: AppColors.darkTextMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: effectiveAccent, size: 24);
          }
          return const IconThemeData(color: AppColors.darkTextMuted, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkSurface2,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Audifi OLED Pure Black Dark Theme with optional accent color
  static ThemeData oledThemeWith([Color? accent]) {
    final effectiveAccent = accent ?? AppColors.accent;
    return _oledThemeCache.putIfAbsent(effectiveAccent, () {
      final baseDark = darkThemeWith(effectiveAccent);
      return baseDark.copyWith(
        scaffoldBackgroundColor: AppColors.oledBackground,
        appBarTheme: baseDark.appBarTheme.copyWith(
          backgroundColor: AppColors.oledBackground,
        ),
        extensions: <ThemeExtension<dynamic>>[
          AudifiThemeColors.oled.copyWith(accent: effectiveAccent),
        ],
      );
    });
  }
}
