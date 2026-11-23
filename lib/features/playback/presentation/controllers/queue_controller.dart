import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tracks/domain/entities/track.dart';
import '../../data/repositories/playback_repository_impl.dart';
import '../../data/services/audifi_audio_handler.dart';
import '../../domain/entities/playback_queue.dart';
import '../../domain/repositories/playback_repository.dart';
import 'audio_player_providers.dart';

/// Riverpod controller managing the playback queue, ordering, shuffling, and persistence.
class QueueController extends Notifier<PlaybackQueue> {
  PlaybackRepository get _repository => ref.read(playbackRepositoryProvider);

  @override
  PlaybackQueue build() {
    try {
      final handler = ref.read(audioHandlerProvider);
      if (handler is AudifiAudioHandler && handler.queueTracks.isNotEmpty) {
        final tracks = handler.queueTracks;
        final currentIdx = handler.currentIndex.clamp(0, tracks.length - 1);
        final shuffled =
            handler.isShuffle && handler.shuffledIndices.length == tracks.length
            ? handler.shuffledIndices
            : _generateShuffledIndices(
                tracks.length,
                currentIdx,
                handler.isShuffle,
              );
        return PlaybackQueue(
          items: tracks,
          currentIndex: currentIdx,
          isShuffleEnabled: handler.isShuffle,
          shuffledIndices: shuffled,
        );
      }
    } catch (_) {}
    return PlaybackQueue.empty;
  }

  void _syncWithAudioHandler() {
    try {
      final handler = ref.read(audioHandlerProvider);
      if (handler is AudifiAudioHandler) {
        handler.syncQueue(
          state.items,
          currentIndex: state.currentIndex,
          isShuffle: state.isShuffleEnabled,
          shuffledIndices: state.shuffledIndices,
        );
      }
    } catch (_) {}
  }

  /// Sets the active queue with a list of [tracks] starting at [startIndex].
  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    if (tracks.isEmpty) {
      state = PlaybackQueue.empty;
      _repository.clearSavedQueue();
      _syncWithAudioHandler();
      return;
    }

    final validIndex = startIndex.clamp(0, tracks.length - 1);
    final shuffled = _generateShuffledIndices(
      tracks.length,
      validIndex,
      state.isShuffleEnabled,
    );

    state = state.copyWith(
      items: tracks,
      currentIndex: validIndex,
      shuffledIndices: shuffled,
    );

