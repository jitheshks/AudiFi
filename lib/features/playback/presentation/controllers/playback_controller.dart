import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/permissions/permission_providers.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../../downloads/data/datasources/download_local_data_source.dart';
import '../../../library/presentation/controllers/listening_history_controller.dart';
import '../../../local_files/data/datasources/local_files_local_data_source.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../data/datasources/next_track_url_cache.dart';
import '../../data/repositories/playback_repository_impl.dart';
import '../../data/services/audifi_audio_handler.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/audio_prebuffer_service.dart';
import '../../data/services/playback_transition_tracer.dart';
import '../../data/services/prebuffered_audio_source.dart';
import '../../domain/entities/playback_queue.dart';
import '../../domain/entities/playback_state.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../domain/repositories/playback_repository.dart';
import 'audio_player_providers.dart';
import 'queue_controller.dart';

/// Riverpod controller orchestrating audio playback lifecycle, stream resolution,
/// engine events, queue transitions, and system media control delegations.
class PlaybackController extends Notifier<PlaybackState>
    implements AudioHandlerPlaybackActions {
  AudioPlayerService get _player => ref.read(audioPlayerServiceProvider);
  PlaybackRepository get _repository => ref.read(playbackRepositoryProvider);

  @override
  bool get isActivelyPlayingOrLoading =>
      state.isPlaying ||
      state.status == PlaybackStatus.loading ||
      state.status == PlaybackStatus.buffering;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  int _operationToken = 0;
  PlaybackTransitionTracer? _activeTracer;
  CancelToken? _playbackCancelToken;
  CancelToken? _predictionCancelToken;
  bool _hasTriggeredPredictionForCurrentTrack = false;
  bool _isOfflinePrebufferExhausted = false;

  /// Visible for testing and baseline transition inspection.
  @visibleForTesting
  PlaybackTransitionTracer? get activeTracer => _activeTracer;

  /// Stores the most recently completed transition tracer for diagnostic verification.
  @visibleForTesting
  static PlaybackTransitionTracer? lastCompletedTracer;

  @override
  PlaybackState build() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _initEngineListeners();

    // Attach system audio handler actions and stream resolver
    final handler = ref.read(audioHandlerProvider);
    Track? initialTrack;
    PlaybackStatus initialStatus = PlaybackStatus.idle;
    Duration initialPosition = Duration.zero;
    Duration initialDuration = Duration.zero;
    RepeatMode initialRepeat = RepeatMode.off;
    bool initialShuffle = false;

    if (handler is AudifiAudioHandler) {
      handler.attachPlaybackActions(this);
      handler.setStreamResolver(_repository.resolveStreamUrl);

      initialTrack = handler.currentTrack;
      initialRepeat = handler.repeatMode;
      initialShuffle = handler.isShuffle;
      if (initialTrack != null) {
        initialDuration = Duration(seconds: initialTrack.duration);
        initialPosition = _player.currentPosition;
        initialStatus = _player.isPlaying
            ? PlaybackStatus.playing
            : (_player.currentPosition > Duration.zero
                  ? PlaybackStatus.paused
                  : PlaybackStatus.idle);
      }
    }

    ref.listen<PlaybackQueue>(queueControllerProvider, (prev, next) {
      if (prev == null) return;
      if (next.isEmpty && prev.isNotEmpty) {
        _invalidatePrediction('queue_cleared');
        unawaited(_player.stop());
        state = PlaybackState.initial;
        if (handler is AudifiAudioHandler) {
          handler.syncTrack(null);
        }
        return;
      }
      final cachedTrackId = _repository.currentPredictedTrackId;
      if (cachedTrackId == null) return;

      // If the queue advanced directly to the predicted track, keep it for playTrack to consume
      if (next.currentTrack?.id == cachedTrackId) {
        return;
      }

      final expectedNext = next.getNextTrack(
        loop: state.repeatMode == RepeatMode.all,
      );
      if (expectedNext?.id != cachedTrackId) {
        _invalidatePrediction('queue_modified_or_index_changed');
      }
    });

    ref.listen<AudifiNetworkState>(networkStateProvider, (prev, next) {
      _onNetworkStateChanged(prev, next);
    });

    ref.listen<SettingsState>(settingsControllerProvider, (prev, next) {
      _onSettingsChanged(prev, next);
    });

    ref.onDispose(() {
      _playbackCancelToken?.cancel('controller_disposed');
      _predictionCancelToken?.cancel('controller_disposed');
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
      if (handler is AudifiAudioHandler) {
        handler.detachPlaybackActions();
      }
    });

    if (initialTrack != null) {
      return PlaybackState(
        currentTrack: initialTrack,
        status: initialStatus,
        position: initialPosition,
        duration: initialDuration,
        repeatMode: initialRepeat,
        isShuffleEnabled: initialShuffle,
      );
    }

    return PlaybackState.initial;
  }

  void _initEngineListeners() {
    final player = _player;

    _subscriptions.add(
      player.positionStream.listen(
        (pos) {
          if (state.hasTrack) {
            state = state.copyWith(position: pos);
            _checkPreResolutionTrigger(pos, state.duration);
          }
          if (pos > Duration.zero &&
              _activeTracer != null &&
              _activeTracer!.hasMark('t8_play_command_issued') &&
              !_activeTracer!.hasMark('t10_first_audio_progression')) {
            _activeTracer!.mark('t10_first_audio_progression');
            lastCompletedTracer = _activeTracer;
            _activeTracer!.complete();
            _activeTracer = null;
          }
        },
        onError: (Object e) {
          AppLogger.warning(
            'Error in positionStream',
            tag: 'Playback',
            error: e,
          );
        },
      ),
    );

    _subscriptions.add(
      player.bufferedPositionStream.listen(
        (buf) {
          if (state.hasTrack) {
            state = state.copyWith(bufferedPosition: buf);
          }
        },
        onError: (Object e) {
          AppLogger.warning(
            'Error in bufferedPositionStream',
            tag: 'Playback',
            error: e,
          );
        },
      ),
    );

    _subscriptions.add(
      player.durationStream.listen(
        (dur) {
          if (dur != null && dur > Duration.zero) {
            state = state.copyWith(duration: dur);
          }
        },
        onError: (Object e) {
          AppLogger.warning(
            'Error in durationStream',
            tag: 'Playback',
            error: e,
          );
        },
      ),
    );

    _subscriptions.add(
      player.playingStream.listen(
        (isPlaying) {
          if (isPlaying && state.status != PlaybackStatus.playing) {
            state = state.copyWith(status: PlaybackStatus.playing);
          } else if (!isPlaying && state.status == PlaybackStatus.playing) {
            state = state.copyWith(status: PlaybackStatus.paused);
          }
          if (isPlaying &&
              _activeTracer != null &&
              !_activeTracer!.hasMark('t9_player_playing')) {
            _activeTracer!.mark('t9_player_playing');
          }
        },
        onError: (Object e) {
          AppLogger.warning(
            'Error in playingStream',
            tag: 'Playback',
            error: e,
          );
        },
      ),
    );

    _subscriptions.add(
      player.processingStateStream.listen(
        (proc) {
          switch (proc) {
            case EngineProcessingState.idle:
              if (state.status != PlaybackStatus.idle && !state.hasTrack) {
                state = state.copyWith(status: PlaybackStatus.idle);
              }
              break;
            case EngineProcessingState.loading:
            case EngineProcessingState.buffering:
              if (_activeTracer != null &&
                  !_activeTracer!.hasMark('t6_player_buffering')) {
                _activeTracer!.mark('t6_player_buffering');
              }
              state = state.copyWith(
                status: proc == EngineProcessingState.loading
                    ? PlaybackStatus.loading
                    : PlaybackStatus.buffering,
              );
              break;
            case EngineProcessingState.ready:
              state = state.copyWith(
                status: player.isPlaying
                    ? PlaybackStatus.playing
                    : PlaybackStatus.paused,
              );
              break;
            case EngineProcessingState.completed:
              // Handled via completedStream
              break;
          }
        },
        onError: (Object e) {
          AppLogger.warning(
            'Error in processingStateStream',
            tag: 'Playback',
            error: e,
          );
        },
      ),
    );

    _subscriptions.add(
      player.completedStream.listen(
        (_) => _onTrackCompleted(),
        onError: (Object e) {
          AppLogger.warning(
            'Error in completedStream',
            tag: 'Playback',
            error: e,
          );
        },
      ),
    );
  }

  /// Starts playback of [track]. Loads optional [contextTracks] into the queue.
  Future<void> playTrack(
    Track track, {
    List<Track>? contextTracks,
    PlaybackTransitionTracer? tracer,
  }) async {
    _checkNotificationPermissionContextually();

    // Invalidate and cancel previous playback requests and predictions
    _playbackCancelToken?.cancel('superseded_by_newer_operation');
    final cancelToken = CancelToken();
    _playbackCancelToken = cancelToken;

    _predictionCancelToken?.cancel('track_changed');
    _predictionCancelToken = null;
    _hasTriggeredPredictionForCurrentTrack = false;
    _isOfflinePrebufferExhausted = false;

    _activeTracer?.abort('superseded_by_newer_operation');
    final currentToken = ++_operationToken;
    final activeTracer =
        tracer ??
        PlaybackTransitionTracer.start(
          transitionId: currentToken,
          trigger: 'direct_play',
          targetTrackId: track.id,
        );
    _activeTracer = activeTracer;

    // Mobile data streaming policy enforcement
    final networkState = ref.read(networkStateProvider);
    final settings = ref.read(settingsControllerProvider);
    final isLocalOrDownloaded = _isLocalOrDownloadedTrack(track.id);

    if (networkState.isMobile &&
        !settings.streamOnMobileData &&
        !isLocalOrDownloaded) {
      activeTracer.abort('mobile_data_restricted');
      AppLogger.warning(
        'Streaming prevented for "${track.title}": Mobile data streaming is disabled in Settings.',
        tag: 'Playback',
      );

      // Preserve queue context
      if (contextTracks != null && contextTracks.isNotEmpty) {
        final startIndex = contextTracks
            .indexWhere((t) => t.id == track.id)
            .clamp(0, contextTracks.length - 1);
        ref
            .read(queueControllerProvider.notifier)
            .setQueue(contextTracks, startIndex: startIndex);
      } else {
        ref.read(queueControllerProvider.notifier).playTrack(track);
      }

      state = state.copyWith(
        currentTrack: track,
        status: PlaybackStatus.error,
        position: Duration.zero,
        duration: Duration(seconds: track.duration),
        bufferedPosition: Duration.zero,
        error: const NetworkFailure(
          message: 'Streaming over mobile data is disabled in Settings.',
          code: 'mobile_data_restricted',
        ),
      );

      final handler = ref.read(audioHandlerProvider);
      if (handler is AudifiAudioHandler) {
        handler.syncTrack(track);
        final q = ref.read(queueControllerProvider);
        handler.syncQueue(
          q.items,
          currentIndex: q.currentIndex,
          isShuffle: q.isShuffleEnabled,
          shuffledIndices: q.shuffledIndices,
        );
      }
      return;
    }

    // Update queue controller and record listening history
    ref
        .read(queueControllerProvider.notifier)
        .playTrack(track, contextTracks: contextTracks);
    ref.read(listeningHistoryProvider.notifier).addTrack(track);

    // Optimistic state update
    state = state.copyWith(
      currentTrack: track,
      status: PlaybackStatus.loading,
      position: Duration.zero,
      duration: Duration(seconds: track.duration),
      bufferedPosition: Duration.zero,
      clearError: true,
    );
    activeTracer.mark('t2_ui_track_updated');

    // Synchronize active track with background audio handler
    final handler = ref.read(audioHandlerProvider);
    if (handler is AudifiAudioHandler) {
      handler.syncTrack(track);
      final q = ref.read(queueControllerProvider);
      handler.syncQueue(
        q.items,
        currentIndex: q.currentIndex,
        isShuffle: q.isShuffleEnabled,
        shuffledIndices: q.shuffledIndices,
      );
    }

    try {
      AppLogger.info(
        'Resolving and playing track "${track.title}" (${track.id})',
        tag: 'Playback',
      );

      final hadPrediction = _repository.hasPrediction(track.id);
      if (hadPrediction) {
        activeTracer.mark('cache_hit');
      } else {
        activeTracer.mark('cache_miss');
      }

      activeTracer.mark('t3_stream_resolution_started');
      final streamUrl = await _repository.resolveStreamUrl(
        track.id,
        cancelToken: cancelToken,
      );
      activeTracer.mark('t4_stream_resolution_completed');

      // Race condition check: abort if a newer playTrack operation was initiated or cancelled
      if (currentToken != _operationToken || cancelToken.isCancelled) {
        activeTracer.abort('superseded_after_stream_resolution');
        return;
      }

      activeTracer.mark('t5_source_load_started');
      try {
        final prebufferService = ref.read(audioPrebufferServiceProvider);
        final prebuffer = prebufferService.getPrebuffer(track.id);

        if (prebuffer != null &&
            prebuffer.isValid &&
            !streamUrl.startsWith('/') &&
            !streamUrl.startsWith('file:')) {
          activeTracer.mark('prebuffer_hit');
          AppLogger.info(
            'Playing track "${track.title}" from prebuffered local prefix (${prebuffer.bufferedBytes} bytes)',
            tag: 'Playback',
          );
          final prebufferedSource = PrebufferedAudioSource(
            trackId: track.id,
            prebufferedFile: prebuffer.file,
            prebufferedBytes: prebuffer.bufferedBytes,
            totalContentLength: prebuffer.totalBytes,
            remoteUri: Uri.parse(streamUrl),
            urlResolver: () => _repository.resolveStreamUrl(track.id),
            onOfflineExhausted: (tId) {
              if (state.currentTrack?.id == tId) {
                _isOfflinePrebufferExhausted = true;
              }
            },
          );
          await _player.setAudioSource(prebufferedSource);
        } else {
          activeTracer.mark('prebuffer_miss');
          await _player.setAudioUrl(streamUrl);
        }
      } catch (loadError) {
        // If loading failed (due to expired URL, transient node failure, or corrupted local file),
        // gracefully attempt fresh remote stream resolution fallback once.
        if (currentToken == _operationToken && !cancelToken.isCancelled) {
          AppLogger.warning(
            'Source failed to load for track ${track.id} ($streamUrl); attempting fresh resolution fallback: $loadError',
            tag: 'Playback',
          );
          _repository.invalidatePrediction(reason: 'source_load_failed');

          // If corrupted local file, remove it from downloads to prevent repeated failures
          final isLocalFile =
              streamUrl.startsWith('/') || streamUrl.startsWith('file:');
          if (isLocalFile) {
            try {
              final downloads = ref.read(downloadLocalDataSourceProvider);
              await downloads.removeDownloadedTrack(track.id);
            } catch (_) {}
          }

          activeTracer.mark('fresh_resolution_fallback');
          activeTracer.mark('normal_resolution_fallback');
          final freshUrl = await _repository.resolveStreamUrl(
            track.id,
            cancelToken: cancelToken,
          );
          await _player.setAudioUrl(freshUrl);
        } else {
          rethrow;
        }
      }

      activeTracer.mark('t7_player_ready');
      if (currentToken != _operationToken || cancelToken.isCancelled) {
        activeTracer.abort('superseded_after_source_load');
        return;
      }

      activeTracer.mark('t8_play_command_issued');
      if (_player.isPlaying && !activeTracer.hasMark('t9_player_playing')) {
        activeTracer.mark('t9_player_playing');
      }
      unawaited(_player.play());
      await Future<void>.delayed(Duration.zero);
    } catch (e, st) {
      if (currentToken != _operationToken || cancelToken.isCancelled) {
        activeTracer.abort('superseded_or_cancelled');
        return;
      }
      if (e is CancellationException) {
        activeTracer.abort('cancelled');
        return;
      }
      activeTracer.abort('playback_error: $e');

      final failure = ErrorMapper.mapToFailure(e);
      AppLogger.error(
        'Playback failed for track "${track.title}"',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );

      state = state.copyWith(status: PlaybackStatus.error, error: failure);
    }
  }

  /// Checks whether playback progress satisfies the pre-resolution threshold (75% or 15s remaining).
  void _checkPreResolutionTrigger(Duration pos, Duration dur) {
    if (!state.isPlaying || dur <= Duration.zero) return;
    if (_hasTriggeredPredictionForCurrentTrack) return;

    // Trigger condition: 75% elapsed OR <= 15 seconds remaining
    final isSeventyFivePercent =
        pos.inMilliseconds >= dur.inMilliseconds * 0.75;
    final isFifteenSecondsLeft = (dur - pos) <= const Duration(seconds: 15);

    if (isSeventyFivePercent || isFifteenSecondsLeft) {
      _hasTriggeredPredictionForCurrentTrack = true;
      final reason = isSeventyFivePercent
          ? '75_percent_elapsed'
          : '15s_remaining';
      _startPredictiveResolution(reason);
    }
  }

  /// Dispatches asynchronous pre-resolution for the authoritative next track.
  void _startPredictiveResolution(String triggerReason) {
    final nextTrack = getPredictedNextTrack();
    if (nextTrack == null || nextTrack.id == state.currentTrack?.id) {
      return;
    }

    final networkState = ref.read(networkStateProvider);
    final settings = ref.read(settingsControllerProvider);
    if (networkState.isMobile &&
        !settings.streamOnMobileData &&
        !_isLocalOrDownloadedTrack(nextTrack.id)) {
      AppLogger.debug(
        'Predictive prefetch skipped: Mobile data streaming is disabled in Settings.',
        tag: 'Playback',
      );
      return;
    }

    AppLogger.debug(
      'Next-track prediction triggered for track: ${nextTrack.id} (trigger: $triggerReason)',
      tag: 'Playback',
    );

    _predictionCancelToken?.cancel('superseded_by_newer_prediction');
    final cancelToken = CancelToken();
    _predictionCancelToken = cancelToken;

    unawaited(
      _repository
          .prefetchStreamUrl(nextTrack.id, cancelToken: cancelToken)
          .then((_) async {
            if (cancelToken.isCancelled) return;
            final cache = ref.read(nextTrackUrlCacheProvider);
            final streamUrl = cache.peek(nextTrack.id);
            if (streamUrl != null && streamUrl.isNotEmpty) {
              final prebufferService = ref.read(audioPrebufferServiceProvider);
              await prebufferService.prebufferTrack(
                nextTrack.id,
                streamUrl,
                cancelToken: cancelToken,
              );
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            if (error is! CancellationException) {
              AppLogger.debug(
                'Predictive next-track resolution failed gracefully for ${nextTrack.id}: $error',
                tag: 'Playback',
              );
            }
          }),
    );
  }

  /// Authoritative predictor of the next track, matching skipToNext() logic.
  Track? getPredictedNextTrack() {
    if (state.repeatMode == RepeatMode.one) {
      // In Repeat One, next action replays current track without new stream resolution
      return null;
    }
    final queue = ref.read(queueControllerProvider);
    return queue.getNextTrack(loop: state.repeatMode == RepeatMode.all);
  }

  /// Explicitly cancels in-flight prediction and invalidates the cached URL.
  void _invalidatePrediction(String reason) {
    _predictionCancelToken?.cancel(reason);
    _predictionCancelToken = null;
    _repository.invalidatePrediction(reason: reason);
    try {
      ref.read(audioPrebufferServiceProvider).cancelAll(reason: reason);
    } catch (_) {}
    _hasTriggeredPredictionForCurrentTrack = false;
  }

  /// Starts or resumes audio playback.
  @override
  Future<void> play() async {
    if (state.hasTrack) {
      final networkState = ref.read(networkStateProvider);
      final settings = ref.read(settingsControllerProvider);
      if (networkState.isMobile &&
          !settings.streamOnMobileData &&
          !_isLocalOrDownloadedTrack(state.currentTrack!.id)) {
        state = state.copyWith(
          status: PlaybackStatus.error,
          error: const NetworkFailure(
            message: 'Streaming over mobile data is disabled in Settings.',
            code: 'mobile_data_restricted',
          ),
        );
        return;
      }

      if (state.status == PlaybackStatus.idle ||
          state.status == PlaybackStatus.error ||
          _player.currentDuration == null) {
        await playTrack(state.currentTrack!);
      } else {
        if (state.status == PlaybackStatus.completed) {
          await seek(Duration.zero);
        }
        if (state.error != null) {
          state = state.copyWith(clearError: true);
        }
        await _player.play();
      }
    } else {
      final currentQueueTrack = ref.read(queueControllerProvider).currentTrack;
      if (currentQueueTrack != null) {
        await playTrack(currentQueueTrack);
      }
    }
  }

  /// Pauses active audio playback without resetting position.
  @override
  Future<void> pause() async {
    if (state.status == PlaybackStatus.loading) {
      _playbackCancelToken?.cancel('paused_while_loading');
      state = state.copyWith(status: PlaybackStatus.paused);
    }
    await _player.pause();
  }

  /// Toggles active playback between play and pause.
  @override
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seeks current playback position to [position].
  @override
  Future<void> seek(Duration position) async {
    final clamped = position < Duration.zero
        ? Duration.zero
        : (state.duration > Duration.zero && position > state.duration
              ? state.duration
              : position);

    state = state.copyWith(position: clamped);
    try {
      await _player.seek(clamped);
    } catch (e) {
      AppLogger.warning('Seek failed or player not ready: $e', tag: 'Playback');
    }
  }

  /// Skips to the next track according to queue and repeat modes.
  @override
  Future<void> skipToNext() async {
    if (state.repeatMode == RepeatMode.one && state.hasTrack) {
      await seek(Duration.zero);
      await _player.play();
      return;
    }

    final nextTrack = ref
        .read(queueControllerProvider.notifier)
        .advanceToNext(loop: state.repeatMode == RepeatMode.all);

    if (nextTrack != null) {
      final tracer = PlaybackTransitionTracer.start(
        transitionId: _operationToken + 1,
        trigger: 'next',
        targetTrackId: nextTrack.id,
      );
      tracer.mark('t1_queue_advanced');
      await playTrack(nextTrack, tracer: tracer);
    } else {
      await _player.stop();
      state = state.copyWith(
        status: PlaybackStatus.completed,
        position: state.duration,
      );
    }
  }

  /// Steps to the previous track, or restarts current track if elapsed > 3 seconds.
  @override
  Future<void> skipToPrevious() async {
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    final prevTrack = ref
        .read(queueControllerProvider.notifier)
        .stepToPrevious();

    if (prevTrack != null) {
      final tracer = PlaybackTransitionTracer.start(
        transitionId: _operationToken + 1,
        trigger: 'previous',
        targetTrackId: prevTrack.id,
      );
      tracer.mark('t1_queue_advanced');
      await playTrack(prevTrack, tracer: tracer);
    } else {
      await seek(Duration.zero);
    }
  }

  /// Skips directly to the track at [index] in the queue.
  @override
  Future<void> skipToQueueItem(int index) async {
    final queue = ref.read(queueControllerProvider);
    if (index >= 0 && index < queue.items.length) {
      final targetTrack = queue.items[index];
      final tracer = PlaybackTransitionTracer.start(
        transitionId: _operationToken + 1,
        trigger: 'queue_select',
        targetTrackId: targetTrack.id,
      );
      ref.read(queueControllerProvider.notifier).setCurrentIndex(index);
      tracer.mark('t1_queue_advanced');
      await playTrack(targetTrack, tracer: tracer);
    }
  }

  /// Sets repeat mode.
  @override
  Future<void> setRepeatMode(RepeatMode repeatMode) async {
    state = state.copyWith(repeatMode: repeatMode);
    final handler = ref.read(audioHandlerProvider);
    if (handler is AudifiAudioHandler) {
      handler.syncRepeatMode(repeatMode);
    }
    _invalidatePrediction('repeat_mode_changed');
    _checkPreResolutionTrigger(state.position, state.duration);
  }

  /// Sets shuffle mode.
  @override
  Future<void> setShuffleMode(bool enabled) async {
    if (state.isShuffleEnabled != enabled) {
      toggleShuffle();
    }
  }

  /// Toggles shuffle mode across the queue.
  void toggleShuffle() {
    ref.read(queueControllerProvider.notifier).toggleShuffle();
    final newShuffle = !state.isShuffleEnabled;
    state = state.copyWith(isShuffleEnabled: newShuffle);
    final handler = ref.read(audioHandlerProvider);
    if (handler is AudifiAudioHandler) {
      final q = ref.read(queueControllerProvider);
      handler.syncShuffle(newShuffle, shuffledIndices: q.shuffledIndices);
    }
    _invalidatePrediction('shuffle_changed');
    _checkPreResolutionTrigger(state.position, state.duration);
  }

  /// Cycles repeat mode: off -> all -> one -> off.
  void cycleRepeatMode() {
    final nextMode = state.repeatMode.next;
    state = state.copyWith(repeatMode: nextMode);
    final handler = ref.read(audioHandlerProvider);
    if (handler is AudifiAudioHandler) {
      handler.syncRepeatMode(nextMode);
    }
    _invalidatePrediction('repeat_mode_changed');
    _checkPreResolutionTrigger(state.position, state.duration);
  }

  /// Adjusts output volume [0.0 - 1.0].
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    await _player.setVolume(clamped);
    state = state.copyWith(volume: clamped);
  }

  /// Adjusts playback speed multiplier.
  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.25, 3.0);
    await _player.setSpeed(clamped);
    state = state.copyWith(speed: clamped);
  }

  /// Stops playback and releases active player engine state.
  @override
  Future<void> stop() async {
    _operationToken++;
    await _player.stop();
    state = state.copyWith(
      status: PlaybackStatus.idle,
      position: Duration.zero,
    );
    final handler = ref.read(audioHandlerProvider);
    if (handler is AudifiAudioHandler) {
      handler.syncTrack(null);
    }
  }

  /// Restores saved queue state on startup.
  Future<void> restoreSavedQueue() async {
    // If the controller already has an active track and is playing or loading,
    // preserve the active playback session without clobbering.
    if (state.hasTrack &&
        (state.isPlaying ||
            state.status == PlaybackStatus.loading ||
            state.status == PlaybackStatus.buffering)) {
      return;
    }
    await ref.read(queueControllerProvider.notifier).restoreQueue();
    final queue = ref.read(queueControllerProvider);
    if (queue.currentTrack != null) {
      state = state.copyWith(
        currentTrack: queue.currentTrack,
        duration: Duration(seconds: queue.currentTrack!.duration),
        status: PlaybackStatus.idle,
        isShuffleEnabled: queue.isShuffleEnabled,
      );
      final handler = ref.read(audioHandlerProvider);
      if (handler is AudifiAudioHandler) {
        handler.syncTrack(queue.currentTrack);
        handler.syncQueue(
          queue.items,
          currentIndex: queue.currentIndex,
          isShuffle: queue.isShuffleEnabled,
          shuffledIndices: queue.shuffledIndices,
        );
      }
    }
  }

  void _onTrackCompleted() {
    if (_isOfflinePrebufferExhausted) {
      _isOfflinePrebufferExhausted = false;
      AppLogger.info(
        'Prebuffered audio playback exhausted while offline. Pausing until internet returns.',
        tag: 'Playback',
      );
      state = state.copyWith(status: PlaybackStatus.paused);
      return;
    }
    if (state.repeatMode == RepeatMode.one) {
      seek(Duration.zero).then((_) => _player.play());
      return;
    }
    skipToNext();
  }

  bool _hasCheckedNotificationPermission = false;

  void _checkNotificationPermissionContextually() {
    if (_hasCheckedNotificationPermission) return;
    _hasCheckedNotificationPermission = true;

    Future<void>.microtask(() async {
      try {
        final permissionService = ref.read(permissionServiceProvider);
        final isGranted = await permissionService.isNotificationGranted();
        if (!isGranted) {
          final isPermanentlyDenied = await permissionService
              .isPermanentlyDenied(Permission.notification);
          if (!isPermanentlyDenied) {
            await permissionService.requestNotificationPermission();
          }
        }
      } catch (e) {
        AppLogger.debug(
          'Contextual notification permission check skipped: $e',
          tag: 'Playback',
        );
      }
    });
  }

  /// Checks if [trackId] corresponds to a locally stored file (imported local file or offline download)
  /// that can be played without network streaming.
  bool _isLocalOrDownloadedTrack(String trackId) {
    try {
      final downloads = ref.read(downloadLocalDataSourceProvider);
      if (downloads.isTrackDownloaded(trackId)) return true;
    } catch (_) {}
    try {
      final localFiles = ref.read(localFilesLocalDataSourceProvider);
      if (localFiles.isLocalFile(trackId)) return true;
    } catch (_) {}
    return false;
  }

  void _onNetworkStateChanged(
    AudifiNetworkState? prev,
    AudifiNetworkState next,
  ) {
    final wasMobile = prev?.isMobile ?? false;
    final isNowMobile = next.isMobile;

    // Transition from Wi-Fi/Ethernet to Mobile Data while streaming
    if (!wasMobile && isNowMobile) {
      final settings = ref.read(settingsControllerProvider);
      if (!settings.streamOnMobileData) {
        if (state.hasTrack &&
            !_isLocalOrDownloadedTrack(state.currentTrack!.id) &&
            (state.isPlaying || state.isBuffering)) {
          AppLogger.warning(
            'Playback paused: Mobile data streaming is disabled in Settings.',
            tag: 'Playback',
          );
          unawaited(_player.pause());
          state = state.copyWith(
            status: PlaybackStatus.paused,
            error: const NetworkFailure(
              message: 'Playback paused: Mobile data streaming is disabled in Settings.',
              code: 'mobile_data_restricted',
            ),
          );
        }
      }
    }

    // Transition from Mobile Data back to Wi-Fi/Ethernet
    if (wasMobile && !isNowMobile) {
      if (state.error?.code == 'mobile_data_restricted') {
        state = state.copyWith(clearError: true);
      }
    }
  }

  void _onSettingsChanged(SettingsState? prev, SettingsState next) {
    if (prev == null) return;

    // Preference toggled OFF -> ON
    if (!prev.streamOnMobileData && next.streamOnMobileData) {
      if (state.error?.code == 'mobile_data_restricted') {
        state = state.copyWith(clearError: true);
      }
    }

    // Preference toggled ON -> OFF while actively streaming on cellular
    if (prev.streamOnMobileData && !next.streamOnMobileData) {
      final networkState = ref.read(networkStateProvider);
      if (networkState.isMobile &&
          state.hasTrack &&
          !_isLocalOrDownloadedTrack(state.currentTrack!.id) &&
          (state.isPlaying || state.isBuffering)) {
        AppLogger.warning(
          'Playback paused: Mobile data streaming was disabled in Settings.',
          tag: 'Playback',
        );
        unawaited(_player.pause());
        state = state.copyWith(
          status: PlaybackStatus.paused,
          error: const NetworkFailure(
            message: 'Playback paused: Mobile data streaming is disabled in Settings.',
            code: 'mobile_data_restricted',
          ),
        );
      }
    }
  }
}

/// Riverpod provider for [PlaybackController].
final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);
