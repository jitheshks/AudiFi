import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_content_switcher.dart';
import '../../../../shared/widgets/audifi_empty_state.dart';
import '../../../../shared/widgets/audifi_error_view.dart';
import '../../../../shared/widgets/audifi_loading_indicator.dart';
import '../../../../shared/widgets/audifi_media_card.dart';
import '../../../../shared/widgets/audifi_page_container.dart';
import '../../../../shared/widgets/audifi_search_field.dart';
import '../../../../shared/widgets/audifi_track_tile.dart';
import '../../../../shared/widgets/audifi_underlined_tabs.dart';
import '../../../playback/presentation/controllers/playback_controller.dart';
import '../controllers/search_controller.dart';

/// Search destination view supporting real-time catalog search, debouncing,
/// kind filtering with underlined tabs, and recent search history.
///
/// Fast, simple, and focused: "I know what I want. Help me find it."
/// Zero redundant discovery feeds.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  static const List<AudifiTabItem<String>> _searchTabs = [
    AudifiTabItem(value: 'all', label: 'All'),
    AudifiTabItem(value: 'tracks', label: 'Tracks'),
    AudifiTabItem(value: 'users', label: 'Artists'),
    AudifiTabItem(value: 'playlists', label: 'Playlists'),
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        ref.read(searchControllerProvider.notifier).search(query);
      }
    });
  }

  void _onQuerySubmitted(String query) {
    _debounceTimer?.cancel();
    ref.read(searchControllerProvider.notifier).search(query);
  }

  void _onClear() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(searchControllerProvider.notifier).clear();
  }

  void _triggerSearch(String query) {
    _searchController.text = query;
    _onQuerySubmitted(query);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      body: AudifiPageContainer(
        scrollable: false,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safe Area Top Padding
            SizedBox(height: MediaQuery.paddingOf(context).top + 10.0),

            // Heading: Search
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 14.0),
              child: Text(
                'Search',
                style: AppTypography.h1.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: AudifiSearchField(
                controller: _searchController,
                hintText: 'Search songs, artists, or playlists',
                onChanged: _onQueryChanged,
                onSubmitted: _onQuerySubmitted,
                onClear: _onClear,
              ),
            ),

            AppSpacing.vGap12,

            // If a search query is active, show the kind filter tabs
            if (searchState.query.isNotEmpty) ...[
              AudifiUnderlinedTabs<String>(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                tabs: _searchTabs,
                selectedValue: searchState.kind,
                onTabSelected: (kind) {
                  ref.read(searchControllerProvider.notifier).setKind(kind);
                },
              ),
              AppSpacing.vGap12,
            ],

            // Content: Initial Browse (Recent Searches) or Search Results
            Expanded(
              child: AudifiContentSwitcher(
                child: searchState.query.isEmpty
                    ? _buildInitialSearchScreen(context, colors, searchState)
                    : _buildSearchResults(context, colors, searchState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Initial screen displayed when query is empty: focused on recent searches
  /// and search guidance.
  Widget _buildInitialSearchScreen(
    BuildContext context,
    AudifiThemeColors colors,
    SearchState searchState,
  ) {
    final recents = searchState.recentSearches;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        key: const ValueKey('search_recent_list'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recents.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Searches',
                    style: AppTypography.h3.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(searchControllerProvider.notifier)
                        .clearRecentSearches();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vGap8,
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: recents.map((item) {
                return InputChip(
                  label: Text(item),
                  labelStyle: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.0,
                  ),
                  backgroundColor: colors.surface1,
                  deleteIcon: Icon(
                    Icons.close_rounded,
                    size: 16.0,
                    color: colors.textMuted,
                  ),
                  onDeleted: () {
                    ref
                        .read(searchControllerProvider.notifier)
                        .removeRecentSearch(item);
                  },
                  onPressed: () => _triggerSearch(item),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(
                      color: colors.surface2.withValues(alpha: 0.8),
                    ),
                  ),
                );
              }).toList(),
            ),
            AppSpacing.vGap24,
          ] else ...[
            // Clean centered search prompt when no recent searches
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 56.0,
                      color: colors.textMuted.withValues(alpha: 0.5),
                    ),
                    AppSpacing.vGap16,
                    Text(
                      'Find What You Love',
                      style: AppTypography.h3.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.vGap6,
                    Text(
                      'Search for tracks, artists, or playlists across Audius.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds active search results based on selected tab and controller state.
  Widget _buildSearchResults(
    BuildContext context,
    AudifiThemeColors colors,
    SearchState state,
  ) {
    return state.results.when(
      loading: () => const Center(
        key: ValueKey('search_loading'),
        child: AudifiLoadingIndicator(size: 32.0),
      ),
      error: (err, stack) => Center(
        key: const ValueKey('search_error'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AudifiErrorView(
            message: err.toString(),
            onRetry: () =>
                ref.read(searchControllerProvider.notifier).search(state.query),
          ),
        ),
      ),
      data: (result) {
        if (result.isEmpty) {
          return Center(
            key: const ValueKey('search_empty'),
            child: AudifiEmptyState(
              title: 'No Results Found',
              description:
                  'No matches found for "${state.query}". Try searching with different keywords.',
              icon: Icons.search_off_rounded,
            ),
          );
        }

        return ListView(
          key: ValueKey('search_${state.kind}_data'),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          children: [
            if (state.kind == 'all' || state.kind == 'tracks') ...[
              if (result.tracks.isNotEmpty) ...[
                Text(
                  'Tracks',
                  style: AppTypography.h3.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.vGap8,
                ...result.tracks.map((track) {
                  return AudifiTrackTile(
                    track: track,
                    onTap: () {
                      ref
                          .read(playbackControllerProvider.notifier)
                          .playTrack(track, contextTracks: result.tracks);
                    },
                  );
                }),
                AppSpacing.vGap16,
              ],
            ],

            if (state.kind == 'all' || state.kind == 'users') ...[
              if (result.users.isNotEmpty) ...[
                Text(
                  'Artists',
                  style: AppTypography.h3.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.vGap8,
                SizedBox(
                  height: 195.0,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: result.users.length,
                    separatorBuilder: (context, index) => AppSpacing.hGap12,
                    itemBuilder: (context, index) {
                      final user = result.users[index];
                      return AudifiMediaCard(
                        title: user.name,
                        subtitle: user.atHandle,
                        imageUrl: user.profilePicture?.primaryUrl,
                        isCircle: true,
                        onTap: () {
                          context.push(RoutePaths.artist(user.id));
                        },
                      );
                    },
                  ),
                ),
                AppSpacing.vGap16,
              ],
            ],

            if (state.kind == 'all' || state.kind == 'playlists') ...[
              if (result.playlists.isNotEmpty) ...[
                Text(
                  'Playlists',
                  style: AppTypography.h3.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.vGap8,
                SizedBox(
                  height: 195.0,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: result.playlists.length,
                    separatorBuilder: (context, index) => AppSpacing.hGap12,
                    itemBuilder: (context, index) {
                      final playlist = result.playlists[index];
                      return AudifiMediaCard(
                        title: playlist.playlistName,
                        subtitle: playlist.user?.name ?? 'Audius Curator',
                        imageUrl: playlist.artwork?.primaryUrl,
                        onTap: () {
                          context.push(RoutePaths.playlist(playlist.id));
                        },
                      );
                    },
                  ),
                ),
              ],
            ],

            const SizedBox(height: 32.0),
          ],
        );
      },
    );
  }
}
