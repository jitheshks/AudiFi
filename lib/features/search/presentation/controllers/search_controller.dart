import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

/// State representation for catalog search including query, filter kind,
/// asynchronous results, and persisted recent search history.
class SearchState {
  const SearchState({
    this.query = '',
    this.kind = 'all',
    this.results = const AsyncValue.data(SearchResult()),
    this.recentSearches = const [],
  });

  /// Current search input query.
  final String query;

  /// Active kind filter ('all', 'tracks', 'users', 'playlists', 'albums').
  final String kind;

  /// Asynchronous state of search results.
  final AsyncValue<SearchResult> results;

  /// Recent search queries history.
  final List<String> recentSearches;

  SearchState copyWith({
    String? query,
    String? kind,
    AsyncValue<SearchResult>? results,
    List<String>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      kind: kind ?? this.kind,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

/// Riverpod Notifier managing search query state, debouncing, history persistence,
/// and stale-response prevention.
class SearchController extends Notifier<SearchState> {
  static const String _recentStorageKey = 'audifi_recent_searches_v1';
  int _requestId = 0;
  bool _historyLoaded = false;

  @override
  SearchState build() {
    _loadRecentSearches();
    return const SearchState();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      if (!_historyLoaded) {
        final list = prefs.getStringList(_recentStorageKey);
        if (list != null && list.isNotEmpty) {
          state = state.copyWith(
            recentSearches: [
              ...state.recentSearches,
              ...list.where((s) => !state.recentSearches.contains(s)),
            ],
          );
        }
        _historyLoaded = true;
      }
    } catch (_) {}
  }

  Future<void> _persistRecentSearches(List<String> searches) async {
    try {
      final prefs = await ref.read(sharedPreferencesAsyncProvider);
      await prefs.setStringList(_recentStorageKey, searches);
    } catch (_) {}
  }

  /// Executes catalog search while preventing race conditions / stale results.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed == state.query && state.results.hasValue) return;

    if (trimmed.isEmpty) {
      _requestId++;
      state = state.copyWith(
        query: '',
        results: const AsyncValue.data(SearchResult()),
      );
      return;
    }

    final currentId = ++_requestId;
    state = state.copyWith(query: trimmed, results: const AsyncValue.loading());

    // Record into recent searches history
    final updatedRecent = [
      trimmed,
      ...state.recentSearches.where(
        (s) => s.toLowerCase() != trimmed.toLowerCase(),
      ),
    ].take(10).toList();
    state = state.copyWith(recentSearches: updatedRecent);
    _persistRecentSearches(updatedRecent);

    try {
      final SearchRepository repository = ref.read(searchRepositoryProvider);
      final kindParam = state.kind == 'all' ? null : state.kind;
      final results = await repository.search(trimmed, kind: kindParam);

      // Verify this response corresponds to the latest issued query
      if (currentId == _requestId) {
        state = state.copyWith(results: AsyncValue.data(results));
      }
    } catch (error, stackTrace) {
      if (currentId == _requestId) {
        final failure = ErrorMapper.mapToFailure(error);
        state = state.copyWith(results: AsyncValue.error(failure, stackTrace));
      }
    }
  }

  /// Updates the active content kind filter and re-executes search if query is non-empty.
  Future<void> setKind(String kind) async {
    if (state.kind == kind) return;
    state = state.copyWith(kind: kind);
    if (state.query.isNotEmpty) {
      await search(state.query);
    }
  }

  /// Removes an individual recent search query.
  void removeRecentSearch(String query) {
    _historyLoaded = true;
    final updated = state.recentSearches.where((s) => s != query).toList();
    state = state.copyWith(recentSearches: updated);
    _persistRecentSearches(updated);
  }

  /// Clears recent searches history.
  void clearRecentSearches() {
    _historyLoaded = true;
    state = state.copyWith(recentSearches: const []);
    _persistRecentSearches(const []);
  }

  /// Clears the current search input and resets results.
  void clear() {
    _requestId++;
    state = state.copyWith(
      query: '',
      results: const AsyncValue.data(SearchResult()),
    );
  }
}

/// Provider for [SearchController].
final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);