    _repository.saveQueue(tracks: tracks, currentIndex: validIndex);
    _syncWithAudioHandler();
  }

  /// Plays [track], setting up the queue either from [contextTracks] or by
  /// inserting into the existing queue.
  void playTrack(Track track, {List<Track>? contextTracks}) {
    if (contextTracks != null && contextTracks.isNotEmpty) {
      final index = contextTracks.indexWhere((t) => t.id == track.id);
      setQueue(contextTracks, startIndex: index >= 0 ? index : 0);
      return;
    }

    // Context not provided: search existing queue
    final existingIndex = state.items.indexWhere((t) => t.id == track.id);
    if (existingIndex >= 0) {
      setCurrentIndex(existingIndex);
      return;
    }

    // Insert into queue right after current index
    final newItems = List<Track>.from(state.items);
    final insertPos =
        state.currentIndex >= 0 && state.currentIndex < newItems.length
        ? state.currentIndex + 1
        : newItems.length;

    newItems.insert(insertPos, track);
    final shuffled = _generateShuffledIndices(
      newItems.length,
      insertPos,
      state.isShuffleEnabled,
    );

    state = state.copyWith(
      items: newItems,
      currentIndex: insertPos,
      shuffledIndices: shuffled,
    );

    _repository.saveQueue(tracks: newItems, currentIndex: insertPos);
    _syncWithAudioHandler();
  }

  /// Inserts [track] immediately after the currently playing track.
  void playNext(Track track) {
    if (state.isEmpty) {
      playTrack(track);
      return;
    }

    final newItems = List<Track>.from(state.items);
    final insertPos = state.currentIndex + 1;
    newItems.insert(insertPos, track);

    final shuffled = _generateShuffledIndices(
      newItems.length,
      state.currentIndex,
      state.isShuffleEnabled,
    );

    state = state.copyWith(items: newItems, shuffledIndices: shuffled);

    _repository.saveQueue(tracks: newItems, currentIndex: state.currentIndex);
    _syncWithAudioHandler();
  }

  /// Appends [track] to the end of the current queue.
  void addToQueue(Track track) {
    if (state.isEmpty) {
      playTrack(track);
      return;
    }

    final newItems = List<Track>.from(state.items)..add(track);
    final shuffled = _generateShuffledIndices(
      newItems.length,
      state.currentIndex,
      state.isShuffleEnabled,
    );

    state = state.copyWith(items: newItems, shuffledIndices: shuffled);

    _repository.saveQueue(tracks: newItems, currentIndex: state.currentIndex);
    _syncWithAudioHandler();
  }

  /// Appends multiple [tracks] to the queue.
  void addTracksToQueue(List<Track> tracks) {
    if (tracks.isEmpty) return;
    if (state.isEmpty) {
      setQueue(tracks);
      return;
    }

    final newItems = List<Track>.from(state.items)..addAll(tracks);
    final shuffled = _generateShuffledIndices(
      newItems.length,
      state.currentIndex,
      state.isShuffleEnabled,
    );

    state = state.copyWith(items: newItems, shuffledIndices: shuffled);

    _repository.saveQueue(tracks: newItems, currentIndex: state.currentIndex);
    _syncWithAudioHandler();
  }

  /// Sets the active index in the queue.
  void setCurrentIndex(int index) {
    if (index < 0 || index >= state.items.length) return;
    state = state.copyWith(currentIndex: index);
    _repository.saveQueue(tracks: state.items, currentIndex: index);
    _syncWithAudioHandler();
  }

  /// Removes the track at [index] from the queue.
  void removeFromQueue(int index) {
    if (index < 0 || index >= state.items.length) return;

    final newItems = List<Track>.from(state.items)..removeAt(index);
    if (newItems.isEmpty) {
      state = PlaybackQueue.empty;
      _repository.clearSavedQueue();
      _syncWithAudioHandler();
      return;
    }

    int newCurrent = state.currentIndex;
    if (index < state.currentIndex) {
      newCurrent = state.currentIndex - 1;
    } else if (newCurrent >= newItems.length) {
      newCurrent = newItems.length - 1;
    }

    final shuffled = _generateShuffledIndices(
      newItems.length,
      newCurrent,
      state.isShuffleEnabled,
    );

    state = state.copyWith(
      items: newItems,
      currentIndex: newCurrent,
      shuffledIndices: shuffled,
    );

    _repository.saveQueue(tracks: newItems, currentIndex: newCurrent);
    _syncWithAudioHandler();
  }

  /// Reorders a track from [oldIndex] to [newIndex].
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.items.length) return;
    if (newIndex < 0 || newIndex > state.items.length) return;

    final currentTrack = state.currentTrack;
    final newItems = List<Track>.from(state.items);

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }

    final movedItem = newItems.removeAt(oldIndex);
    newItems.insert(targetIndex, movedItem);

    // Maintain current playing track reference
    final newCurrent = currentTrack != null
        ? newItems.indexWhere((t) => t.id == currentTrack.id)
        : 0;

    final shuffled = _generateShuffledIndices(
      newItems.length,
      newCurrent >= 0 ? newCurrent : 0,
      state.isShuffleEnabled,
    );

    state = state.copyWith(
      items: newItems,
      currentIndex: newCurrent >= 0 ? newCurrent : 0,
      shuffledIndices: shuffled,
    );

    _repository.saveQueue(tracks: newItems, currentIndex: state.currentIndex);
    _syncWithAudioHandler();
  }

  /// Clears upcoming queue tracks, retaining only the currently active track.
  void clearQueue() {
    final current = state.currentTrack;
    if (current == null) {
      state = PlaybackQueue.empty;
      _repository.clearSavedQueue();
      _syncWithAudioHandler();
      return;
    }

    state = state.copyWith(
      items: [current],
      currentIndex: 0,
      shuffledIndices: [0],
    );

    _repository.saveQueue(tracks: [current], currentIndex: 0);
    _syncWithAudioHandler();
  }

  /// Toggles shuffle mode and recalculates the shuffle permutation.
  void toggleShuffle() {
    final newShuffle = !state.isShuffleEnabled;
    final shuffled = _generateShuffledIndices(
      state.items.length,
      state.currentIndex,
      newShuffle,
    );

    state = state.copyWith(
      isShuffleEnabled: newShuffle,
      shuffledIndices: shuffled,
    );
    _syncWithAudioHandler();
  }

  /// Advances to the next track in the queue, returning the new [Track] or null.
  Track? advanceToNext({bool loop = false}) {
    if (state.isEmpty) return null;

    final nextIdx = state.nextIndex;
    if (nextIdx != null) {
      setCurrentIndex(nextIdx);
      return state.currentTrack;
    }

    if (loop && state.effectiveIndices.isNotEmpty) {
      final firstIdx = state.effectiveIndices.first;
      setCurrentIndex(firstIdx);
      return state.currentTrack;
    }

    return null;
  }

  /// Steps to the previous track in the queue, returning the new [Track] or null.
  Track? stepToPrevious() {
    if (state.isEmpty) return null;

    final prevIdx = state.previousIndex;
    if (prevIdx != null) {
      setCurrentIndex(prevIdx);
      return state.currentTrack;
    }

    return null;
  }

  /// Restores persisted queue state from local storage.
  Future<void> restoreQueue() async {
    final restored = await _repository.restoreQueue();
    if (restored != null && restored.tracks.isNotEmpty) {
      final shuffled = _generateShuffledIndices(
        restored.tracks.length,
        restored.currentIndex,
        state.isShuffleEnabled,
      );

      state = state.copyWith(
        items: restored.tracks,
        currentIndex: restored.currentIndex,
        shuffledIndices: shuffled,
      );
      _syncWithAudioHandler();
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

/// Riverpod provider for [QueueController].
final queueControllerProvider =
    NotifierProvider<QueueController, PlaybackQueue>(QueueController.new);
