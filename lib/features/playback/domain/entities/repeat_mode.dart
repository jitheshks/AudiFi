/// Repeat modes for audio playback.
enum RepeatMode {
  /// Play through queue once, then stop when queue finishes.
  off,

  /// Loop continuously through the entire queue.
  all,

  /// Loop continuously on the current single track.
  one;

  /// Returns the next repeat mode in cycle: off -> all -> one -> off.
  RepeatMode get next {
    switch (this) {
      case RepeatMode.off:
        return RepeatMode.all;
      case RepeatMode.all:
        return RepeatMode.one;
      case RepeatMode.one:
        return RepeatMode.off;
    }
  }

  /// User-facing descriptive label for accessibility and UI.
  String get label {
    switch (this) {
      case RepeatMode.off:
        return 'Repeat Off';
      case RepeatMode.all:
        return 'Repeat All';
      case RepeatMode.one:
        return 'Repeat One';
    }
  }

  /// Whether repeat is currently active in any mode.
  bool get isActive => this != RepeatMode.off;
}
