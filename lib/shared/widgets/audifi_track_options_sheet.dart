import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/downloads/presentation/controllers/download_controller.dart';
import '../../features/playback/presentation/controllers/queue_controller.dart';
import '../../features/playlists/presentation/controllers/custom_playlists_controller.dart';
import '../../features/playlists/presentation/widgets/create_playlist_dialog.dart';
import '../../features/tracks/domain/entities/track.dart';
import 'audifi_network_image.dart';

/// Modal bottom sheet presenting quick options for a [Track].
class AudifiTrackOptionsSheet extends ConsumerWidget {
  const AudifiTrackOptionsSheet({
    super.key,
    required this.track,
    this.onRemoveFromPlaylist,
  });

  /// The target track.
  final Track track;

  /// Optional callback to remove track from a specific playlist.
  final VoidCallback? onRemoveFromPlaylist;

  /// Helper to display the options sheet modally.
  static Future<void> show(
    BuildContext context,
    Track track, {
    VoidCallback? onRemoveFromPlaylist,
  }) {
    return AppMotion.showModalSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AudifiTrackOptionsSheet(
        track: track,
        onRemoveFromPlaylist: onRemoveFromPlaylist,
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final playlists = ref.read(customPlaylistsProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
                child: Text(
                  'Add to Playlist',
                  style: AppTypography.h2.copyWith(color: colors.textPrimary),
                ),
              ),
              ListTile(
                leading: Icon(Icons.add_rounded, color: colors.accent),
                title: Text(
                  'New Playlist',
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final created = await CreatePlaylistDialog.show(
                    context,
                    initialTrack: track,
                  );
                  if (created != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to "${created.playlistName}"'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              if (playlists.isNotEmpty) const Divider(height: 1.0),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: Icon(
                        Icons.queue_music_rounded,
                        color: colors.textMuted,
                      ),
                      title: Text(
                        playlist.playlistName,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      subtitle: Text(
                        '${playlist.trackCount} tracks',
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        final added = await ref
                            .read(customPlaylistsProvider.notifier)
                            .addTrackToPlaylist(playlist.id, track);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? 'Added to "${playlist.playlistName}"'
                                    : 'Already in "${playlist.playlistName}"',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;

    return Material(
      color: colors.surface1,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            // Track Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
              child: Row(
                children: [
                  AudifiNetworkImage(
                    imageUrl: track.artwork?.small ?? track.artwork?.primaryUrl,
                    width: 48.0,
                    height: 48.0,
                    borderRadius: 8.0,
                    fallbackIcon: Icons.music_note_rounded,
                  ),
                  AppSpacing.hGap12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.vGap2,
                        Text(
                          track.user?.name ?? 'Unknown Artist',
                          style: AppTypography.caption.copyWith(
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1.0),

            // Options list
            ListTile(
              leading: Icon(
                Icons.playlist_play_rounded,
                color: colors.textPrimary,
              ),
              title: Text(
                'Play Next',
                style: TextStyle(color: colors.textPrimary),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(queueControllerProvider.notifier).playNext(track);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playing next: "${track.title}"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.queue_music_rounded,
                color: colors.textPrimary,
              ),
              title: Text(
                'Add to Queue',
                style: TextStyle(color: colors.textPrimary),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(queueControllerProvider.notifier).addToQueue(track);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to queue'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.playlist_add_rounded,
                color: colors.textPrimary,
              ),
              title: Text(
                'Add to Playlist',
                style: TextStyle(color: colors.textPrimary),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showAddToPlaylist(context, ref);
              },
            ),
            // Download / Offline Option
            Consumer(
              builder: (context, ref, _) {
                final isDownloaded = ref.watch(
                  isTrackDownloadedProvider(track.id),
                );
                final progress = ref.watch(downloadProgressProvider(track.id));

                final permissionAsync = ref.watch(
                  trackDownloadPermissionProvider(track),
                );

                if (isDownloaded) {
                  return ListTile(
                    leading: Icon(
                      Icons.download_done_rounded,
                      color: colors.accent,
                    ),
                    title: const Text('Remove Download'),
                    subtitle: Text(
                      'Downloaded for offline playback',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      ref
                          .read(downloadControllerProvider.notifier)
                          .removeDownload(track.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Removed "${track.title}" from downloads',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                }

                if (progress != null && progress.isDownloading) {
                  return ListTile(
                    leading: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: progress.progress > 0 ? progress.progress : null,
                        strokeWidth: 2.5,
                        color: colors.accent,
                      ),
                    ),
                    title: Text(
                      'Downloading (${(progress.progress * 100).toInt()}%)...',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        ref
                            .read(downloadControllerProvider.notifier)
                            .cancelDownload(track.id);
                      },
                    ),
                  );
                }

                return permissionAsync.when(
                  data: (perm) {
                    if (perm.isAuthorized) {
                      return ListTile(
                        leading: Icon(
                          Icons.download_rounded,
                          color: colors.textPrimary,
                        ),
                        title: Text(
                          'Download',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                        subtitle: Text(
                          'Listen offline without internet',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          ref
                              .read(downloadControllerProvider.notifier)
                              .downloadTrack(track);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading "${track.title}"...'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    }
                    if (perm.isGated) {
                      return ListTile(
                        enabled: false,
                        leading: Icon(
                          Icons.lock_outline_rounded,
                          color: colors.textMuted,
                        ),
                        title: Text(
                          'Download Gated',
                          style: TextStyle(color: colors.textMuted),
                        ),
                        subtitle: Text(
                          'This download requires creator access.',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return ListTile(
                      enabled: false,
                      leading: Icon(
                        Icons.file_download_off_rounded,
                        color: colors.textMuted,
                      ),
                      title: Text(
                        'Download Unavailable',
                        style: TextStyle(color: colors.textMuted),
                      ),
                      subtitle: Text(
                        "Downloads aren't available for this track.",
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    );
                  },
                  loading: () => ListTile(
                    enabled: false,
                    leading: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: colors.textMuted,
                      ),
                    ),
                    title: Text(
                      'Checking Permissions…',
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                  error: (_, _) => ListTile(
                    leading: Icon(
                      Icons.refresh_rounded,
                      color: colors.textMuted,
                    ),
                    title: Text(
                      'Retry Permission Check',
                      style: TextStyle(color: colors.textMuted),
                    ),
                    onTap: () =>
                        ref.refresh(trackDownloadPermissionProvider(track)),
                  ),
                );
              },
            ),
            if (track.user != null)
              ListTile(
                leading: Icon(Icons.person_rounded, color: colors.textPrimary),
                title: Text(
                  'Go to Artist',
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(RoutePaths.artist(track.user!.id));
                },
              ),
            if (onRemoveFromPlaylist != null)
              ListTile(
                leading: Icon(
                  Icons.remove_circle_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Remove from this Playlist',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onRemoveFromPlaylist!();
                },
              ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }
}
