import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _preloadedSharedPreferences;

/// Sets the preloaded [SharedPreferences] instance from bootstrap initialization.
void setPreloadedSharedPreferences(SharedPreferences? prefs) {
  _preloadedSharedPreferences = prefs;
}

/// Returns the preloaded [SharedPreferences] if available synchronously.
SharedPreferences? getPreloadedSharedPreferences() =>
    _preloadedSharedPreferences;

/// Centralized provider delivering [SharedPreferences] for local persistence.
final sharedPreferencesAsyncProvider = Provider<Future<SharedPreferences>>((
  ref,
) {
  if (_preloadedSharedPreferences != null) {
    return Future.value(_preloadedSharedPreferences!);
  }
  return SharedPreferences.getInstance();
});
