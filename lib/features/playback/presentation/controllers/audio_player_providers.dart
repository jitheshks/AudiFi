import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/services/audifi_audio_handler.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/just_audio_player_service.dart';

import 'package:just_audio/just_audio.dart';

/// Top-level references to singletons initialized during application bootstrap.
AudioHandler? _bootstrapAudioHandler;
AudioPlayerService? _bootstrapAudioPlayerService;

/// Returns true if bootstrap audio services have already been initialized.
bool get isBootstrapAudioInitialized =>
    _bootstrapAudioHandler != null && _bootstrapAudioPlayerService != null;

/// Returns the singleton [AudioHandler] initialized at bootstrap, if available.
AudioHandler? getBootstrapAudioHandler() => _bootstrapAudioHandler;

/// Returns the singleton [AudioPlayerService] initialized at bootstrap, if available.
AudioPlayerService? getBootstrapAudioPlayerService() =>
    _bootstrapAudioPlayerService;

/// Sets bootstrap audio singletons. Called during application bootstrapping.
/// Guarantees idempotency: will not overwrite active services unless [allowOverwrite] is true.
void setBootstrapAudioServices({
  required AudioHandler audioHandler,
  required AudioPlayerService audioPlayerService,
  bool allowOverwrite = false,
}) {
  if (_bootstrapAudioHandler != null && !allowOverwrite) {
    AppLogger.warning(
      'Bootstrap audio services already initialized; duplicate registration ignored',
      tag: 'Playback',
    );
    return;
  }
  _bootstrapAudioHandler = audioHandler;
  _bootstrapAudioPlayerService = audioPlayerService;
}

/// Resets bootstrap audio singletons (primarily used in test teardowns).
void resetBootstrapAudioServices() {
  _bootstrapAudioHandler = null;
  _bootstrapAudioPlayerService = null;
}

/// Riverpod provider delivering the single application-level [AudioPlayerService].
/// Can be overridden in tests with a fake or mock service.
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  if (_bootstrapAudioPlayerService != null) {
    final service = _bootstrapAudioPlayerService!;
    if (service is JustAudioPlayerService) {
      service.setShouldPauseOnHeadphoneDisconnect(
        () => ref.read(settingsControllerProvider).pauseOnHeadphonesDisconnect,
      );
    }
    return service;
  }

  // In automated tests where neither bootstrap singletons nor explicit overrides
  // are provided, supply a lightweight in-memory fallback to avoid unmocked platform channels.
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return _NoopAudioPlayerService();
  }

  try {
    final service = JustAudioPlayerService(
      shouldPauseOnHeadphoneDisconnect: () {
        return ref.read(settingsControllerProvider).pauseOnHeadphonesDisconnect;
      },
    );
    ref.onDispose(() => service.dispose());
    return service;
  } catch (_) {
    return _NoopAudioPlayerService();
  }
});

/// Riverpod provider delivering the single application-level [AudioHandler].
/// Can be overridden in tests with a fake or mock service.
final audioHandlerProvider = Provider<AudioHandler>((ref) {
  if (_bootstrapAudioHandler != null) {
    return _bootstrapAudioHandler!;
  }

  final playerService = ref.watch(audioPlayerServiceProvider);
  final handler = AudifiAudioHandler(playerService: playerService);
  ref.onDispose(() => handler.dispose());
  return handler;
});

/// Lightweight no-op fallback used in tests when platform binary
/// messengers and audio channels are uninitialized.
class _NoopAudioPlayerService implements AudioPlayerService {
  @override
  Stream<EngineProcessingState> get processingStateStream =>
      const Stream.empty();

  @override
  Stream<bool> get playingStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<void> get completedStream => const Stream.empty();

  @override
  Duration get currentPosition => Duration.zero;

  @override
  Duration? get currentDuration => null;

  @override
  bool get isPlaying => false;

  @override
  Future<void> setAudioUrl(String url) async {}

  @override
  Future<void> setAudioSource(AudioSource source) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {}
}
