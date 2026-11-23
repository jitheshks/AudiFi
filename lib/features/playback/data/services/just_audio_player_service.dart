import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import 'audio_player_service.dart';

/// Concrete [AudioPlayerService] backed by the production [AudioPlayer] from `just_audio`
/// and configured with [AudioSession] for platform audio focus, interruption, and ducking management.
class JustAudioPlayerService implements AudioPlayerService {
  JustAudioPlayerService({
    AudioPlayer? player,
    AudioSession? session,
    AudioLoadConfiguration? audioLoadConfiguration,
    bool Function()? shouldPauseOnHeadphoneDisconnect,
  }) : _player =
           player ??
           AudioPlayer(
             audioLoadConfiguration:
                 audioLoadConfiguration ??
                 const AudioLoadConfiguration(
                   androidLoadControl: AndroidLoadControl(
                     minBufferDuration: Duration(seconds: 30),
                     maxBufferDuration: Duration(seconds: 60),
                     bufferForPlaybackDuration: Duration(milliseconds: 300),
                     bufferForPlaybackAfterRebufferDuration: Duration(
                       milliseconds: 600,
                     ),
                     prioritizeTimeOverSizeThresholds: true,
                   ),
                 ),
           ),
       _audioSession = session {
    _shouldPauseOnHeadphoneDisconnect = shouldPauseOnHeadphoneDisconnect;
    _initSubscriptions();
    _sessionInitFuture = _initAudioSession(session);
  }

  final AudioPlayer _player;
  AudioSession? _audioSession;
  Future<void>? _sessionInitFuture;
  bool Function()? _shouldPauseOnHeadphoneDisconnect;

  /// External callback invoked when an interruption requests playback pause.
  Future<void> Function()? onInterruptionPause;

  /// External callback invoked when a transient interruption ends and playback should resume.
  Future<void> Function()? onInterruptionResume;

  /// External callback invoked when headphones disconnect (becoming noisy).
  Future<void> Function()? onBecomingNoisy;

  /// External check returning whether playback is active or intending to play.
  bool Function()? isPlaybackActive;

  /// Stored user volume (0.0 to 1.0) preserved across ducking interruptions.
  double _userVolume = 1.0;

  /// Whether audio is currently ducked due to a transient ducking interruption.
  bool _isDucked = false;

  /// Whether playback was active when a transient interruption started and should auto-resume when it ends.
  bool _playInterrupted = false;

  /// Flag indicating that pause was initiated by an internal interruption handler,
  /// so that _playInterrupted is not cleared by the resulting pause() invocation.
  bool _isHandlingInterruption = false;

  final StreamController<void> _completedController =
      StreamController<void>.broadcast();
  StreamSubscription<ProcessingState>? _processingSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;
  bool _isDisposed = false;

  /// Whether this player service has been disposed and released.
  bool get isDisposed => _isDisposed;

  /// Whether volume is currently ducked.
  @visibleForTesting
  bool get isDucked => _isDucked;

  /// Current user-configured volume (before ducking scale factor).
  @visibleForTesting
  double get userVolume => _userVolume;

  /// Whether playback was actively interrupted and pending auto-resume.
  @visibleForTesting
  bool get isPlayInterrupted => _playInterrupted;

  /// Sets or updates the pause-on-headphone-disconnect preference resolver.
  void setShouldPauseOnHeadphoneDisconnect(bool Function() callback) {
    _shouldPauseOnHeadphoneDisconnect = callback;
  }

  /// Sets coordination callbacks for external integration with AudioHandler or PlaybackController.
  void setInterruptionCallbacks({
    Future<void> Function()? onPause,
    Future<void> Function()? onResume,
    Future<void> Function()? onBecomingNoisy,
    bool Function()? isPlaybackActive,
  }) {
    if (onPause != null) onInterruptionPause = onPause;
    if (onResume != null) onInterruptionResume = onResume;
    if (onBecomingNoisy != null) this.onBecomingNoisy = onBecomingNoisy;
    if (isPlaybackActive != null) this.isPlaybackActive = isPlaybackActive;
  }

  void _initSubscriptions() {
    _processingSub = _player.processingStateStream.listen(
      (state) {
        if (state == ProcessingState.completed) {
          _completedController.add(null);
        }
      },
      onError: (Object error, StackTrace st) {
        AppLogger.warning(
          'Error in player processing state stream',
          tag: 'Playback',
          error: error,
          stackTrace: st,
        );
      },
    );
  }

