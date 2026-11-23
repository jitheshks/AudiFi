import '../../../../core/errors/failure.dart';
import '../../../tracks/domain/entities/track.dart';
import 'repeat_mode.dart';

/// Lifecycle statuses for audio playback.
enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  error,
  completed,
}

/// Pure domain entity modeling the real-time state of audio playback.
class PlaybackState {
  const PlaybackState({
    this.currentTrack,
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.repeatMode = RepeatMode.off,
    this.isShuffleEnabled = false,
    this.error,
  });

  /// Currently active track, or null if nothing is loaded.
  final Track? currentTrack;

  /// Current engine playback status.
  final PlaybackStatus status;

  /// Current playback elapsed position.
  final Duration position;

  /// Total duration of the current audio track.
  final Duration duration;

  /// Buffered audio duration for network streaming.
  final Duration bufferedPosition;

  /// Audio volume multiplier [0.0 - 1.0].
  final double volume;

  /// Audio playback rate multiplier (e.g. 1.0 = normal).
  final double speed;

  /// Active repeat setting.
  final RepeatMode repeatMode;

  /// Whether queue shuffle is currently active.
  final bool isShuffleEnabled;

  /// Optional failure information if playback or stream resolution failed.
  final Failure? error;

  /// Initial empty state.
  static const PlaybackState initial = PlaybackState();

  /// Whether audio is actively playing.
  bool get isPlaying => status == PlaybackStatus.playing;

  /// Whether playback is actively loading or buffering data.
  bool get isBuffering =>
      status == PlaybackStatus.buffering || status == PlaybackStatus.loading;

  /// Whether an active track is loaded.
  bool get hasTrack => currentTrack != null;

  /// Normalized progress ratio [0.0 - 1.0].
  double get progress {
    if (duration.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Formatted position string (e.g., "1:23").
  String get formattedPosition => _formatDuration(position);

  /// Formatted duration string (e.g., "3:45").
  String get formattedDuration => _formatDuration(duration);

  /// Formatted remaining duration string (e.g., "-2:22").
  String get formattedRemaining {
    final remaining = duration - position;
    if (remaining.isNegative) return '0:00';
    return '-${_formatDuration(remaining)}';
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  PlaybackState copyWith({
    Track? currentTrack,
    bool clearTrack = false,
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    double? speed,
    RepeatMode? repeatMode,
    bool? isShuffleEnabled,
    Failure? error,
    bool clearError = false,
  }) {
    return PlaybackState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackState &&
          runtimeType == other.runtimeType &&
          currentTrack == other.currentTrack &&
          status == other.status &&
          position == other.position &&
          duration == other.duration &&
          bufferedPosition == other.bufferedPosition &&
          volume == other.volume &&
          speed == other.speed &&
          repeatMode == other.repeatMode &&
          isShuffleEnabled == other.isShuffleEnabled &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
    currentTrack,
    status,
    position,
    duration,
    bufferedPosition,
    volume,
    speed,
    repeatMode,
    isShuffleEnabled,
    error,
  );

  @override
  String toString() =>
      'PlaybackState(track: ${currentTrack?.title}, status: $status, pos: $position/$duration)';
}
