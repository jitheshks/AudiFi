import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';

class SettingsState {
  const SettingsState({
    this.pauseOnHeadphonesDisconnect = true,
    this.dynamicColors = true,
    this.streamQuality = '320 kbps (High)',
    this.streamOnMobileData = true,
  });

  final bool pauseOnHeadphonesDisconnect;
  final bool dynamicColors;
  final String streamQuality;
  final bool streamOnMobileData;

  SettingsState copyWith({
    bool? pauseOnHeadphonesDisconnect,
    bool? dynamicColors,
    String? streamQuality,
    bool? streamOnMobileData,
  }) {
    return SettingsState(
      pauseOnHeadphonesDisconnect:
          pauseOnHeadphonesDisconnect ?? this.pauseOnHeadphonesDisconnect,
      dynamicColors: dynamicColors ?? this.dynamicColors,
      streamQuality: streamQuality ?? this.streamQuality,
      streamOnMobileData: streamOnMobileData ?? this.streamOnMobileData,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  static const String _keyPauseDisconnect = 'audifi_pref_pause_disconnect';
  static const String _keyDynamicColors = 'audifi_pref_dynamic_colors';
  static const String _keyStreamMobileData = 'audifi_pref_stream_mobile_data';
  bool _isLoaded = false;

  @override
  SettingsState build() {
    _loadPreferences();
    return const SettingsState();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      if (!_isLoaded) {
        final pause = prefs.getBool(_keyPauseDisconnect) ?? true;
        final dynamicColors = prefs.getBool(_keyDynamicColors) ?? true;
        final streamMobile = prefs.getBool(_keyStreamMobileData) ?? true;
        state = state.copyWith(
          pauseOnHeadphonesDisconnect: pause,
          dynamicColors: dynamicColors,
          streamOnMobileData: streamMobile,
        );
        _isLoaded = true;
      }
    } catch (_) {}
  }

  Future<void> setPauseOnHeadphonesDisconnect(bool value) async {
    _isLoaded = true;
    state = state.copyWith(pauseOnHeadphonesDisconnect: value);
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      await prefs.setBool(_keyPauseDisconnect, value);
    } catch (_) {}
  }

  Future<void> setDynamicColors(bool value) async {
    _isLoaded = true;
    state = state.copyWith(dynamicColors: value);
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      await prefs.setBool(_keyDynamicColors, value);
    } catch (_) {}
  }

  Future<void> setStreamOnMobileData(bool value) async {
    _isLoaded = true;
    state = state.copyWith(streamOnMobileData: value);
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      await prefs.setBool(_keyStreamMobileData, value);
    } catch (_) {}
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
