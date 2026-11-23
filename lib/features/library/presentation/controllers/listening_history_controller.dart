import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../home/data/datasources/home_local_data_source.dart';
import '../../../tracks/data/models/track_model.dart';
import '../../../tracks/data/repositories/track_repository_impl.dart';
import '../../../tracks/domain/entities/track.dart';

/// State representation and persistence for listening history and playback statistics.
class ListeningHistoryNotifier extends Notifier<List<Track>> {
  static const String _storageKey = 'audifi_listening_history_v1';
  static const String _playCountsKey = 'audifi_play_counts_v1';

  bool _loaded = false;
  Map<String, int> _playCounts = {};

  @override
  List<Track> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      if (!_loaded) {
        final prefs = await ref.read(sharedPreferencesAsyncProvider);
        final raw = prefs.getStringList(_storageKey);
        if (raw != null && raw.isNotEmpty) {
          final tracks = <Track>[];
          for (final item in raw) {
            try {
              final map = jsonDecode(item) as Map<String, dynamic>;
              tracks.add(TrackModel.fromJson(map));
            } catch (_) {}
          }
          state = tracks;
        }

        final rawCounts = prefs.getString(_playCountsKey);
        if (rawCounts != null && rawCounts.isNotEmpty) {
          final decoded = jsonDecode(rawCounts);
          if (decoded is Map<String, dynamic>) {
            _playCounts = decoded.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            );
          }
        }

        _loaded = true;
      }
    } catch (_) {}
  }

  /// Adds a track to recent listening history and increments its local play count.
  Future<void> addTrack(Track track) async {
    _playCounts[track.id] = (_playCounts[track.id] ?? 0) + 1;

    final updated = [
      track,
      ...state.where((t) => t.id != track.id),
    ].take(50).toList();

    state = updated;
    await _persist();
  }

  /// Clears recent listening history and play count statistics.
  Future<void> clearHistory() async {
    state = const [];
    _playCounts.clear();
    await _persist();
  }

  /// Convenience alias for [clearHistory].
  Future<void> clear() => clearHistory();

  /// Returns the recorded play count for [trackId].
  int getPlayCount(String trackId) => _playCounts[trackId] ?? 0;

  /// Total count of all track plays recorded locally.
  int get totalPlays => _playCounts.values.fold(0, (sum, c) => sum + c);

  /// Returns the most played tracks sorted by local play count descending.
  List<Track> getMostPlayedTracks({int limit = 10}) {
    final sorted = List<Track>.from(state)
      ..sort((a, b) {
        final countA = _playCounts[a.id] ?? 0;
        final countB = _playCounts[b.id] ?? 0;
        return countB.compareTo(countA);
      });
    return sorted.take(limit).toList();
  }

  /// Returns the top artists based on track play counts.
  List<({String name, String? id, int count})> getTopArtists({int limit = 5}) {
    final artistCounts = <String, ({String? id, int count})>{};
    for (final track in state) {
      final name = track.user?.name;
      if (name != null && name.isNotEmpty) {
        final current = artistCounts[name];
        final playCount = _playCounts[track.id] ?? 1;
        artistCounts[name] = (
          id: track.user?.id,
          count: (current?.count ?? 0) + playCount,
        );
      }
    }

    final sorted = artistCounts.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return sorted
        .take(limit)
        .map((e) => (name: e.key, id: e.value.id, count: e.value.count))
        .toList();
  }

  /// Returns the most frequent genre from the listening history.
  String? getFavoriteGenre() {
    final genreCounts = <String, int>{};
    for (final track in state) {
      final genre = track.genre;
      if (genre != null && genre.trim().isNotEmpty) {
        final playCount = _playCounts[track.id] ?? 1;
        genreCounts[genre] = (genreCounts[genre] ?? 0) + playCount;
      }
    }
    if (genreCounts.isEmpty) return null;

    final sorted = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Future<void> _persist() async {
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      final jsonList = state.map((t) {
        final model = t is TrackModel ? t : TrackModel.fromEntity(t);
        return jsonEncode(model.toJson());
      }).toList();
      await prefs.setStringList(_storageKey, jsonList);
      await prefs.setString(_playCountsKey, jsonEncode(_playCounts));
    } catch (_) {}
  }
}

/// Provider for accessing and managing listening history.
final listeningHistoryProvider =
    NotifierProvider<ListeningHistoryNotifier, List<Track>>(
      ListeningHistoryNotifier.new,
    );

/// Provider generating unauthenticated local recommendations based on listening history
/// with Stale-While-Revalidate caching and offline fallback.
final localRecommendationsProvider = FutureProvider.autoDispose<List<Track>>((
  ref,
) async {
  final history = ref.watch(listeningHistoryProvider);
  final notifier = ref.watch(listeningHistoryProvider.notifier);
  final repository = ref.watch(trackRepositoryProvider);
  final localCache = ref.watch(homeLocalDataSourceProvider);

  if (history.isEmpty) {
    return const [];
  }

  final topGenre = notifier.getFavoriteGenre();
  try {
    final candidateTracks = await repository.getTrendingTracks(
      limit: 15,
      genre: topGenre,
    );

    // Filter out tracks already listened to recently
    final historyIds = history.map((t) => t.id).toSet();
    final filtered = candidateTracks
        .where((t) => !historyIds.contains(t.id))
        .take(10)
        .toList();

    final result = filtered.isNotEmpty
        ? filtered
        : candidateTracks.take(10).toList();
    if (result.isNotEmpty) {
      unawaited(localCache.saveCachedRecommendations(result));
    }
    return result;
  } catch (_) {
    // Attempt reading cached recommendations on failure/offline
    try {
      final cached = await localCache.getCachedRecommendations();
      if (cached.isNotEmpty) return cached;
    } catch (_) {}
    return const [];
  }
});
