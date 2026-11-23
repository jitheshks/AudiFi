import '../../../tracks/domain/entities/track.dart';

/// Pure domain entity modeling the ordered playback queue and shuffle order.
class PlaybackQueue {
  const PlaybackQueue({
    this.items = const [],
    this.currentIndex = -1,
    this.shuffledIndices = const [],
    this.isShuffleEnabled = false,
  });

  /// Ordered list of tracks in the queue.
  final List<Track> items;

  /// Current index pointing to the active track in [items].
  final int currentIndex;

  /// Permutation of indices representing shuffle playback order.
  final List<int> shuffledIndices;

  /// Whether shuffle playback order is active.
  final bool isShuffleEnabled;

  /// Initial empty queue.
  static const PlaybackQueue empty = PlaybackQueue();

  /// Currently active track or null if queue is empty or index invalid.
  Track? get currentTrack {
    if (currentIndex >= 0 && currentIndex < items.length) {
      return items[currentIndex];
    }
    return null;
  }

  /// Whether the queue contains any tracks.
  bool get isEmpty => items.isEmpty;

  /// Whether the queue contains at least one track.
  bool get isNotEmpty => items.isNotEmpty;

  /// Total number of tracks in the queue.
  int get length => items.length;

  /// Current playback order of track indices based on shuffle state.
  List<int> get effectiveIndices {
    if (isShuffleEnabled && shuffledIndices.length == items.length) {
      return shuffledIndices;
    }
    return List<int>.generate(items.length, (i) => i);
  }

  /// Current position within the effective playback sequence.
  int get currentEffectivePosition {
    if (currentIndex < 0 || currentIndex >= items.length) return -1;
    return effectiveIndices.indexOf(currentIndex);
  }

  /// Whether there is a subsequent track available in the sequence.
  bool get hasNext {
    final pos = currentEffectivePosition;
    return pos >= 0 && pos < effectiveIndices.length - 1;
  }

  /// Whether there is a preceding track available in the sequence.
  bool get hasPrevious {
    final pos = currentEffectivePosition;
    return pos > 0;
  }

  /// Returns the index of the next track, or null if at the end of the queue.
  int? get nextIndex {
    final pos = currentEffectivePosition;
    if (pos >= 0 && pos < effectiveIndices.length - 1) {
      return effectiveIndices[pos + 1];
    }
    return null;
  }

  /// Returns the upcoming [Track] in playback sequence, accounting for optional [loop] mode.
  Track? getNextTrack({bool loop = false}) {
    final idx = nextIndex;
    if (idx != null && idx >= 0 && idx < items.length) {
      return items[idx];
    }
    if (loop && effectiveIndices.isNotEmpty) {
      final firstIdx = effectiveIndices.first;
      if (firstIdx >= 0 && firstIdx < items.length) {
        return items[firstIdx];
      }
    }
    return null;
  }

  /// Returns the preceding [Track] in playback sequence, accounting for optional [loop] mode.
  Track? getPreviousTrack({bool loop = false}) {
    final idx = previousIndex;
    if (idx != null && idx >= 0 && idx < items.length) {
      return items[idx];
    }
    if (loop && effectiveIndices.isNotEmpty) {
      final lastIdx = effectiveIndices.last;
      if (lastIdx >= 0 && lastIdx < items.length) {
        return items[lastIdx];
      }
    }
    return null;
  }

  /// Returns the index of the previous track, or null if at the start of the queue.
  int? get previousIndex {
    final pos = currentEffectivePosition;
    if (pos > 0) {
      return effectiveIndices[pos - 1];
    }
    return null;
  }

  /// Returns list of upcoming tracks in effective playback order after the current track.
  List<Track> get upcomingTracks {
    final pos = currentEffectivePosition;
    if (pos < 0 || pos >= effectiveIndices.length - 1) return const [];
    final upcomingIndices = effectiveIndices.sublist(pos + 1);
    return upcomingIndices.map((i) => items[i]).toList();
  }

  PlaybackQueue copyWith({
    List<Track>? items,
    int? currentIndex,
    List<int>? shuffledIndices,
    bool? isShuffleEnabled,
  }) {
    return PlaybackQueue(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffledIndices: shuffledIndices ?? this.shuffledIndices,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackQueue &&
          runtimeType == other.runtimeType &&
          currentIndex == other.currentIndex &&
          isShuffleEnabled == other.isShuffleEnabled &&
          _listEquals(items, other.items) &&
          _listEquals(shuffledIndices, other.shuffledIndices);

  @override
  int get hashCode => Object.hash(
    currentIndex,
    isShuffleEnabled,
    Object.hashAll(items),
    Object.hashAll(shuffledIndices),
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
