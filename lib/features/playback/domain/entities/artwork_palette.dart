import 'dart:ui';

import '../../../../core/theme/app_colors.dart';

/// Immutable model representing the adaptive color palette extracted from track artwork.
/// Drives the ambient background glow of the Now Playing screen.
class ArtworkPalette {
  const ArtworkPalette({
    required this.dominant,
    required this.secondary,
    required this.accent,
    required this.background,
    this.isFallback = false,
  });

  /// Primary dominant color of the artwork.
  final Color dominant;

  /// Harmonious secondary color complementing the dominant hue.
  final Color secondary;

  /// Vibrant accent color for subtle highlights.
  final Color accent;

  /// Background-compatible color tuned for ambient backdrop blending.
  final Color background;

  /// Whether this palette is a fallback rather than extracted from live artwork.
  final bool isFallback;

  /// Generates a theme-aware fallback palette when artwork is absent or extraction fails.
  factory ArtworkPalette.fallback({
    required Brightness brightness,
    required AudifiThemeColors colors,
  }) {
    final isDark = brightness == Brightness.dark;
    return ArtworkPalette(
      dominant: isDark ? const Color(0xFF2C2F48) : const Color(0xFFD6D9F0),
      secondary: isDark ? const Color(0xFF1E2033) : const Color(0xFFE2E4F2),
      accent: colors.accent,
      background: colors.background,
      isFallback: true,
    );
  }

  /// Linearly interpolates between two [ArtworkPalette] instances for smooth transitions.
  static ArtworkPalette lerp(ArtworkPalette a, ArtworkPalette b, double t) {
    return ArtworkPalette(
      dominant: Color.lerp(a.dominant, b.dominant, t) ?? b.dominant,
      secondary: Color.lerp(a.secondary, b.secondary, t) ?? b.secondary,
      accent: Color.lerp(a.accent, b.accent, t) ?? b.accent,
      background: Color.lerp(a.background, b.background, t) ?? b.background,
      isFallback: t < 0.5 ? a.isFallback : b.isFallback,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtworkPalette &&
          runtimeType == other.runtimeType &&
          dominant == other.dominant &&
          secondary == other.secondary &&
          accent == other.accent &&
          background == other.background &&
          isFallback == other.isFallback;

  @override
  int get hashCode =>
      Object.hash(dominant, secondary, accent, background, isFallback);

  @override
  String toString() =>
      'ArtworkPalette(dominant: $dominant, secondary: $secondary, accent: $accent, isFallback: $isFallback)';
}
