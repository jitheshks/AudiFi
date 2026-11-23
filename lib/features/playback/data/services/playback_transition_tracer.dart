import '../../../../core/logging/app_logger.dart';

/// Lightweight diagnostic timing tracer for measuring end-to-end playback
/// transition latency using a monotonic clock ([Stopwatch]).
class PlaybackTransitionTracer {
  PlaybackTransitionTracer._({
    required this.transitionId,
    required this.trigger,
    required this.targetTrackId,
  }) : _stopwatch = Stopwatch()..start();

  /// Starts a new transition trace for [transitionId].
  static PlaybackTransitionTracer start({
    required int transitionId,
    required String trigger,
    required String targetTrackId,
  }) {
    final tracer = PlaybackTransitionTracer._(
      transitionId: transitionId,
      trigger: trigger,
      targetTrackId: targetTrackId,
    );
    tracer.mark('t0_user_triggered');
    return tracer;
  }

  /// Sequential identifier correlating all events in this transition.
  final int transitionId;

  /// Trigger origin ('next', 'previous', 'queue_select', 'direct_play').
  final String trigger;

  /// Track ID being transitioned to (safe non-sensitive identifier).
  final String targetTrackId;

  final Stopwatch _stopwatch;
  final Map<String, double> _timingsMs = {};
  bool _isCompleted = false;

  /// Returns an unmodifiable snapshot of recorded event timestamps (in ms).
  Map<String, double> get timings => Map.unmodifiable(_timingsMs);

  /// True if the tracer has recorded [eventName].
  bool hasMark(String eventName) => _timingsMs.containsKey(eventName);

  /// Records an event timestamp relative to T0 using the monotonic stopwatch.
  void mark(String eventName) {
    if (_isCompleted) return;
    _timingsMs[eventName] = _stopwatch.elapsedMicroseconds / 1000.0;
  }

  /// Finalizes the trace and logs the structured timing summary.
  void complete() {
    if (_isCompleted) return;
    _isCompleted = true;
    _stopwatch.stop();

    final buffer = StringBuffer(
      '[PlaybackTiming][transition=$transitionId][trigger=$trigger][track=$targetTrackId]\n',
    );
    for (final entry in _timingsMs.entries) {
      buffer.writeln(
        '  ${entry.key.padRight(32)}: ${entry.value.toStringAsFixed(2)} ms',
      );
    }
    AppLogger.info(buffer.toString().trimRight(), tag: 'PlaybackTiming');
  }

  /// Aborts the trace (e.g. if superseded by a rapid skip or on error).
  void abort(String reason) {
    if (_isCompleted) return;
    _isCompleted = true;
    _stopwatch.stop();

    final elapsed = (_stopwatch.elapsedMicroseconds / 1000.0).toStringAsFixed(
      2,
    );
    AppLogger.info(
      '[PlaybackTiming][transition=$transitionId][trigger=$trigger][track=$targetTrackId] Aborted: $reason ($elapsed ms)',
      tag: 'PlaybackTiming',
    );
  }
}
