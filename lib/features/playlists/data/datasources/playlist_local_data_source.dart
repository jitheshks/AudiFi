import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../domain/entities/playlist.dart';
import '../models/playlist_model.dart';

/// Local data source persisting custom user-created playlists in [SharedPreferences].
class PlaylistLocalDataSource {
  const PlaylistLocalDataSource({required this.prefsAsync});

  final Future<SharedPreferences> prefsAsync;

  static const String _customPlaylistsKey = 'audifi_custom_playlists_v1';

  /// Reads and deserializes all custom playlists from local storage.
  Future<List<Playlist>> getCustomPlaylists() async {
    try {
      final prefs = await prefsAsync;
      final raw = prefs.getString(_customPlaylistsKey);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PlaylistModel.fromJson)
          .toList();
    } catch (e, st) {
      AppLogger.warning(
        'Failed to read custom playlists from local storage',
        tag: 'PlaylistLocalDataSource',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  /// Serializes and stores all custom playlists to local storage.
  Future<void> saveCustomPlaylists(List<Playlist> playlists) async {
    try {
      final prefs = await prefsAsync;
      final serialized = playlists.map((p) {
        if (p is PlaylistModel) return p.toJson();
        return PlaylistModel.fromEntity(p).toJson();
      }).toList();

      await prefs.setString(_customPlaylistsKey, jsonEncode(serialized));
    } catch (e, st) {
      AppLogger.warning(
        'Failed to save custom playlists to local storage',
        tag: 'PlaylistLocalDataSource',
        error: e,
        stackTrace: st,
      );
    }
  }
}

/// Provider for [PlaylistLocalDataSource].
final playlistLocalDataSourceProvider = Provider<PlaylistLocalDataSource>((
  ref,
) {
  final prefsAsync = ref.watch(sharedPreferencesAsyncProvider);
  return PlaylistLocalDataSource(prefsAsync: prefsAsync);
});
