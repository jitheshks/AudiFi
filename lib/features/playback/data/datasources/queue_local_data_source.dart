import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../shared/models/artwork.dart';
import '../../../artists/domain/entities/user.dart';
import '../../../tracks/domain/entities/track.dart';

/// Local data source persisting and restoring queue state across app launches.
/// Stream URLs are explicitly never persisted because Audius node tokens expire.
class QueueLocalDataSource {
  const QueueLocalDataSource({required this.prefsAsync});

  final Future<SharedPreferences> prefsAsync;

  static const String _queueStorageKey = 'audifi_playback_queue_v1';

  /// Persists the active track list and current index to local storage.
  Future<void> saveQueue({
    required List<Track> tracks,
    required int currentIndex,
  }) async {
    try {
      final prefs = await prefsAsync;
      if (tracks.isEmpty) {
        await prefs.remove(_queueStorageKey);
        return;
      }

      final serializableList = tracks.map((t) {
        return {
          'id': t.id,
          'title': t.title,
          'duration': t.duration,
          'artworkUrl': t.artwork?.primaryUrl,
          'userId': t.user?.id,
          'userName': t.user?.name,
          'userHandle': t.user?.handle,
          'isVerified': t.user?.isVerified ?? false,
          'genre': t.genre,
          'mood': t.mood,
          'playCount': t.playCount,
        };
      }).toList();

      final payload = jsonEncode({
        'currentIndex': currentIndex,
        'tracks': serializableList,
      });

      await prefs.setString(_queueStorageKey, payload);
      AppLogger.debug(
        'Saved ${tracks.length} queue tracks to local storage',
        tag: 'Playback',
      );
    } catch (e, st) {
      AppLogger.warning(
        'Failed to save playback queue to local storage',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Restores persisted track state from local storage.
  Future<({List<Track> tracks, int currentIndex})?> restoreQueue() async {
    try {
      final prefs = await prefsAsync;
      final raw = prefs.getString(_queueStorageKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final currentIndex = (decoded['currentIndex'] as num?)?.toInt() ?? 0;
      final rawTracks = decoded['tracks'];
      if (rawTracks is! List<dynamic>) return null;

      final tracks = <Track>[];
      for (final item in rawTracks) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] as String?;
          final title = item['title'] as String?;
          if (id == null || title == null) continue;

          final artworkUrl = item['artworkUrl'] as String?;
          final userId = item['userId'] as String?;
          final userName = item['userName'] as String?;
          final userHandle = item['userHandle'] as String?;
          final isVerified = item['isVerified'] as bool? ?? false;

          final user = userId != null
              ? User(
                  id: userId,
                  name: userName ?? 'Artist',
                  handle: userHandle ?? '',
                  isVerified: isVerified,
                )
              : null;

          final artwork = artworkUrl != null
              ? Artwork(
                  small: artworkUrl,
                  medium: artworkUrl,
                  large: artworkUrl,
                )
              : null;

          tracks.add(
            Track(
              id: id,
              title: title,
              duration: (item['duration'] as num?)?.toInt() ?? 0,
              genre: item['genre'] as String?,
              mood: item['mood'] as String?,
              playCount: (item['playCount'] as num?)?.toInt() ?? 0,
              artwork: artwork,
              user: user,
            ),
          );
        }
      }

      if (tracks.isEmpty) return null;

      return (
        tracks: tracks,
        currentIndex: currentIndex.clamp(0, tracks.length - 1),
      );
    } catch (e, st) {
      AppLogger.warning(
        'Failed to restore playback queue from local storage',
        tag: 'Playback',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Clears stored queue from local storage.
  Future<void> clearQueue() async {
    try {
      final prefs = await prefsAsync;
      await prefs.remove(_queueStorageKey);
    } catch (e) {
      AppLogger.warning(
        'Failed to clear playback queue',
        tag: 'Playback',
        error: e,
      );
    }
  }
}

/// Riverpod provider for [QueueLocalDataSource].
final queueLocalDataSourceProvider = Provider<QueueLocalDataSource>((ref) {
  return QueueLocalDataSource(prefsAsync: SharedPreferences.getInstance());
});