  Future<void> _initAudioSession([AudioSession? existingSession]) async {
    try {
      final session = existingSession ?? await AudioSession.instance;
      _audioSession = session;
      await session.configure(const AudioSessionConfiguration.music());

      _becomingNoisySub = session.becomingNoisyEventStream.listen(
        (_) => handleBecomingNoisyEvent(),
        onError: (Object error, StackTrace st) {
          AppLogger.warning(
            'Error in audio session becoming noisy stream',
            tag: 'Playback',
            error: error,
            stackTrace: st,
          );
        },
      );

      _interruptionSub = session.interruptionEventStream.listen(
        (event) => handleInterruptionEvent(event),
        onError: (Object error, StackTrace st) {
          AppLogger.warning(
            'Error in audio session interruption stream',
            tag: 'Playback',
            error: error,
            stackTrace: st,
          );
        },
      );
    } catch (e, st) {
      AppLogger.warning(
        'AudioSession initialization failed or unavailable in test environment',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Handles incoming [AudioInterruptionEvent] for ducking, transient pauses, and permanent loss.
  @visibleForTesting
  Future<void> handleInterruptionEvent(AudioInterruptionEvent event) async {
    if (_isDisposed) return;

    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          if (!_isDucked) {
            _isDucked = true;
            final duckedVolume = (_userVolume * 0.5).clamp(0.0, 1.0);
            AppLogger.debug(
              'Audio interruption begin (duck): reducing volume from $_userVolume to $duckedVolume',
              tag: 'Playback',
            );
            await _player.setVolume(duckedVolume);
          }
          break;

        case AudioInterruptionType.pause:
          final wasActive = _isAudiblyActive;
          _playInterrupted = wasActive;
          AppLogger.info(
            'Audio interruption begin (transient pause): wasActive=$wasActive -> pausing playback',
            tag: 'Playback',
          );
          await _handleInterruptionPause();
          break;

        case AudioInterruptionType.unknown:
          // Permanent focus loss: must pause and NEVER auto-resume
          _playInterrupted = false;
          AppLogger.info(
            'Audio interruption begin (permanent focus loss): pausing playback, will not auto-resume',
            tag: 'Playback',
          );
          await _handleInterruptionPause();
          break;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          if (_isDucked) {
            _isDucked = false;
            AppLogger.debug(
              'Audio interruption ended (duck): restoring volume to $_userVolume',
              tag: 'Playback',
            );
            await _player.setVolume(_userVolume);
          }
          break;

        case AudioInterruptionType.pause:
          AppLogger.debug(
            'Audio interruption ended (pause): wasInterrupted=$_playInterrupted',
            tag: 'Playback',
          );
          if (_playInterrupted) {
            _playInterrupted = false;
            AppLogger.info(
              'Resuming playback after transient interruption',
              tag: 'Playback',
            );
            await _handleInterruptionResume();
          } else {
            AppLogger.debug(
              'Interruption ended but playback was not actively interrupted or user paused; staying paused',
              tag: 'Playback',
            );
          }
          break;

        case AudioInterruptionType.unknown:
          AppLogger.debug(
            'Permanent audio focus loss ended; auto-resume is forbidden',
            tag: 'Playback',
          );
          _playInterrupted = false;
          break;
      }
    }
  }

  /// Handles platform becoming-noisy events (e.g. wired/Bluetooth headphones disconnected).
  @visibleForTesting
  Future<void> handleBecomingNoisyEvent() async {
    if (_isDisposed) return;

    final shouldPause = _shouldPauseOnHeadphoneDisconnect?.call() ?? true;
    if (!shouldPause) {
      AppLogger.debug(
        'Audio noisy event received (headphones disconnected) but pause-on-disconnect preference is disabled; continuing playback',
        tag: 'Playback',
      );
      return;
    }

    AppLogger.info(
      'Audio noisy event received (headphones disconnected) and preference enabled -> pausing playback without auto-resume',
      tag: 'Playback',
    );
    // Disconnection is not a transient interruption; do NOT auto-resume if reconnected later
    _playInterrupted = false;
    try {
      if (onBecomingNoisy != null) {
        await onBecomingNoisy!();
      } else {
        await pause();
      }
    } catch (e, st) {
      AppLogger.error(
        'Error pausing playback on becoming noisy event',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
    }
  }

  bool get _isAudiblyActive {
    if (isPlaybackActive != null) {
      try {
        return isPlaybackActive!();
      } catch (_) {}
    }
    return _player.playing ||
        _player.processingState == ProcessingState.buffering ||
        _player.processingState == ProcessingState.loading;
  }

  Future<void> _handleInterruptionPause() async {
    _isHandlingInterruption = true;
    try {
      if (onInterruptionPause != null) {
        await onInterruptionPause!();
      } else {
        await pause();
      }
    } catch (e, st) {
      AppLogger.error(
        'Error executing interruption pause',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
    } finally {
      _isHandlingInterruption = false;
    }
  }

  Future<void> _handleInterruptionResume() async {
    try {
      if (onInterruptionResume != null) {
        await onInterruptionResume!();
      } else {
        await play();
      }
    } catch (e, st) {
      AppLogger.error(
        'Error executing interruption resume',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Stream<EngineProcessingState> get processingStateStream {
    return _player.processingStateStream.map(_mapProcessingState);
  }

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<void> get completedStream => _completedController.stream;

  @override
  Duration get currentPosition => _player.position;

  @override
  Duration? get currentDuration => _player.duration;

  @override
  bool get isPlaying => _player.playing;

  @override
  Future<void> setAudioUrl(String url) async {
    if (_isDisposed) {
      AppLogger.warning(
        'setAudioUrl() ignored on disposed player service',
        tag: 'Playback',
      );
      return;
    }
    try {
      AppLogger.debug(
        'Loading audio into player engine: $url',
        tag: 'Playback',
      );
      if (url.startsWith('/') || url.startsWith('file://')) {
        final filePath = url.startsWith('file://')
            ? Uri.parse(url).toFilePath()
            : url;
        await _player.setFilePath(filePath);
      } else {
        await _player.setUrl(url);
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to set audio URL in engine',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
      throw PlaybackException(message: 'Audio player stream load failed: $e');
    }
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    if (_isDisposed) {
      AppLogger.warning(
        'setAudioSource() ignored on disposed player service',
        tag: 'Playback',
      );
      return;
    }
    try {
      AppLogger.debug(
        'Loading AudioSource into player engine: $source',
        tag: 'Playback',
      );
      await _player.setAudioSource(source);
    } catch (e, st) {
      AppLogger.error(
        'Failed to set AudioSource in engine',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
      throw PlaybackException(message: 'Audio player stream load failed: $e');
    }
  }

  @override
  Future<void> play() async {
    if (_isDisposed) {
      AppLogger.warning(
        'play() ignored on disposed player service',
        tag: 'Playback',
      );
      return;
    }
    _playInterrupted = false;
    try {
      if (_sessionInitFuture != null) {
        await _sessionInitFuture;
      }
      if (_audioSession != null) {
        final activated = await _audioSession!.setActive(true);
        if (!activated) {
          AppLogger.warning(
            'AudioSession.setActive(true) returned false (audio focus denied by OS)',
            tag: 'Playback',
          );
          return;
        }
      }
      await _player.play();
    } catch (e, st) {
      AppLogger.error(
        'Player play() invocation failed',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
      throw PlaybackException(message: 'Audio playback failed: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) return;
    if (!_isHandlingInterruption) {
      // User or controller explicitly initiated pause -> clear interruption auto-resume flag
      _playInterrupted = false;
    }
    try {
      await _player.pause();
    } catch (e, st) {
      AppLogger.error(
        'Player pause() invocation failed',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
      throw PlaybackException(message: 'Audio pause failed: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isDisposed) return;
    try {
      await _player.seek(position);
    } catch (e, st) {
      AppLogger.error(
        'Player seek() failed',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
      throw PlaybackException(message: 'Audio seek failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) return;
    _playInterrupted = false;
    try {
      await _player.stop();
      if (_audioSession != null) {
        try {
          await _audioSession!.setActive(false);
        } catch (_) {}
      }
    } catch (e, st) {
      AppLogger.error(
        'Player stop() failed',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
      throw PlaybackException(message: 'Audio stop failed: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    _userVolume = volume.clamp(0.0, 1.0);
    final targetVolume = _isDucked
        ? (_userVolume * 0.5).clamp(0.0, 1.0)
        : _userVolume;
    await _player.setVolume(targetVolume);
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_isDisposed) return;
    await _player.setSpeed(speed.clamp(0.25, 3.0));
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _playInterrupted = false;
    await _processingSub?.cancel();
    _processingSub = null;
    await _becomingNoisySub?.cancel();
    _becomingNoisySub = null;
    await _interruptionSub?.cancel();
    _interruptionSub = null;
    if (_audioSession != null) {
      try {
        await _audioSession!.setActive(false);
      } catch (_) {}
    }
    if (!_completedController.isClosed) {
      await _completedController.close();
    }
    await _player.dispose();
  }

  static EngineProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return EngineProcessingState.idle;
      case ProcessingState.loading:
        return EngineProcessingState.loading;
      case ProcessingState.buffering:
        return EngineProcessingState.buffering;
      case ProcessingState.ready:
        return EngineProcessingState.ready;
      case ProcessingState.completed:
        return EngineProcessingState.completed;
    }
  }
}
