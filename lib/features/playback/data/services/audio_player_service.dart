import 'package:just_audio/just_audio.dart';

/// Abstract engine status emitted by underlying audio player implementations.
enum EngineProcessingState { idle, loading, buffering, ready, completed }

/// Abstract audio player service decoupling the audio engine (e.g. `just_audio`)
/// from state management and presentation layers for complete testability.
abstract interface class AudioPlayerService {
  /// Stream emitting real-time engine processing states.
  Stream<EngineProcessingState> get processingStateStream;

  /// Stream emitting real-time play/pause state changes.
  Stream<bool> get playingStream;

  /// Stream emitting real-time elapsed playback position updates.
  Stream<Duration> get positionStream;

  /// Stream emitting real-time buffered stream duration.
  Stream<Duration> get bufferedPositionStream;

  /// Stream emitting audio file duration when loaded.
  Stream<Duration?> get durationStream;

  /// Stream emitting when the currently playing track completes.
  Stream<void> get completedStream;

  /// Synchronous snapshot of current playback position.
  Duration get currentPosition;

  /// Synchronous snapshot of current track duration.
  Duration? get currentDuration;

  /// Whether the player is actively playing audio.
  bool get isPlaying;

  /// Loads and prepares an audio stream from [url].
  Future<void> setAudioUrl(String url);

  /// Loads and prepares audio directly from an [AudioSource] (e.g. [PrebufferedAudioSource]).
  Future<void> setAudioSource(AudioSource source);

  /// Starts or resumes audio playback.
  Future<void> play();

  /// Pauses active playback without resetting position.
  Future<void> pause();

  /// Seeks playback to the specified [position].
  Future<void> seek(Duration position);

  /// Stops audio playback and resets the engine.
  Future<void> stop();

  /// Adjusts player volume in range [0.0 - 1.0].
  Future<void> setVolume(double volume);

  /// Sets audio playback speed multiplier.
  Future<void> setSpeed(double speed);

  /// Releases resources held by the audio engine.
  Future<void> dispose();
}
