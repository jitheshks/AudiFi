import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../tracks/data/repositories/track_repository_impl.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../../tracks/domain/repositories/track_repository.dart';
import '../../data/datasources/home_local_data_source.dart';

/// Riverpod controller managing trending tracks list and active genre filtering
/// with Stale-While-Revalidate (SWR) caching and offline resilience.
class TrendingTracksController extends AsyncNotifier<List<Track>> {
  String? _selectedGenre;

  /// Currently selected genre filter (null signifies 'All' genres).
  String? get selectedGenre => _selectedGenre;

  HomeLocalDataSource get _localCache => ref.read(homeLocalDataSourceProvider);
  TrackRepository get _repository => ref.read(trackRepositoryProvider);

  @override
  FutureOr<List<Track>> build() async {
    // 1. Immediately read cached content if available (for default 'All' genre)
    List<Track> cached = const [];
    if (_selectedGenre == null) {
      try {
        cached = await _localCache.getCachedTrendingTracks();
      } catch (e) {
        AppLogger.warning('Failed to read cached trending tracks', error: e);
      }
    }

    if (cached.isNotEmpty) {
      // Background revalidation: fetch fresh content in background
      unawaited(_revalidateInBackground());
      // Return cached tracks immediately without full-screen loading
      return cached;
    }

    // 2. No cache available: perform synchronous initial fetch
    return _fetchAndCacheFresh();
  }

  /// Revalidates fresh content in the background without clearing the UI.
  Future<void> _revalidateInBackground() async {
    try {
      final fresh = await _repository.getTrendingTracks(genre: _selectedGenre);
      if (fresh.isNotEmpty) {
        if (_selectedGenre == null) {
          await _localCache.saveCachedTrendingTracks(fresh);
        }
        state = AsyncValue.data(fresh);
      }
    } catch (e, st) {
      AppLogger.warning(
        'Background revalidation failed for trending tracks; preserving cached data',
        tag: 'TrendingTracksController',
        error: e,
        stackTrace: st,
      );
      // Preserve existing cached state
    }
  }

  Future<List<Track>> _fetchAndCacheFresh() async {
    try {
      final fresh = await _repository.getTrendingTracks(genre: _selectedGenre);
      if (_selectedGenre == null && fresh.isNotEmpty) {
        await _localCache.saveCachedTrendingTracks(fresh);
      }
      return fresh;
    } catch (error, stackTrace) {
      // If we already have cached tracks in state, preserve them on failure
      if (state.hasValue && state.value!.isNotEmpty) {
        AppLogger.warning(
          'Trending tracks request failed; falling back to cached state',
          tag: 'TrendingTracksController',
          error: error,
          stackTrace: stackTrace,
        );
        return state.value!;
      }
      throw ErrorMapper.mapToFailure(error);
    }
  }

  /// Sets the active genre filter and re-fetches trending tracks.
  Future<void> setGenre(String? genre) async {
    if (_selectedGenre == genre && state.hasValue) return;
    _selectedGenre = genre;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchAndCacheFresh);
  }

  /// Refreshes the trending tracks for the currently selected genre.
  /// If cached content exists and network request fails, preserves cached content.
  Future<void> refresh() async {
    try {
      final fresh = await _repository.getTrendingTracks(genre: _selectedGenre);
      if (_selectedGenre == null && fresh.isNotEmpty) {
        await _localCache.saveCachedTrendingTracks(fresh);
      }
      state = AsyncValue.data(fresh);
    } catch (error, stackTrace) {
      if (state.hasValue && state.value!.isNotEmpty) {
        AppLogger.warning(
          'Trending tracks refresh failed; preserving cached data',
          tag: 'TrendingTracksController',
          error: error,
        );
        // Do not overwrite state with error if cached data is present
        return;
      }
      state = AsyncValue.error(ErrorMapper.mapToFailure(error), stackTrace);
    }
  }
}

/// Provider for [TrendingTracksController].
final trendingTracksControllerProvider =
    AsyncNotifierProvider<TrendingTracksController, List<Track>>(
      TrendingTracksController.new,
    );
