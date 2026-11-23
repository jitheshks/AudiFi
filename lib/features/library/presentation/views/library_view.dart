import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_button.dart';
import '../../../../shared/widgets/audifi_card.dart';
import '../../../../shared/widgets/audifi_content_switcher.dart';
import '../../../../shared/widgets/audifi_page_container.dart';
import '../../../../shared/widgets/audifi_search_field.dart';
import '../../../../shared/widgets/audifi_track_tile.dart';
import '../../../downloads/domain/entities/downloaded_track.dart';
import '../../../downloads/presentation/controllers/download_controller.dart';
import '../../../local_files/domain/entities/local_audio_track.dart';
import '../../../local_files/presentation/controllers/local_files_controller.dart';
import '../../../playback/presentation/controllers/playback_controller.dart';
import '../../../playlists/presentation/controllers/custom_playlists_controller.dart';
import '../../../playlists/presentation/widgets/create_playlist_dialog.dart';
import '../../../tracks/domain/entities/track.dart';
import '../controllers/library_controller.dart';
import '../controllers/listening_history_controller.dart';

/// Categories for filtering user collection in Library.
enum LibraryCategory {
  all,
  tracks,
  playlists,
  downloaded,
  localFiles,
  artists,
  history;

  static const liked = tracks;
  static const downloads = downloaded;
}

/// Backwards compatibility alias for existing navigation references.
typedef LibraryTab = LibraryCategory;

enum LibrarySort { recentlyAdded, title, artist }

/// Library destination view representing personal collections:
/// Liked tracks, Custom/Followed Playlists, Offline Downloads, Imported Local Files,
/// Followed Artists, and Listening History.
///
/// Features Spotify-inspired horizontal filter chips, real-time in-library search,
/// multi-field sorting, and responsive Shuffle / Play All controls.
class LibraryView extends ConsumerStatefulWidget {
  const LibraryView({super.key, this.initialTab});

  /// Optional initial category selection (e.g. from Home shortcuts).
  final LibraryCategory? initialTab;

  @override
  ConsumerState<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends ConsumerState<LibraryView> {
  late LibraryCategory _activeCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  LibrarySort _sortOrder = LibrarySort.recentlyAdded;

  static const List<({LibraryCategory category, String label})>
  _chipCategories = [
    (category: LibraryCategory.all, label: 'All'),
    (category: LibraryCategory.tracks, label: 'Liked'),
    (category: LibraryCategory.playlists, label: 'Playlists'),
    (category: LibraryCategory.downloaded, label: 'Downloads'),
    (category: LibraryCategory.localFiles, label: 'Local Files'),
    (category: LibraryCategory.artists, label: 'Artists'),
    (category: LibraryCategory.history, label: 'History'),
  ];

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialTab ?? LibraryCategory.tracks;
  }

  @override
  void didUpdateWidget(covariant LibraryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null &&
        widget.initialTab != oldWidget.initialTab) {
      setState(() => _activeCategory = widget.initialTab!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query.trim().toLowerCase());
  }

