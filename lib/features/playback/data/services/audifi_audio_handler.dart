import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../domain/entities/repeat_mode.dart';
import 'audio_player_service.dart';
import 'just_audio_player_service.dart';

/// Contract for coordinating audio playback actions initiated from system media controls
/// (notification, lock-screen, Bluetooth, Android Auto) with the application's
/// [PlaybackController] and [QueueController].
abstract interface class AudioHandlerPlaybackActions {
  bool get isActivelyPlayingOrLoading;
  Future<void> play();
  Future<void> pause();
  Future<void> togglePlayPause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> skipToQueueItem(int index);
  Future<void> setRepeatMode(RepeatMode repeatMode);
  Future<void> setShuffleMode(bool enabled);
}

/// Production [AudioHandler] connecting Flutter's audio engine with the operating
/// system's media session, notification tray, lock-screen, and Bluetooth controls.
///
/// Implements [BaseAudioHandler] with [SeekHandler] and [QueueHandler].
/// Exactly ONE underlying [AudioPlayerService] instance is utilized across the app.
/// Remains completely functional and autonomous even when Flutter UI screens are detached.
class AudifiAudioHandler extends BaseAudioHandler
    with SeekHandler, QueueHandler {
  AudifiAudioHandler({required this.playerService, this.streamResolver}) {
    _initEngineSubscriptions();
    _initAudioSessionLink();
    _broadcastPlaybackState();
  }

  void _initAudioSessionLink() {
    if (playerService is JustAudioPlayerService) {
      final jas = playerService as JustAudioPlayerService;
      jas.setInterruptionCallbacks(
        onPause: () async => pause(),
        onResume: () async => play(),
        onBecomingNoisy: () async => pause(),
        isPlaybackActive: () => isActivelyPlayingOrLoading,
      );
    }
  }

  /// Whether audio is actively playing, loading, or buffering.
  bool get isActivelyPlayingOrLoading {
    if (_playbackActions != null) {
      return _playbackActions!.isActivelyPlayingOrLoading;
    }
    return playerService.isPlaying ||
        _engineProcessingState == EngineProcessingState.buffering ||
        _engineProcessingState == EngineProcessingState.loading;
  }

  /// Authoritative underlying audio engine service.
  final AudioPlayerService playerService;

  /// Optional attached playback coordinator (e.g. [PlaybackController]).
  AudioHandlerPlaybackActions? _playbackActions;

  /// Dynamic streaming URL resolver used for autonomous background playback.
  Future<String> Function(String trackId)? streamResolver;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Track? _currentTrack;
  List<Track> _queueTracks = const [];
  List<int> _shuffledIndices = const [];
  int _currentIndex = 0;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffle = false;
  double _speed = 1.0;
  Duration _bufferedPosition = Duration.zero;
  EngineProcessingState _engineProcessingState = EngineProcessingState.idle;

  Duration _lastBroadcastPosition = Duration.zero;
  DateTime _lastBroadcastTime = DateTime.now();
  bool _isDisposed = false;

  /// Whether this audio handler has been disposed and its subscriptions closed.
  bool get isDisposed => _isDisposed;

  /// Public read-only accessors for UI rehydration.
  Track? get currentTrack => _currentTrack;
  List<Track> get queueTracks => _queueTracks;
  List<int> get shuffledIndices => _shuffledIndices;
  int get currentIndex => _currentIndex;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffle => _isShuffle;

  /// Sets or updates the streaming URL resolver for autonomous queue advances.
  void setStreamResolver(Future<String> Function(String trackId) resolver) {
    streamResolver = resolver;
  }

  void _initEngineSubscriptions() {
    _subscriptions.add(
      playerService.playingStream.listen(
        (_) => _broadcastPlaybackState(),
        onError: (Object e) {
          AppLogger.warning(
            'Error in playingStream',
            tag: 'A11yAudio',
            error: e,
          );
        },
      ),
    );

    _subscriptions.add(
      playerService.processingStateStream.listen(
        (state) {
          _engineProcessingState = state;
          _broadcastPlaybackState();
        },
        onError: (Object e) {
          AppLogger.warning(
            'Error in processingStateStream',
            tag: 'A11yAudio',
            error: e,
          );
        },
      ),
    );

    _subscriptions.add(
      playerService.bufferedPositionStream.listen(
        (buf) => _bufferedPosition = buf,
        onError: (Object e) {
          AppLogger.warning(
            'Error in bufferedPositionStream',
            tag: 'A11yAudio',
            error: e,
          );
        },
      ),
    );

    _subscriptions.add(
      playerService.durationStream.listen(
        (dur) {
          if (dur != null && dur > Duration.zero && _currentTrack != null) {
            syncTrack(_currentTrack, overrideDuration: dur);
          }
        },
        onError: (Object e) {
          AppLogger.warning(
            'Error in durationStream',
            tag: 'A11yAudio',
            error: e,
          );
        },
      ),
    );

    // Throttled position listener to anchor system position without IPC flooding
    _subscriptions.add(
      playerService.positionStream.listen(
        (pos) {
          final elapsed = DateTime.now().difference(_lastBroadcastTime);
          final delta = (pos - _lastBroadcastPosition).abs();

          // Broadcast if position jumped significantly (seek) or at least 5s elapsed
          if (delta > const Duration(seconds: 2) ||
              elapsed > const Duration(seconds: 5)) {
            _broadcastPlaybackState(forcePosition: pos);
          }
        },
        onError: (Object e) {
          AppLogger.warning(
            'Error in positionStream',
            tag: 'A11yAudio',
            error: e,
          );
        },
      ),
    );

    // Autonomous track completion handling when UI controller is detached
    _subscriptions.add(
      playerService.completedStream.listen(
        (_) {
          if (_playbackActions == null) {
            skipToNext();
          }
        },
        onError: (Object e) {
          AppLogger.warning(
            'Error in completedStream',
            tag: 'A11yAudio',
            error: e,
          );
        },
      ),
    );
  }

  /// Attaches application-level playback actions for bidirectional coordination.
  void attachPlaybackActions(AudioHandlerPlaybackActions actions) {
    _playbackActions = actions;
    AppLogger.debug(
      'PlaybackActions attached to AudioHandler',
      tag: 'A11yAudio',
    );
  }

  /// Detaches application-level playback actions on dispose.
  void detachPlaybackActions() {
    _playbackActions = null;
    AppLogger.debug(
      'PlaybackActions detached from AudioHandler',
      tag: 'A11yAudio',
    );
  }

  /// Synchronizes the currently active [Track] with system media metadata.
  void syncTrack(Track? track, {Duration? overrideDuration}) {
    if (_isDisposed) return;
    _currentTrack = track;
    if (track == null) {
      mediaItem.add(null);
    } else {
      final title = track.title.trim().isNotEmpty
          ? track.title.trim()
          : 'Unknown Title';
      final artist =
          (track.user?.name != null && track.user!.name.trim().isNotEmpty)
          ? track.user!.name.trim()
          : 'Unknown Artist';
      final artUri = _parseArtUri(
        track.artwork?.primaryUrl ?? track.user?.profilePicture?.primaryUrl,
      );
      final dur =
          overrideDuration ??
          (track.duration > 0 ? Duration(seconds: track.duration) : null);

      mediaItem.add(
        MediaItem(
          id: track.id,
          album: 'AudiFi',
          title: title,
          artist: artist,
          duration: dur != null && dur > Duration.zero ? dur : null,
          artUri: artUri,
          genre: track.genre,
          displayTitle: title,
          displaySubtitle: artist,
          displayDescription: track.genre,
          extras: {
            'trackId': track.id,
            'isStreamable': track.isStreamable,
            if (track.permalink != null) 'permalink': track.permalink,
          },
        ),
      );
    }
    _broadcastPlaybackState();
  }

  /// Synchronizes active queue tracks, current index, and shuffle state with the media session.
  void syncQueue(
    List<Track> tracks, {
    required int currentIndex,
    required bool isShuffle,
    List<int>? shuffledIndices,
  }) {
    if (_isDisposed) return;
    _queueTracks = List.unmodifiable(tracks);
    _currentIndex = currentIndex;
    _isShuffle = isShuffle;
    if (shuffledIndices != null && shuffledIndices.isNotEmpty) {
      _shuffledIndices = List.unmodifiable(shuffledIndices);
    } else if (isShuffle && tracks.isNotEmpty) {
      _shuffledIndices = _generateShuffledIndices(
        tracks.length,
        currentIndex,
        true,
      );
    } else {
      _shuffledIndices = const [];
    }

    final items = tracks.map((t) {
      final title = t.title.trim().isNotEmpty
          ? t.title.trim()
          : 'Unknown Title';
      final artist = (t.user?.name != null && t.user!.name.trim().isNotEmpty)
          ? t.user!.name.trim()
          : 'Unknown Artist';
      final dur = t.duration > 0 ? Duration(seconds: t.duration) : null;
      final artUri = _parseArtUri(
        t.artwork?.primaryUrl ?? t.user?.profilePicture?.primaryUrl,
      );

      return MediaItem(
        id: t.id,
        album: 'AudiFi',
        title: title,
        artist: artist,
        duration: dur,
        artUri: artUri,
        genre: t.genre,
        displayTitle: title,
        displaySubtitle: artist,
        displayDescription: t.genre,
        extras: {'trackId': t.id, 'isStreamable': t.isStreamable},
      );
    }).toList();

    queue.add(items);
    _broadcastPlaybackState();
  }

  /// Synchronizes repeat mode state.
  void syncRepeatMode(RepeatMode repeatMode) {
    if (_isDisposed) return;
    _repeatMode = repeatMode;
    _broadcastPlaybackState();
  }

  /// Synchronizes shuffle mode state.
  void syncShuffle(bool isShuffle, {List<int>? shuffledIndices}) {
    if (_isDisposed) return;
    _isShuffle = isShuffle;
    if (shuffledIndices != null && shuffledIndices.isNotEmpty) {
      _shuffledIndices = List.unmodifiable(shuffledIndices);
    } else if (isShuffle && _queueTracks.isNotEmpty) {
      _shuffledIndices = _generateShuffledIndices(
        _queueTracks.length,
        _currentIndex,
        true,
      );
    } else {
      _shuffledIndices = const [];
    }
    _broadcastPlaybackState();
  }

  // ---------------------------------------------------------------------------
  // BaseAudioHandler / System Action Overrides
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() async {
    if (_isDisposed) return;
    if (_playbackActions != null) {
      await _playbackActions!.play();
      return;
    }

    if (playerService.isPlaying) return;

    if (_engineProcessingState == EngineProcessingState.completed) {
      await seek(Duration.zero);
      await playerService.play();
      return;
    }

    if (playerService.currentPosition > Duration.zero) {
      await playerService.play();
      return;
    }

    if (_currentTrack != null && streamResolver != null) {
      try {
        final url = await streamResolver!(_currentTrack!.id);
        await playerService.setAudioUrl(url);
        await playerService.play();
      } catch (e, st) {
        AppLogger.error(
          'Autonomous play failed',
          tag: 'A11yAudio',
          error: e,
          stackTrace: st,
        );
      }
    } else {
      try {
        await playerService.play();
      } catch (e, st) {
        AppLogger.warning(
          'Autonomous play without resolver failed: $e',
          tag: 'A11yAudio',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) return;
    if (_playbackActions != null) {
      await _playbackActions!.pause();
    } else {
      await playerService.pause();
    }
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) return;
    if (_playbackActions != null) {
      await _playbackActions!.stop();
    } else {
      await playerService.stop();
    }
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isDisposed) return;
    final clamped = position < Duration.zero ? Duration.zero : position;
    if (_playbackActions != null) {
      await _playbackActions!.seek(clamped);
    } else {
      try {
        await playerService.seek(clamped);
      } catch (e) {
        AppLogger.warning('AudioHandler seek failed: $e', tag: 'A11yAudio');
      }
    }
    _broadcastPlaybackState(forcePosition: clamped);
  }

  @override
  Future<void> skipToNext() async {
    if (_isDisposed) return;
    if (_playbackActions != null) {
      await _playbackActions!.skipToNext();
      return;
    }

    if (_queueTracks.isEmpty) return;

    if (_repeatMode == RepeatMode.one && _currentTrack != null) {
      await seek(Duration.zero);
      await playerService.play();
      return;
    }

    final effective =
        _isShuffle && _shuffledIndices.length == _queueTracks.length
        ? _shuffledIndices
        : List<int>.generate(_queueTracks.length, (i) => i);

    final currentPos = effective.indexOf(_currentIndex);
    int? nextIndex;
    if (currentPos >= 0 && currentPos < effective.length - 1) {
      nextIndex = effective[currentPos + 1];
    } else if (_repeatMode == RepeatMode.all && effective.isNotEmpty) {
      nextIndex = effective.first;
    } else {
      await stop();
      return;
    }

    _currentIndex = nextIndex;
    final nextTrack = _queueTracks[nextIndex];
    syncTrack(nextTrack);

    if (streamResolver != null) {
      try {
        final url = await streamResolver!(nextTrack.id);
        await playerService.setAudioUrl(url);
        await playerService.play();
      } catch (e, st) {
        AppLogger.error(
          'Autonomous skipToNext failed',
          tag: 'A11yAudio',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_isDisposed) return;
    if (_playbackActions != null) {
      await _playbackActions!.skipToPrevious();
      return;
    }

    // 3-second restart rule
    if (playerService.currentPosition.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_queueTracks.isEmpty) {
      await seek(Duration.zero);
      return;
    }

    final effective =
        _isShuffle && _shuffledIndices.length == _queueTracks.length
        ? _shuffledIndices
        : List<int>.generate(_queueTracks.length, (i) => i);

    final currentPos = effective.indexOf(_currentIndex);
    if (currentPos > 0) {
      final prevIndex = effective[currentPos - 1];
      _currentIndex = prevIndex;
      final prevTrack = _queueTracks[prevIndex];
      syncTrack(prevTrack);

      if (streamResolver != null) {
        try {
          final url = await streamResolver!(prevTrack.id);
          await playerService.setAudioUrl(url);
          await playerService.play();
        } catch (e, st) {
          AppLogger.error(
            'Autonomous skipToPrevious failed',
            tag: 'A11yAudio',
            error: e,
            stackTrace: st,
          );
        }
      }
    } else {
      await seek(Duration.zero);
      return;
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (_isDisposed) return;
    if (_playbackActions != null) {
      await _playbackActions!.skipToQueueItem(index);
      return;
    }

    if (index < 0 || index >= _queueTracks.length) return;

    _currentIndex = index;
    final targetTrack = _queueTracks[index];
    syncTrack(targetTrack);

    if (streamResolver != null) {
      try {
        final url = await streamResolver!(targetTrack.id);
        await playerService.setAudioUrl(url);
        await playerService.play();
      } catch (e, st) {
        AppLogger.error(
          'Autonomous skipToQueueItem failed',
          tag: 'A11yAudio',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (_isDisposed) return;
    final mode = _mapAudioServiceRepeatMode(repeatMode);
    _repeatMode = mode;
    if (_playbackActions != null) {
      await _playbackActions!.setRepeatMode(mode);
    }
    _broadcastPlaybackState();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (_isDisposed) return;
    final enabled =
        shuffleMode == AudioServiceShuffleMode.all ||
        shuffleMode == AudioServiceShuffleMode.group;
    _isShuffle = enabled;
    if (enabled && _queueTracks.isNotEmpty) {
      _shuffledIndices = _generateShuffledIndices(
        _queueTracks.length,
        _currentIndex,
        true,
      );
    } else {
      _shuffledIndices = const [];
    }
    if (_playbackActions != null) {
      await _playbackActions!.setShuffleMode(enabled);
    }
    _broadcastPlaybackState();
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_isDisposed) return;
    _speed = speed.clamp(0.25, 3.0);
    await playerService.setSpeed(_speed);
    _broadcastPlaybackState();
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    if (_isDisposed) return;
    switch (button) {
      case MediaButton.media:
        if (_playbackActions != null) {
          await _playbackActions!.togglePlayPause();
        } else if (playerService.isPlaying) {
          await pause();
        } else {
          await play();
        }
        break;
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
    }
  }

  /// Releases resources held by the handler and cleans up stream subscriptions.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _playbackActions = null;
    streamResolver = null;
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  void _broadcastPlaybackState({Duration? forcePosition}) {
    if (_isDisposed) return;
    final isPlaying = playerService.isPlaying;
    final position = forcePosition ?? playerService.currentPosition;
    final buffered = _bufferedPosition;
    final procState = _mapProcessingState(_engineProcessingState);

    _lastBroadcastPosition = position;
    _lastBroadcastTime = DateTime.now();

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.stop,
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.skipToQueueItem,
          MediaAction.setRepeatMode,
          MediaAction.setShuffleMode,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: procState,
        playing: isPlaying,
        updatePosition: position,
        bufferedPosition: buffered,
        speed: _speed,
        queueIndex: _queueTracks.isNotEmpty ? _currentIndex : null,
        updateTime: _lastBroadcastTime,
        repeatMode: _mapRepeatModeToAudioService(_repeatMode),
        shuffleMode: _isShuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }

  static Uri? _parseArtUri(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final parsed = Uri.tryParse(url.trim());
    if (parsed != null &&
        parsed.hasScheme &&
        (parsed.scheme == 'http' ||
            parsed.scheme == 'https' ||
            parsed.scheme == 'file')) {
      return parsed;
    }
    return null;
  }

  static AudioProcessingState _mapProcessingState(EngineProcessingState state) {
    switch (state) {
      case EngineProcessingState.idle:
        return AudioProcessingState.idle;
      case EngineProcessingState.loading:
        return AudioProcessingState.loading;
      case EngineProcessingState.buffering:
        return AudioProcessingState.buffering;
      case EngineProcessingState.ready:
        return AudioProcessingState.ready;
      case EngineProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  static RepeatMode _mapAudioServiceRepeatMode(AudioServiceRepeatMode mode) {
    switch (mode) {
      case AudioServiceRepeatMode.none:
      case AudioServiceRepeatMode.group:
        return RepeatMode.off;
      case AudioServiceRepeatMode.one:
        return RepeatMode.one;
      case AudioServiceRepeatMode.all:
        return RepeatMode.all;
    }
  }

  static AudioServiceRepeatMode _mapRepeatModeToAudioService(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return AudioServiceRepeatMode.none;
      case RepeatMode.one:
        return AudioServiceRepeatMode.one;
      case RepeatMode.all:
        return AudioServiceRepeatMode.all;
    }
  }

  static List<int> _generateShuffledIndices(
    int length,
    int currentIndex,
    bool isShuffle,
  ) {
    if (length <= 0) return const [];
    if (!isShuffle) {
      return List<int>.generate(length, (i) => i);
    }

    final rand = Random();
    final remaining = <int>[];
    for (var i = 0; i < length; i++) {
      if (i != currentIndex) remaining.add(i);
    }
    remaining.shuffle(rand);

    if (currentIndex >= 0 && currentIndex < length) {
      return [currentIndex, ...remaining];
    }
    return remaining;
  }
}
