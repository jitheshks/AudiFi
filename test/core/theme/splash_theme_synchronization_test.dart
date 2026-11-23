import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:audifi/core/storage/storage_providers.dart';
import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/core/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Native Splash Theme Synchronization & Preloading', () {
    tearDown(() {
      setPreloadedSharedPreferences(null);
    });

    test(
      'ThemeModeNotifier defaults to ThemeMode.system when no prefs preloaded',
      () {
        setPreloadedSharedPreferences(null);
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(themeModeProvider), equals(ThemeMode.system));
      },
    );

    test(
      'ThemeModeNotifier resolves dark mode synchronously from preloaded prefs',
      () async {
        SharedPreferences.setMockInitialValues({
          'audifi_pref_theme_mode': 'dark',
        });
        final prefs = await SharedPreferences.getInstance();
        setPreloadedSharedPreferences(prefs);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Must be synchronously dark on the very first read (no async lag)
        expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      },
    );

    test('ThemeModeNotifier resolves light mode synchronously from preloaded prefs', () async {
      SharedPreferences.setMockInitialValues({
        'audifi_pref_theme_mode': 'light',
      });
      final prefs = await SharedPreferences.getInstance();
      setPreloadedSharedPreferences(prefs);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Must be synchronously light on the very first read
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    test('OledModeNotifier resolves OLED preference synchronously from preloaded prefs', () async {
      SharedPreferences.setMockInitialValues({'audifi_pref_oled': true});
      final prefs = await SharedPreferences.getInstance();
      setPreloadedSharedPreferences(prefs);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(oledModeProvider), isTrue);
    });

    test('AccentColorNotifier resolves accent preference synchronously from preloaded prefs', () async {
      SharedPreferences.setMockInitialValues({
        'audifi_pref_accent_color': 'cyan',
      });
      final prefs = await SharedPreferences.getInstance();
      setPreloadedSharedPreferences(prefs);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(accentColorProvider), equals(AudifiAccent.cyan));
    });
  });

  group('Splash Screen Assets Integrity & Independence', () {
    test('launcher icon is preserved and independent of splash assets', () {
      final launcherIcon = File('assets/icon/app_icon.png');
      expect(launcherIcon.existsSync(), isTrue);
      expect(launcherIcon.lengthSync(), greaterThan(100000));
    });

    test(
      'dedicated light and dark splash assets exist under assets/splash/',
      () {
        final splashLight = File('assets/splash/splash_light.png');
        final splashDark = File('assets/splash/splash_dark.png');
        final a12SplashLight = File('assets/splash/splash_android12_light.png');
        final a12SplashDark = File('assets/splash/splash_android12_dark.png');

        expect(splashLight.existsSync(), isTrue);
        expect(splashDark.existsSync(), isTrue);
        expect(a12SplashLight.existsSync(), isTrue);
        expect(a12SplashDark.existsSync(), isTrue);
      },
    );

    test('Android native styles define theme-matched backgrounds', () {
      final stylesLight = File('android/app/src/main/res/values/styles.xml');
      final stylesDark = File(
        'android/app/src/main/res/values-night/styles.xml',
      );
      final stylesA12Light = File(
        'android/app/src/main/res/values-v31/styles.xml',
      );
      final stylesA12Dark = File(
        'android/app/src/main/res/values-night-v31/styles.xml',
      );

      expect(stylesLight.existsSync(), isTrue);
      expect(stylesDark.existsSync(), isTrue);
      expect(stylesA12Light.existsSync(), isTrue);
      expect(stylesA12Dark.existsSync(), isTrue);

      final a12LightContent = stylesA12Light.readAsStringSync();
      final a12DarkContent = stylesA12Dark.readAsStringSync();

      expect(a12LightContent, contains('#F4F1EC'));
      expect(a12LightContent, contains('windowSplashScreenBackground'));
      expect(a12DarkContent, contains('#0B0B0D'));
      expect(a12DarkContent, contains('windowSplashScreenBackground'));
    });
  });
}
