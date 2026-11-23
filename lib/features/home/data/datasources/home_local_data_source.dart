import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../tracks/data/models/track_model.dart';
import '../../../tracks/domain/entities/track.dart';

/// Local data source persisting cached Home screen feed content
/// to support instantaneous Stale-While-Revalidate (SWR) cold launches
/// and robust offline playback resilience.
class HomeLocalDataSource {
  const HomeLocalDataSource({required this.prefsAsync});

  final Future<SharedPreferences> prefsAsync;

  static const String _trendingCacheKey = 'audifi_home_trending_cache_v1';
  static const String _recsCacheKey = 'audifi_home_recs_cache_v1';

  /// Retrieves locally cached trending tracks from [SharedPreferences].
  Future<List<Track>> getCachedTrendingTracks() async {
    return _readTracksFromStorage(_trendingCacheKey);
  }

  /// Persists fresh trending tracks to [SharedPreferences].
  Future<void> saveCachedTrendingTracks(List<Track> tracks) async {
    await _writeTracksToStorage(_trendingCacheKey, tracks);
  }

  /// Retrieves locally cached personalized recommendations from [SharedPreferences].
  Future<List<Track>> getCachedRecommendations() async {
    return _readTracksFromStorage(_recsCacheKey);
  }

  /// Persists fresh personalized recommendations to [SharedPreferences].
  Future<void> saveCachedRecommendations(List<Track> tracks) async {
    await _writeTracksToStorage(_recsCacheKey, tracks);
  }

  /// Helper reading a JSON list of tracks from [key].
  Future<List<Track>> _readTracksFromStorage(String key) async {
    try {
      final prefs = await prefsAsync;
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];

      final tracks = <Track>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            tracks.add(TrackModel.fromJson(item));
          } catch (_) {}
        }
      }
      return tracks;
    } catch (e, st) {
      AppLogger.warning(
        'Failed reading cached tracks from key "$key"',
        tag: 'HomeLocalDataSource',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  /// Helper writing a list of tracks to [key] as a JSON string.
  Future<void> _writeTracksToStorage(String key, List<Track> tracks) async {
    try {
      final prefs = await prefsAsync;
      final serialized = tracks.map((t) {
        final model = t is TrackModel ? t : TrackModel.fromEntity(t);
        return model.toJson();
      }).toList();

      await prefs.setString(key, jsonEncode(serialized));
    } catch (e, st) {
      AppLogger.warning(
        'Failed saving tracks to cache key "$key"',
        tag: 'HomeLocalDataSource',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Clears cached Home feed data.
  Future<void> clearCache() async {
    try {
      final prefs = await prefsAsync;
      await Future.wait([
        prefs.remove(_trendingCacheKey),
        prefs.remove(_recsCacheKey),
      ]);
    } catch (_) {}
  }
}

/// Riverpod provider delivering [HomeLocalDataSource].
final homeLocalDataSourceProvider = Provider<HomeLocalDataSource>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesAsyncProvider);
  return HomeLocalDataSource(prefsAsync: prefsAsync);
});
