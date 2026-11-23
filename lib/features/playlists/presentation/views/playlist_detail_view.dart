import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_app_bar.dart';
import '../../../../shared/widgets/audifi_button.dart';
import '../../../../shared/widgets/audifi_content_switcher.dart';
import '../../../../shared/widgets/audifi_error_view.dart';
import '../../../../shared/widgets/audifi_favorite_button.dart';
import '../../../../shared/widgets/audifi_loading_indicator.dart';
import '../../../../shared/widgets/audifi_network_image.dart';
import '../../../../shared/widgets/audifi_page_container.dart';
import '../../../../shared/widgets/audifi_section_header.dart';
import '../../../../shared/widgets/audifi_track_options_sheet.dart';
import '../../../../shared/widgets/audifi_track_tile.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../playback/presentation/controllers/playback_controller.dart';
import '../../domain/entities/playlist.dart';
import '../controllers/custom_playlists_controller.dart';
import '../controllers/playlist_detail_controller.dart';

/// Detailed view showing playlist header, curator details, and track listings.
class PlaylistDetailView extends ConsumerWidget {
  const PlaylistDetailView({super.key, required this.playlistId});

  /// The unique Audius playlist ID or custom playlist ID.
  final String playlistId;

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    final colors = context.audifiColors;
    final controller = TextEditingController(text: playlist.playlistName);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Rename Playlist',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Playlist Name',
              labelStyle: TextStyle(color: colors.textMuted),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.surface2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: colors.accent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            ),
            AudifiButton(
              text: 'Save',
              variant: AudifiButtonVariant.primary,
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  ref
                      .read(customPlaylistsProvider.notifier)
                      .renamePlaylist(playlist.id, newName);
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    final colors = context.audifiColors;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Delete Playlist?',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete "${playlist.playlistName}"? This action cannot be undone.',
            style: TextStyle(color: colors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(customPlaylistsProvider.notifier)
                    .deletePlaylist(playlist.id);
                if (context.mounted) {
                  Navigator.of(context).maybePop();
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));
    final isCustom = ref
        .watch(customPlaylistsProvider)
        .any((p) => p.id == playlistId);

    return Scaffold(
      appBar: AudifiAppBar(
        title: isCustom ? 'Custom Playlist' : 'Playlist',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (isCustom && playlistAsync.value != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: colors.textPrimary),
              color: colors.surface1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              onSelected: (value) {
                final playlist = playlistAsync.value!.playlist;
                if (value == 'rename') {
                  _showRenameDialog(context, ref, playlist);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, ref, playlist);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                      AppSpacing.hGap12,
                      Text(
                        'Rename',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      AppSpacing.hGap12,
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: AudifiContentSwitcher(
        layoutBuilder: AnimatedSwitcher.defaultLayoutBuilder,
        child: playlistAsync.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(
            key: ValueKey('playlist_detail_loading'),
            child: AudifiLoadingIndicator(size: 36.0),
          ),
          error: (error, stack) => Center(
            key: const ValueKey('playlist_detail_error'),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AudifiErrorView(
                message: error.toString(),
                title: 'Playlist Unavailable',
                onRetry: () => ref.refresh(playlistDetailProvider(playlistId)),
              ),
            ),
          ),
          data: (detailState) {
            final playlist = detailState.playlist;
            final tracks = detailState.tracks;

            return AudifiPageContainer(
              key: const ValueKey('playlist_detail_data'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Playlist Header
                  Center(
                    child: Column(
                      children: [
                        AudifiNetworkImage(
                          imageUrl: playlist.artwork?.primaryUrl,
                          width: 140.0,
                          height: 140.0,
                          borderRadius: 12.0,
                          fallbackIcon: Icons.queue_music_rounded,
                        ),
                        AppSpacing.vGap16,
                        Text(
                          playlist.playlistName,
                          style: AppTypography.h1.copyWith(
                            color: colors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.vGap6,
                        if (isCustom)
                          Text(
                            'By You',
                            style: AppTypography.body.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (playlist.user != null)
                          GestureDetector(
                            onTap: () {
                              context.push(
                                RoutePaths.artist(playlist.user!.id),
                              );
                            },
                            child: Text(
                              'By ${playlist.user!.name}',
                              style: AppTypography.body.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        AppSpacing.vGap8,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${tracks.length} ${tracks.length == 1 ? "track" : "tracks"}',
                              style: AppTypography.caption.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                            if (!isCustom && playlist.totalPlayCount > 0)
                              Text(
                                ' · ${playlist.formattedPlayCount}',
                                style: AppTypography.caption.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                          ],
                        ),
                        if (playlist.description != null &&
                            playlist.description!.isNotEmpty) ...[
                          AppSpacing.vGap10,
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Text(
                              playlist.description!,
                              style: AppTypography.caption.copyWith(
                                color: colors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        AppSpacing.vGap16,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (tracks.isNotEmpty) ...[
                              AudifiButton(
                                text: 'Play All',
                                icon: const Icon(Icons.play_arrow_rounded),
                                onPressed: () {
                                  ref
                                      .read(playbackControllerProvider.notifier)
                                      .playTrack(
                                        tracks.first,
                                        contextTracks: tracks,
                                      );
                                },
                              ),
                              AppSpacing.hGap8,
                            ],
                            if (isCustom) ...[
                              AudifiButton(
                                text: 'Rename',
                                icon: const Icon(Icons.edit_rounded),
                                variant: AudifiButtonVariant.secondary,
                                onPressed: () =>
                                    _showRenameDialog(context, ref, playlist),
                              ),
                            ] else
                              Builder(
                                builder: (context) {
                                  final isSaved = ref
                                      .watch(libraryControllerProvider)
                                      .isPlaylistSaved(playlist.id);
                                  return AudifiButton(
                                    text: isSaved ? 'Saved' : 'Save',
                                    icon: Icon(
                                      isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                    ),
                                    variant: isSaved
                                        ? AudifiButtonVariant.inverted
                                        : AudifiButtonVariant.secondary,
                                    onPressed: () {
                                      ref
                                          .read(
                                            libraryControllerProvider.notifier,
                                          )
                                          .toggleSavePlaylist(playlist);
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.vGap24,

                  // Track Listing
                  const AudifiSectionHeader(title: 'Tracks'),
                  if (tracks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          isCustom
                              ? 'This playlist has no tracks yet.\nUse "..." on any track to add it here.'
                              : 'This playlist has no tracks.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    )
                  else if (isCustom)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: tracks.length,
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(customPlaylistsProvider.notifier)
                            .reorderTracks(playlist.id, oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return Container(
                          key: ValueKey('custom_${track.id}_$index'),
                          child: AudifiTrackTile(
                            track: track,
                            index: index + 1,
                            onTap: () {
                              ref
                                  .read(playbackControllerProvider.notifier)
                                  .playTrack(track, contextTracks: tracks);
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Consumer(
                                  builder: (context, ref, _) {
                                    final isLiked = ref
                                        .watch(libraryControllerProvider)
                                        .isTrackLiked(track.id);
                                    return AudifiFavoriteButton(
                                      isFavorite: isLiked,
                                      size: 20.0,
                                      onToggle: () {
                                        ref
                                            .read(
                                              libraryControllerProvider
                                                  .notifier,
                                            )
                                            .toggleLikeTrack(track);
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.more_horiz_rounded,
                                    color: colors.textMuted.withValues(
                                      alpha: 0.8,
                                    ),
                                    size: 22.0,
                                  ),
                                  tooltip: 'More options',
                                  constraints: const BoxConstraints(
                                    minWidth: 44.0,
                                    minHeight: 44.0,
                                  ),
                                  onPressed: () {
                                    AudifiTrackOptionsSheet.show(
                                      context,
                                      track,
                                      onRemoveFromPlaylist: () {
                                        ref
                                            .read(
                                              customPlaylistsProvider.notifier,
                                            )
                                            .removeTrackFromPlaylist(
                                              playlist.id,
                                              track.id,
                                            );
                                      },
                                    );
                                  },
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: SizedBox(
                                    width: 36.0,
                                    height: 48.0,
                                    child: Center(
                                      child: Icon(
                                        Icons.drag_handle_rounded,
                                        color: colors.textMuted.withValues(
                                          alpha: 0.6,
                                        ),
                                        size: 20.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tracks.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: colors.surface2, height: 1.0),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return AudifiTrackTile(
                          track: track,
                          index: index + 1,
                          onTap: () {
                            ref
                                .read(playbackControllerProvider.notifier)
                                .playTrack(track, contextTracks: tracks);
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
