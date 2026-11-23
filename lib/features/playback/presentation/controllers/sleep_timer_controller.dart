import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'playback_controller.dart';

/// State representation of the playback sleep timer.
class SleepTimerState {
  const SleepTimerState({
    this.isActive = false,
    this.remaining = Duration.zero,
    this.totalDuration = Duration.zero,
  });

  /// Whether a sleep timer is currently running.
  final bool isActive;

  /// Time remaining before playback pauses.
  final Duration remaining;

  /// Original target duration selected by user.
  final Duration totalDuration;

  /// Formatted remaining countdown mm:ss or hh:mm:ss.
  String get formattedRemaining {
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:$s';
    }
    return '$m:$s';
  }

  SleepTimerState copyWith({
    bool? isActive,
    Duration? remaining,
    Duration? totalDuration,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      remaining: remaining ?? this.remaining,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}

/// Riverpod controller managing sleep timer countdown and automatic playback pause.
class SleepTimerController extends Notifier<SleepTimerState> {
  Timer? _timer;

  @override
  SleepTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const SleepTimerState();
  }

  /// Starts a countdown timer for [duration] and pauses playback upon expiration.
  void startTimer(Duration duration) {
    _timer?.cancel();
    if (duration <= Duration.zero) {
      cancelTimer();
      return;
    }

    state = SleepTimerState(
      isActive: true,
      remaining: duration,
      totalDuration: duration,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemaining = state.remaining - const Duration(seconds: 1);
      if (newRemaining <= Duration.zero) {
        timer.cancel();
        state = const SleepTimerState(isActive: false);
        ref.read(playbackControllerProvider.notifier).pause();
      } else {
        state = state.copyWith(remaining: newRemaining);
      }
    });
  }

  /// Cancels any active sleep timer.
  void cancelTimer() {
    _timer?.cancel();
    state = const SleepTimerState(isActive: false);
  }
}

/// Provider for [SleepTimerController].
final sleepTimerProvider =
    NotifierProvider<SleepTimerController, SleepTimerState>(
      SleepTimerController.new,
    );
