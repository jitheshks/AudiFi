import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/features/playback/domain/entities/artwork_palette.dart';

void main() {
  group('ArtworkPalette Domain Entity', () {
    test('instantiates with specified colors', () {
      const palette = ArtworkPalette(
        dominant: Color(0xFF112233),
        secondary: Color(0xFF445566),
        accent: Color(0xFF778899),
        background: Color(0xFFAABBCC),
        isFallback: false,
      );

      expect(palette.dominant, equals(const Color(0xFF112233)));
      expect(palette.secondary, equals(const Color(0xFF445566)));
      expect(palette.accent, equals(const Color(0xFF778899)));
      expect(palette.background, equals(const Color(0xFFAABBCC)));
      expect(palette.isFallback, isFalse);
    });

    test('value equality and hashCode match for identical colors', () {
      const paletteA = ArtworkPalette(
        dominant: Color(0xFF112233),
        secondary: Color(0xFF445566),
        accent: Color(0xFF778899),
        background: Color(0xFFAABBCC),
      );

      const paletteB = ArtworkPalette(
        dominant: Color(0xFF112233),
        secondary: Color(0xFF445566),
        accent: Color(0xFF778899),
        background: Color(0xFFAABBCC),
      );

      expect(paletteA, equals(paletteB));
      expect(paletteA.hashCode, equals(paletteB.hashCode));
    });

    test('fallback palette provides appropriate colors for light theme', () {
      final fallbackLight = ArtworkPalette.fallback(
        brightness: Brightness.light,
        colors: AudifiThemeColors.light,
      );

      expect(fallbackLight.isFallback, isTrue);
      expect(fallbackLight.accent, equals(AudifiThemeColors.light.accent));
      expect(
        fallbackLight.background,
        equals(AudifiThemeColors.light.background),
      );
    });

    test('fallback palette provides appropriate colors for dark theme', () {
      final fallbackDark = ArtworkPalette.fallback(
        brightness: Brightness.dark,
        colors: AudifiThemeColors.dark,
      );

      expect(fallbackDark.isFallback, isTrue);
      expect(fallbackDark.accent, equals(AudifiThemeColors.dark.accent));
      expect(
        fallbackDark.background,
        equals(AudifiThemeColors.dark.background),
      );
    });

    test('lerp smoothly interpolates between two palettes', () {
      const p1 = ArtworkPalette(
        dominant: Color(0xFF000000),
        secondary: Color(0xFF000000),
        accent: Color(0xFF000000),
        background: Color(0xFF000000),
        isFallback: false,
      );

      const p2 = ArtworkPalette(
        dominant: Color(0xFFFFFFFF),
        secondary: Color(0xFFFFFFFF),
        accent: Color(0xFFFFFFFF),
        background: Color(0xFFFFFFFF),
        isFallback: true,
      );

      final mid = ArtworkPalette.lerp(p1, p2, 0.5);
      // Alpha & RGB channels are halfway interpolated (0x7F or 0x80)
      expect(mid.dominant.r, closeTo(0.5, 0.05));
      expect(mid.secondary.g, closeTo(0.5, 0.05));
      expect(mid.accent.b, closeTo(0.5, 0.05));

      final start = ArtworkPalette.lerp(p1, p2, 0.0);
      expect(start.dominant, equals(p1.dominant));
      expect(start.isFallback, isFalse);

      final end = ArtworkPalette.lerp(p1, p2, 1.0);
      expect(end.dominant, equals(p2.dominant));
      expect(end.isFallback, isTrue);
    });
  });
}
