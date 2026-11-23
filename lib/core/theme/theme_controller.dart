import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../storage/storage_providers.dart';
import 'app_colors.dart';

/// Riverpod Notifier managing the application's [ThemeMode].
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _storageKey = 'audifi_pref_theme_mode';

  @override
  ThemeMode build() {
    final preloaded = getPreloadedSharedPreferences();
    if (preloaded != null) {
      final raw = preloaded.getString(_storageKey);
      if (raw == 'dark') return ThemeMode.dark;
      if (raw == 'light') return ThemeMode.light;
      if (raw == 'system') return ThemeMode.system;
    }
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        if (raw == 'dark') state = ThemeMode.dark;
        if (raw == 'light') state = ThemeMode.light;
        if (raw == 'system') state = ThemeMode.system;
      }
    } catch (_) {}
  }

  /// Explicitly sets the active [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      await prefs.setString(_storageKey, mode.name);
    } catch (_) {}
  }

  /// Toggles between light and dark modes.
  void toggleTheme() {
    setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Provider for accessing and modifying the [ThemeMode].
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Riverpod Notifier managing OLED pure black mode for dark theme.
class OledModeNotifier extends Notifier<bool> {
  static const String _storageKey = 'audifi_pref_oled';

  @override
  bool build() {
    final preloaded = getPreloadedSharedPreferences();
    if (preloaded != null) {
      final val = preloaded.getBool(_storageKey);
      if (val != null) return val;
    }
    _load();
    return false;
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      final val = prefs.getBool(_storageKey);
      if (val != null) state = val;
    } catch (_) {}
  }

  /// Sets OLED pure black mode on or off.
  Future<void> setOled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      await prefs.setBool(_storageKey, enabled);
    } catch (_) {}
  }

  /// Toggles OLED pure black mode.
  void toggle() {
    setOled(!state);
  }
}

/// Provider for accessing and modifying OLED pure black mode.
final oledModeProvider = NotifierProvider<OledModeNotifier, bool>(
  OledModeNotifier.new,
);

/// Riverpod Notifier managing the selected [AudifiAccent].
class AccentColorNotifier extends Notifier<AudifiAccent> {
  static const String _storageKey = 'audifi_pref_accent_color';

  @override
  AudifiAccent build() {
    final preloaded = getPreloadedSharedPreferences();
    if (preloaded != null) {
      final id = preloaded.getString(_storageKey);
      if (id != null) {
        return AudifiAccent.fromId(id);
      }
    }
    _load();
    return AudifiAccent.defaultPurple;
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      final id = prefs.getString(_storageKey);
      if (id != null) {
        state = AudifiAccent.fromId(id);
      }
    } catch (_) {}
  }

  /// Updates the application's active accent color and persists choice.
  Future<void> setAccent(AudifiAccent accent) async {
    state = accent;
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      await prefs.setString(_storageKey, accent.id);
    } catch (_) {}
  }
}

/// Provider for accessing and modifying the selected [AudifiAccent].
final accentColorProvider = NotifierProvider<AccentColorNotifier, AudifiAccent>(
  AccentColorNotifier.new,
);

/// Riverpod Notifier managing animation motion preference ('Full' or 'Reduced').
class AnimationModeNotifier extends Notifier<String> {
  static const String _storageKey = 'audifi_pref_animation_mode';

  @override
  String build() {
    _load();
    return 'Full';
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      final val = prefs.getString(_storageKey);
      if (val != null) state = val;
    } catch (_) {}
  }

  /// Sets animation mode ('Full' or 'Reduced').
  Future<void> setMode(String mode) async {
    state = mode;
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      await prefs.setString(_storageKey, mode);
    } catch (_) {}
  }

  /// Toggles between Full and Reduced.
  void toggle() {
    setMode(state == 'Full' ? 'Reduced' : 'Full');
  }
}

/// Provider for animation mode preference ('Full' or 'Reduced').
final animationModeProvider = NotifierProvider<AnimationModeNotifier, String>(
  AnimationModeNotifier.new,
);

/// Convenience provider indicating whether reduced motion is active.
final isReducedMotionProvider = Provider<bool>((ref) {
  final mode = ref.watch(animationModeProvider);
  return mode.toLowerCase() == 'reduced';
});