  void _onSearchClear() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  List<Track> _applySorting(List<Track> tracks) {
    final list = List<Track>.from(tracks);
    switch (_sortOrder) {
      case LibrarySort.recentlyAdded:
        return list; // Preserves recent insertion order
      case LibrarySort.title:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        return list;
      case LibrarySort.artist:
        list.sort((a, b) {
          final artA = a.user?.name.toLowerCase() ?? '';
          final artB = b.user?.name.toLowerCase() ?? '';
          return artA.compareTo(artB);
        });
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final library = ref.watch(libraryControllerProvider);
    final history = ref.watch(listeningHistoryProvider);
    final downloads = ref.watch(downloadedTracksProvider);
    final localTracks = ref.watch(localFilesControllerProvider);

    return Scaffold(
      body: AudifiPageContainer(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safe Area Top Padding
            SizedBox(height: MediaQuery.paddingOf(context).top + 10.0),

            // Heading: Library
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 4.0),
              child: Text(
                'Library',
                style: AppTypography.h1.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Subtitle: Your saved collection
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 10.0),
              child: Text(
                'Your saved music and offline collection',
                style: TextStyle(fontSize: 13.0, color: colors.textMuted),
              ),
            ),

            // In-Library Search Field for real-time collection filtering
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: AudifiSearchField(
                controller: _searchController,
                hintText: 'Search within your library',
                onChanged: _onSearchChanged,
                onClear: _onSearchClear,
              ),
            ),

            AppSpacing.vGap12,

            // Spotify-inspired Horizontal Category Filter Chips
            SizedBox(
              height: 38.0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    for (int i = 0; i < _chipCategories.length; i++) ...[
                      if (i > 0) AppSpacing.hGap8,
                      () {
                        final item = _chipCategories[i];
                        final isSelected = _activeCategory == item.category;

                        return Semantics(
                          button: true,
                          selected: isSelected,
                          label: '${item.label} filter',
                          child: InkWell(
                            key: ValueKey('library_chip_${item.category.name}'),
                            onTap: () {
                              setState(() => _activeCategory = item.category);
                            },
                            borderRadius: BorderRadius.circular(20.0),
                            child: AnimatedContainer(
                              duration: AppMotion.resolveDuration(
                                AppMotion.durationShort,
                                context: context,
                              ),
                              curve: AppMotion.curveDecelerate,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.accent
                                    : colors.surface1,
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.accent
                                      : colors.surface2.withValues(alpha: 0.8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  item.label,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isSelected
                                        ? Colors.black
                                        : colors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }(),
                    ],
                  ],
                ),
              ),
            ),

            AppSpacing.vGap16,

            // Category Content Area
            AudifiContentSwitcher(
              child: switch (_activeCategory) {
                LibraryCategory.all => _buildAllOverview(
                  context,
                  colors,
                  library,
                  downloads,
                  localTracks,
                  history,
                ),
                LibraryCategory.tracks => _buildLikedTab(
                  context,
                  colors,
                  library,
                ),
                LibraryCategory.playlists => _buildPlaylistsTab(
                  context,
                  colors,
                  library,
                ),
                LibraryCategory.downloaded => _buildDownloadedTab(
                  context,
                  colors,
                ),
                LibraryCategory.localFiles => _buildLocalFilesTab(
                  context,
                  colors,
                ),
                LibraryCategory.artists => _buildArtistsTab(
                  context,
                  colors,
                  library,
                ),
                LibraryCategory.history => _buildHistoryTab(
                  context,
                  colors,
                  history,
                ),
              },
            ),

            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  /// Unified "All" Category Overview displaying collection summary cards
  /// and fast navigation into each specific collection.
  Widget _buildAllOverview(
    BuildContext context,
    AudifiThemeColors colors,
    dynamic library,
    List<DownloadedTrack> downloads,
    List<LocalAudioTrack> localTracks,
    List<Track> history,
  ) {
    // Combined list of all saved tracks across liked, downloaded, and local
    final allTracksMap = <String, Track>{};
    for (final t in library.likedTracks as List<Track>) {
      allTracksMap[t.id] = t;
    }
    for (final dt in downloads) {
      allTracksMap[dt.track.id] = dt.track;
    }
    for (final lt in localTracks) {
      allTracksMap[lt.track.id] = lt.track;
    }
    final allTracks = allTracksMap.values.toList();

    return Padding(
      key: const ValueKey('library_all_overview'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // If user has any saved music, offer Shuffle / Play All across entire collection
          if (allTracks.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: AudifiButton(
                    text: 'Shuffle All',
                    icon: const Icon(Icons.shuffle_rounded),
                    variant: AudifiButtonVariant.secondary,
                    onPressed: () {
                      final shuffled = List<Track>.from(allTracks)..shuffle();
                      ref
                          .read(playbackControllerProvider.notifier)
                          .playTrack(shuffled.first, contextTracks: shuffled);
                    },
                  ),
                ),
                AppSpacing.hGap12,
                Expanded(
                  child: AudifiButton(
                    text: 'Play All',
                    icon: const Icon(Icons.play_arrow_rounded),
                    variant: AudifiButtonVariant.primary,
                    onPressed: () {
                      ref
                          .read(playbackControllerProvider.notifier)
                          .playTrack(allTracks.first, contextTracks: allTracks);
                    },
                  ),
                ),
              ],
            ),
            AppSpacing.vGap16,
          ],

          // Collection Cards Grid
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: [
              // 1. Liked Songs Card
              _buildCollectionTile(
                colors: colors,
                title: 'Liked Songs',
                subtitle:
                    '${library.likedTracks.length} ${library.likedTracks.length == 1 ? "track" : "tracks"}',
                icon: Icons.favorite_rounded,
                iconColor: colors.accent,
                onTap: () =>
                    setState(() => _activeCategory = LibraryCategory.tracks),
              ),

              // 2. Downloads Card
              _buildCollectionTile(
                colors: colors,
                title: 'Downloads',
                subtitle:
                    '${downloads.length} ${downloads.length == 1 ? "track" : "tracks"} offline',
                icon: Icons.download_done_rounded,
                iconColor: colors.accent,
                onTap: () => setState(
                  () => _activeCategory = LibraryCategory.downloaded,
                ),
              ),

              // 3. Local Files Card
              _buildCollectionTile(
                colors: colors,
                title: 'Local Files',
                subtitle:
                    '${localTracks.length} ${localTracks.length == 1 ? "file" : "files"} on device',
                icon: Icons.folder_rounded,
                iconColor: colors.accent,
                onTap: () => setState(
                  () => _activeCategory = LibraryCategory.localFiles,
                ),
              ),

              // 4. Custom Playlists Card
              _buildCollectionTile(
                colors: colors,
                title: 'Playlists',
                subtitle:
                    '${ref.watch(customPlaylistsProvider).length} playlists',
                icon: Icons.queue_music_rounded,
                iconColor: colors.accent,
                onTap: () =>
                    setState(() => _activeCategory = LibraryCategory.playlists),
              ),

              // 5. Artists Card
              _buildCollectionTile(
                colors: colors,
                title: 'Followed Artists',
                subtitle: '${library.followedArtists.length} followed',
                icon: Icons.person_rounded,
                iconColor: colors.accent,
                onTap: () =>
                    setState(() => _activeCategory = LibraryCategory.artists),
              ),

              // 6. History Card
              _buildCollectionTile(
                colors: colors,
                title: 'Listening History',
                subtitle: '${history.length} played recently',
                icon: Icons.history_rounded,
                iconColor: colors.accent,
                onTap: () =>
                    setState(() => _activeCategory = LibraryCategory.history),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTile({
    required AudifiThemeColors colors,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52.0) / 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colors.surface1,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: colors.surface2.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22.0),
              ),
              AppSpacing.vGap12,
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.vGap4,
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.micro.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Liked Songs Collection Tab
  Widget _buildLikedTab(
    BuildContext context,
    AudifiThemeColors colors,
    dynamic library,
  ) {
    final List<Track> rawTracks = library.likedTracks;

    if (rawTracks.isEmpty) {
      return Padding(
        key: const ValueKey('library_tracks_empty'),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: AudifiCard(
          padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 48.0,
                color: colors.textMuted,
              ),
              AppSpacing.vGap12,
              Text(
                'Your favorite tracks will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16.0),
              AudifiButton(
                text: 'Discover music',
                variant: AudifiButtonVariant.primary,
                onPressed: () => context.go(RoutePaths.discover),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _searchQuery.isEmpty
        ? rawTracks
        : rawTracks.where((t) {
            final titleMatch = t.title.toLowerCase().contains(_searchQuery);
            final artistMatch =
                t.user?.name.toLowerCase().contains(_searchQuery) ?? false;
            return titleMatch || artistMatch;
          }).toList();

    if (filtered.isEmpty) {
      return _buildSearchNoResults(colors);
    }

    final sortedTracks = _applySorting(filtered);

    return Padding(
      key: const ValueKey('library_tracks_populated'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sortedTracks.length} ${sortedTracks.length == 1 ? "track" : "tracks"}',
                style: AppTypography.caption.copyWith(color: colors.textMuted),
              ),
              _buildSortDropdown(colors),
            ],
          ),
          AppSpacing.vGap12,
          _buildActionControlsRow(sortedTracks),
          AppSpacing.vGap16,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedTracks.length,
            separatorBuilder: (context, index) => Divider(
              color: colors.surface2.withValues(alpha: 0.5),
              height: 1.0,
            ),
            itemBuilder: (context, index) {
              final track = sortedTracks[index];
              return AudifiTrackTile(
                track: track,
                onTap: () {
                  ref
                      .read(playbackControllerProvider.notifier)
                      .playTrack(track, contextTracks: sortedTracks);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Local Files Tab
  Widget _buildLocalFilesTab(BuildContext context, AudifiThemeColors colors) {
    final localTracks = ref.watch(localFilesControllerProvider);

    return Padding(
      key: const ValueKey('library_local_files_tab'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final storageAsync = ref.watch(
                    localFilesStorageBytesProvider,
                  );
                  return storageAsync.maybeWhen(
                    data: (bytes) {
                      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
                      return Text(
                        '${localTracks.length} files ($mb MB)',
                        style: AppTypography.caption.copyWith(
                          color: colors.textMuted,
                        ),
                      );
                    },
                    orElse: () => Text(
                      '${localTracks.length} files',
                      style: AppTypography.caption.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18.0),
                label: const Text('Import Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.surface1,
                  foregroundColor: colors.accent,
                  elevation: 0,
                  side: BorderSide(
                    color: colors.surface2.withValues(alpha: 0.8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                onPressed: () async {
                  final count = await ref
                      .read(localFilesControllerProvider.notifier)
                      .pickAndImportAudioFiles();
                  if (context.mounted && count > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Imported $count ${count == 1 ? "track" : "tracks"} into Audifi',
                        ),
                        backgroundColor: colors.surface2,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          AppSpacing.vGap12,
          if (localTracks.isEmpty) ...[
            AudifiCard(
              padding: const EdgeInsets.symmetric(
                vertical: 36.0,
                horizontal: 20.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.audio_file_rounded,
                    size: 48.0,
                    color: colors.textMuted,
                  ),
                  AppSpacing.vGap12,
                  Text(
                    'No local files imported yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  AppSpacing.vGap6,
                  Text(
                    'Import MP3, FLAC, M4A, or WAV tracks from your device to play offline.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  AudifiButton(
                    text: 'Select Files to Import',
                    icon: const Icon(Icons.folder_open_rounded),
                    variant: AudifiButtonVariant.primary,
                    onPressed: () async {
                      await ref
                          .read(localFilesControllerProvider.notifier)
                          .pickAndImportAudioFiles();
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            Builder(
              builder: (context) {
                final filtered = _searchQuery.isEmpty
                    ? localTracks
                    : localTracks.where((lt) {
                        final titleMatch = lt.track.title
                            .toLowerCase()
                            .contains(_searchQuery);
                        final artistMatch =
                            lt.track.user?.name.toLowerCase().contains(
                              _searchQuery,
                            ) ??
                            false;
                        return titleMatch || artistMatch;
                      }).toList();

                if (filtered.isEmpty) {
                  return _buildSearchNoResults(colors);
                }

                final sortedTracks = _applySorting(
                  filtered.map((lt) => lt.track).toList(),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildActionControlsRow(sortedTracks),
                    AppSpacing.vGap16,
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedTracks.length,
                      separatorBuilder: (context, index) => Divider(
                        color: colors.surface2.withValues(alpha: 0.5),
                        height: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final track = sortedTracks[index];
                        final localItem = localTracks.firstWhere(
                          (lt) => lt.track.id == track.id,
                        );

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 48.0,
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: colors.surface2,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Icon(
                                Icons.music_note_rounded,
                                color: colors.accent,
                                size: 24.0,
                              ),
                            ),
                            title: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${track.user?.name ?? "Local Artist"} · ${localItem.fileExtension.toUpperCase()} · ${localItem.formattedSize}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.micro.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_vert_rounded),
                              color: colors.textMuted,
                              onPressed: () {
                                _showLocalTrackOptions(
                                  context,
                                  colors,
                                  localItem,
                                );
                              },
                            ),
                            onTap: () {
                              ref
                                  .read(playbackControllerProvider.notifier)
                                  .playTrack(
                                    track,
                                    contextTracks: sortedTracks,
                                  );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showLocalTrackOptions(
    BuildContext context,
    AudifiThemeColors colors,
    LocalAudioTrack localTrack,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: BoxDecoration(
                          color: colors.surface2,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          color: colors.accent,
                        ),
                      ),
                      AppSpacing.hGap12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localTrack.track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Device Storage (${localTrack.formattedSize})',
                              style: AppTypography.caption.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24.0),
                ListTile(
                  leading: const Icon(Icons.playlist_add_rounded),
                  title: const Text('Add to Playlist'),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _showAddToPlaylistSheet(context, colors, localTrack.track);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Remove from Audifi',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  subtitle: const Text(
                    'Does not delete the original file on device',
                    style: TextStyle(fontSize: 12.0),
                  ),
                  onTap: () async {
                    Navigator.pop(modalContext);
                    await ref
                        .read(localFilesControllerProvider.notifier)
                        .removeTrack(localTrack.track.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddToPlaylistSheet(
    BuildContext context,
    AudifiThemeColors colors,
    Track track,
  ) {
    final playlists = ref.read(customPlaylistsProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Add to Playlist',
                    style: AppTypography.h3.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppSpacing.vGap12,
                if (playlists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No custom playlists found. Create one first!',
                      style: TextStyle(color: colors.textMuted),
                    ),
                  )
                else
                  ...playlists.map((playlist) {
                    return ListTile(
                      leading: const Icon(Icons.queue_music_rounded),
                      title: Text(playlist.playlistName),
                      subtitle: Text('${playlist.trackCount} tracks'),
                      onTap: () async {
                        Navigator.pop(modalContext);
                        final added = await ref
                            .read(customPlaylistsProvider.notifier)
                            .addTrackToPlaylist(playlist.id, track);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? 'Added to "${playlist.playlistName}"'
                                    : 'Track is already in "${playlist.playlistName}"',
                              ),
                              backgroundColor: colors.surface2,
                            ),
                          );
                        }
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Playlists Collection Tab
  Widget _buildPlaylistsTab(
    BuildContext context,
    AudifiThemeColors colors,
    dynamic library,
  ) {
    final customPlaylists = ref.watch(customPlaylistsProvider);
    final savedPlaylists = library.savedPlaylists;

    return Padding(
      key: const ValueKey('library_playlists_tab'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${customPlaylists.length + savedPlaylists.length} playlists',
                  style: AppTypography.caption.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18.0),
                label: const Text('Create Playlist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.surface1,
                  foregroundColor: colors.accent,
                  elevation: 0,
                  side: BorderSide(
                    color: colors.surface2.withValues(alpha: 0.8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                onPressed: () => CreatePlaylistDialog.show(context),
              ),
            ],
          ),
          AppSpacing.vGap16,
          if (customPlaylists.isEmpty && savedPlaylists.isEmpty) ...[
            AudifiCard(
              key: const ValueKey('library_playlists_empty'),
              padding: const EdgeInsets.symmetric(
                vertical: 36.0,
                horizontal: 20.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: 48.0,
                    color: colors.textMuted,
                  ),
                  AppSpacing.vGap12,
                  Text(
                    'No playlists yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  AppSpacing.vGap6,
                  Text(
                    'Create custom playlists or save public playlists from Discover.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...customPlaylists.map((playlist) {
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: colors.accent,
                    ),
                  ),
                  title: Text(
                    playlist.playlistName,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Custom Playlist · ${playlist.trackCount} tracks',
                    style: AppTypography.micro.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: colors.textMuted,
                    onPressed: () async {
                      await ref
                          .read(customPlaylistsProvider.notifier)
                          .deletePlaylist(playlist.id);
                    },
                  ),
                  onTap: () {
                    context.push(RoutePaths.playlist(playlist.id));
                  },
                ),
              );
            }),
            ...savedPlaylists.map((playlist) {
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.playlist_play_rounded,
                      color: colors.accent,
                    ),
                  ),
                  title: Text(
                    playlist.playlistName,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Saved · ${playlist.trackCount} tracks',
                    style: AppTypography.micro.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  onTap: () {
                    context.push(RoutePaths.playlist(playlist.id));
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Downloaded Tracks Tab (App-private storage)
  Widget _buildDownloadedTab(BuildContext context, AudifiThemeColors colors) {
    final downloadedTracks = ref.watch(downloadedTracksProvider);
    final storageAsync = ref.watch(downloadStorageBytesProvider);

    return Padding(
      key: const ValueKey('library_downloaded_tab'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              storageAsync.maybeWhen(
                data: (bytes) {
                  final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
                  return Text(
                    '${downloadedTracks.length} offline ($mb MB)',
                    style: AppTypography.caption.copyWith(
                      color: colors.textMuted,
                    ),
                  );
                },
                orElse: () => Text(
                  '${downloadedTracks.length} offline',
                  style: AppTypography.caption.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
              if (downloadedTracks.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(downloadControllerProvider.notifier)
                        .clearAllDownloads();
                  },
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
          AppSpacing.vGap12,
          if (downloadedTracks.isEmpty) ...[
            AudifiCard(
              padding: const EdgeInsets.symmetric(
                vertical: 36.0,
                horizontal: 20.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_for_offline_rounded,
                    size: 48.0,
                    color: colors.textMuted,
                  ),
                  AppSpacing.vGap12,
                  Text(
                    'No downloaded tracks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  AppSpacing.vGap6,
                  Text(
                    'Tracks you download for offline listening will appear here.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Builder(
              builder: (context) {
                final filtered = _searchQuery.isEmpty
                    ? downloadedTracks
                    : downloadedTracks.where((dt) {
                        final titleMatch = dt.track.title
                            .toLowerCase()
                            .contains(_searchQuery);
                        final artistMatch =
                            dt.track.user?.name.toLowerCase().contains(
                              _searchQuery,
                            ) ??
                            false;
                        return titleMatch || artistMatch;
                      }).toList();

                if (filtered.isEmpty) {
                  return _buildSearchNoResults(colors);
                }

                final sortedTracks = _applySorting(
                  filtered.map((dt) => dt.track).toList(),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildActionControlsRow(sortedTracks),
                    AppSpacing.vGap16,
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedTracks.length,
                      separatorBuilder: (context, index) => Divider(
                        color: colors.surface2.withValues(alpha: 0.5),
                        height: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final track = sortedTracks[index];
                        return AudifiTrackTile(
                          track: track,
                          onTap: () {
                            ref
                                .read(playbackControllerProvider.notifier)
                                .playTrack(track, contextTracks: sortedTracks);
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Followed Artists Tab
  Widget _buildArtistsTab(
    BuildContext context,
    AudifiThemeColors colors,
    dynamic library,
  ) {
    final artists = library.followedArtists;

    if (artists.isEmpty) {
      return Padding(
        key: const ValueKey('library_artists_empty'),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: AudifiCard(
          padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 48.0,
                color: colors.textMuted,
              ),
              AppSpacing.vGap12,
              Text(
                'No followed artists yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              AppSpacing.vGap6,
              Text(
                'Follow artists from Discover or Search to keep up with their music.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      key: const ValueKey('library_artists_tab'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${artists.length} artists followed',
            style: AppTypography.caption.copyWith(color: colors.textMuted),
          ),
          AppSpacing.vGap16,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: artists.length,
            separatorBuilder: (context, index) => Divider(
              color: colors.surface2.withValues(alpha: 0.5),
              height: 1.0,
            ),
            itemBuilder: (context, index) {
              final artist = artists[index];
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_rounded, color: colors.accent),
                  ),
                  title: Text(
                    artist.name,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    artist.atHandle,
                    style: AppTypography.micro.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    context.push(RoutePaths.artist(artist.id));
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// History Tab
  Widget _buildHistoryTab(
    BuildContext context,
    AudifiThemeColors colors,
    List<Track> history,
  ) {
    if (history.isEmpty) {
      return Padding(
        key: const ValueKey('library_history_empty'),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: AudifiCard(
          padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 48.0, color: colors.textMuted),
              AppSpacing.vGap12,
              Text(
                'Listening history is empty.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              AppSpacing.vGap6,
              Text(
                'Tracks you listen to will be recorded here.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _searchQuery.isEmpty
        ? history
        : history.where((t) {
            final titleMatch = t.title.toLowerCase().contains(_searchQuery);
            final artistMatch =
                t.user?.name.toLowerCase().contains(_searchQuery) ?? false;
            return titleMatch || artistMatch;
          }).toList();

    return Padding(
      key: const ValueKey('library_history_tab'),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filtered.length} recently played',
                style: AppTypography.caption.copyWith(color: colors.textMuted),
              ),
              TextButton(
                onPressed: () {
                  ref.read(listeningHistoryProvider.notifier).clear();
                },
                child: Text(
                  'Clear history',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGap12,
          _buildActionControlsRow(filtered),
          AppSpacing.vGap16,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => Divider(
              color: colors.surface2.withValues(alpha: 0.5),
              height: 1.0,
            ),
            itemBuilder: (context, index) {
              final track = filtered[index];
              return AudifiTrackTile(
                track: track,
                onTap: () {
                  ref
                      .read(playbackControllerProvider.notifier)
                      .playTrack(track, contextTracks: filtered);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Responsive Shuffle & Play All Controls Row
  Widget _buildActionControlsRow(List<Track> contextTracks) {
    return Row(
      children: [
        Expanded(
          child: AudifiButton(
            text: 'Shuffle',
            icon: const Icon(Icons.shuffle_rounded),
            variant: AudifiButtonVariant.secondary,
            onPressed: () {
              final shuffled = List<Track>.from(contextTracks)..shuffle();
              ref
                  .read(playbackControllerProvider.notifier)
                  .playTrack(shuffled.first, contextTracks: shuffled);
            },
          ),
        ),
        AppSpacing.hGap12,
        Expanded(
          child: AudifiButton(
            text: 'Play All',
            icon: const Icon(Icons.play_arrow_rounded),
            variant: AudifiButtonVariant.primary,
            onPressed: () {
              ref
                  .read(playbackControllerProvider.notifier)
                  .playTrack(contextTracks.first, contextTracks: contextTracks);
            },
          ),
        ),
      ],
    );
  }

  /// Sort Dropdown Popup
  Widget _buildSortDropdown(AudifiThemeColors colors) {
    return PopupMenuButton<LibrarySort>(
      initialValue: _sortOrder,
      color: colors.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: colors.surface2.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 16.0, color: colors.accent),
            AppSpacing.hGap4,
            Text(
              switch (_sortOrder) {
                LibrarySort.recentlyAdded => 'Recently Added',
                LibrarySort.title => 'Title (A-Z)',
                LibrarySort.artist => 'Artist (A-Z)',
              },
              style: TextStyle(
                fontSize: 12.0,
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onSelected: (sort) {
        setState(() => _sortOrder = sort);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: LibrarySort.recentlyAdded,
          child: Text('Recently Added'),
        ),
        const PopupMenuItem(
          value: LibrarySort.title,
          child: Text('Title (A-Z)'),
        ),
        const PopupMenuItem(
          value: LibrarySort.artist,
          child: Text('Artist (A-Z)'),
        ),
      ],
    );
  }

  /// Search No Results View
  Widget _buildSearchNoResults(AudifiThemeColors colors) {
    return Padding(
      key: const ValueKey('library_search_empty'),
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48.0, color: colors.textMuted),
            AppSpacing.vGap12,
            Text(
              'No matches for "$_searchQuery"',
              style: AppTypography.body.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.vGap6,
            Text(
              'Try searching with another title or artist keyword.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: colors.textMuted),
            ),
            AppSpacing.vGap16,
            AudifiButton(
              text: 'Clear search',
              variant: AudifiButtonVariant.secondary,
              onPressed: _onSearchClear,
            ),
          ],
        ),
      ),
    );
  }
}
