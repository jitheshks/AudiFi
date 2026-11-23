import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/core/theme/app_theme.dart';
import 'package:audifi/core/theme/app_typography.dart';
import 'package:audifi/core/theme/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppTheme', () {
    test('light theme provides expected colors and tokens', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(theme.colorScheme.primary, AppColors.accent);

      final extension = theme.extension<AudifiThemeColors>();
      expect(extension, isNotNull);
      expect(extension!.background, AppColors.lightBackground);
      expect(extension.surface1, AppColors.lightSurface1);
      expect(extension.surface2, AppColors.lightSurface2);
      expect(extension.textPrimary, AppColors.lightTextPrimary);
      expect(extension.textMuted, AppColors.lightTextMuted);
      expect(extension.accent, AppColors.accent);
    });

    test('dark theme provides expected colors and tokens', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(theme.colorScheme.primary, AppColors.accent);

      final extension = theme.extension<AudifiThemeColors>();
      expect(extension, isNotNull);
      expect(extension!.background, AppColors.darkBackground);
      expect(extension.surface1, AppColors.darkSurface1);
      expect(extension.surface2, AppColors.darkSurface2);
      expect(extension.textPrimary, AppColors.darkTextPrimary);
      expect(extension.textMuted, AppColors.darkTextMuted);
    });

    test('oled theme uses pure black background', () {
      final theme = AppTheme.oledTheme;
      expect(theme.scaffoldBackgroundColor, AppColors.oledBackground);
      final extension = theme.extension<AudifiThemeColors>();
      expect(extension!.background, AppColors.oledBackground);
    });

    test('typography styles match design specifications', () {
      expect(AppTypography.h1.fontSize, 32.0);
      expect(AppTypography.h2.fontSize, 20.0);
      expect(AppTypography.h3.fontSize, 18.0);
      expect(AppTypography.body.fontSize, 15.0);
      expect(AppTypography.pill.fontSize, 14.0);
      expect(AppTypography.caption.fontSize, 12.0);
    });

    test('theme caches return memoized identical ThemeData references', () {
      final dark1 = AppTheme.darkThemeWith(AppColors.accent);
      final dark2 = AppTheme.darkThemeWith(AppColors.accent);
      expect(identical(dark1, dark2), isTrue);

      final oled1 = AppTheme.oledThemeWith(AppColors.accent);
      final oled2 = AppTheme.oledThemeWith(AppColors.accent);
      expect(identical(oled1, oled2), isTrue);

      // Verify oledTheme shares sub-objects with darkTheme for O(1) lerp performance
      expect(identical(oled1.textTheme, dark1.textTheme), isTrue);
      expect(oled1.colorScheme, equals(dark1.colorScheme));

      // Verify different accent returns distinct theme with matching primary/accent
      const customAccent = Color(0xFF4F5BFF);
      final darkCustom = AppTheme.darkThemeWith(customAccent);
      expect(identical(darkCustom, dark1), isFalse);
      expect(darkCustom.colorScheme.primary, customAccent);
      expect(darkCustom.extension<AudifiThemeColors>()?.accent, customAccent);

      final lightCustom = AppTheme.lightThemeWith(customAccent);
      expect(lightCustom.colorScheme.primary, customAccent);
      expect(lightCustom.extension<AudifiThemeColors>()?.accent, customAccent);

      final oledCustom = AppTheme.oledThemeWith(customAccent);
      expect(oledCustom.colorScheme.primary, customAccent);
      expect(oledCustom.extension<AudifiThemeColors>()?.accent, customAccent);
    });

    test('AudifiThemeColors.lerp preserves identical properties without reallocation', () {
      final darkColors = AudifiThemeColors.dark;
      final oledColors = AudifiThemeColors.oled;

      final lerped = darkColors.lerp(oledColors, 0.5);
      expect(identical(lerped.surface1, darkColors.surface1), isTrue);
      expect(identical(lerped.surface2, darkColors.surface2), isTrue);
      expect(identical(lerped.textPrimary, darkColors.textPrimary), isTrue);
      expect(identical(lerped.textMuted, darkColors.textMuted), isTrue);
      expect(identical(lerped.accent, darkColors.accent), isTrue);
    });
  });

  group('ThemeModeNotifier & OledModeNotifier', () {
    test('themeModeNotifier updates state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('oledModeNotifier updates state correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(oledModeProvider), isFalse);

      container.read(oledModeProvider.notifier).setOled(true);
      expect(container.read(oledModeProvider), isTrue);

      container.read(oledModeProvider.notifier).toggle();
      expect(container.read(oledModeProvider), isFalse);
    });
  });

  group('AudifiAccent & AppColors.accent', () {
    test('AppColors.accent matches Audius purple #8B5CF6', () {
      expect(AppColors.accent, const Color(0xFF8B5CF6));
      expect(AppColors.accentLight, const Color(0xFFA78BFA));
      expect(AppColors.accentDark, const Color(0xFF7C3AED));
    });

    test('AudifiAccent.defaultPurple is the first option with id purple', () {
      expect(AudifiAccent.options.length, 6);
      expect(AudifiAccent.options.first, AudifiAccent.defaultPurple);
      expect(AudifiAccent.defaultPurple.id, 'purple');
      expect(AudifiAccent.defaultPurple.name, 'Default (Purple)');
      expect(AudifiAccent.defaultPurple.color, const Color(0xFF8B5CF6));
    });

    test('AudifiAccent provides 6 distinct preset colors', () {
      final colorValues = AudifiAccent.options
          .map((a) => a.color.toARGB32())
          .toSet();
      expect(colorValues.length, 6);
      expect(AudifiAccent.options.map((a) => a.id).toSet().length, 6);
    });

    test('AudifiAccent.fromId resolves valid ids and defaults unknown to defaultPurple', () {
      expect(AudifiAccent.fromId('red'), AudifiAccent.red);
      expect(AudifiAccent.fromId('indigo'), AudifiAccent.indigo);
      expect(AudifiAccent.fromId('purple'), AudifiAccent.purple);
      expect(AudifiAccent.fromId('cyan'), AudifiAccent.cyan);
      expect(AudifiAccent.fromId('green'), AudifiAccent.green);
      expect(AudifiAccent.fromId('orange'), AudifiAccent.orange);
      expect(AudifiAccent.fromId('unknown'), AudifiAccent.defaultPurple);
      expect(AudifiAccent.fromId(''), AudifiAccent.defaultPurple);
    });

    test('AudifiAccent.defaultIndigo and defaultRed maintain backwards compatibility', () {
      expect(AudifiAccent.defaultIndigo, AudifiAccent.indigo);
      expect(AudifiAccent.defaultRed, AudifiAccent.red);
    });
  });

  group('AccentColorNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to AudifiAccent.defaultPurple', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(accentColorProvider), AudifiAccent.defaultPurple);
    });

    test('setAccent updates state and persists id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(accentColorProvider.notifier)
          .setAccent(AudifiAccent.cyan);

      expect(container.read(accentColorProvider), AudifiAccent.cyan);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('audifi_pref_accent_color'), 'cyan');
    });

    test(
      'loads persisted accent from SharedPreferences on initialization',
      () async {
        SharedPreferences.setMockInitialValues({
          'audifi_pref_accent_color': 'purple',
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Trigger build and wait for async _load
        container.read(accentColorProvider);
        await pumpEventQueue();

        expect(container.read(accentColorProvider), AudifiAccent.purple);
      },
    );
  });
}
