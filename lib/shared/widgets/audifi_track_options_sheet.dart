import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../features/library/presentation/controllers/library_controller.dart';
import '../../features/playback/presentation/controllers/playback_controller.dart';
import '../../features/playback/presentation/controllers/queue_controller.dart';
import '../../features/playback/presentation/widgets/queue/queue_sheet.dart';
import '../../features/tracks/domain/entities/track.dart';
import 'track_options/track_options_download_tile.dart';
import 'track_options/track_options_header.dart';
import 'track_options/track_options_playlist_dialog.dart';

/// Modal bottom sheet presenting quick options and queue actions for a [Track].
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;

    // Determine if this track is currently active/playing
    final currentPlayingTrack = ref.watch(
      playbackControllerProvider.select((s) => s.currentTrack),
    );
    final isCurrentTrack =
        currentPlayingTrack != null && currentPlayingTrack.id == track.id;

    // Check liked/favorite state
    final isLiked = ref.watch(
      libraryControllerProvider.select((lib) => lib.isTrackLiked(track.id)),
    );

    return Material(
      color: colors.surface1,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Grab handle
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
              TrackOptionsHeader(track: track),
              const Divider(height: 1.0),

              // 1. Add/Remove from Liked Songs
              ListTile(
                leading: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isLiked ? colors.accent : colors.textPrimary,
                ),
                title: Text(
                  isLiked ? 'Remove from Liked Songs' : 'Save to Liked Songs',
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () {
                  ref.read(libraryControllerProvider.notifier).toggleLikeTrack(track);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isLiked
                            ? 'Removed from Liked Songs'
                            : 'Added to Liked Songs',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // 2. Add to Playlist
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
                  TrackOptionsPlaylistDialog.show(context, ref, track);
                },
              ),

              // 3. Play Next (Hidden if this is the currently playing track)
              if (!isCurrentTrack)
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

              // 4. Add to Queue (Always available, appends to queue end)
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

              // 5. Go to Queue
              ListTile(
                leading: Icon(
                  Icons.format_list_bulleted_rounded,
                  color: colors.textPrimary,
                ),
                title: Text(
                  'Go to Queue',
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  QueueSheet.show(context);
                },
              ),

              // 6. Go to Album (Only shown when valid parent album info exists)
              if (track.albumBacklink != null)
                ListTile(
                  leading: Icon(
                    Icons.album_rounded,
                    color: colors.textPrimary,
                  ),
                  title: const Text('Go to Album'),
                  subtitle: track.albumBacklink!.playlistName.isNotEmpty
                      ? Text(
                          track.albumBacklink!.playlistName,
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(
                      RoutePaths.playlist(track.albumBacklink!.playlistId.toString()),
                    );
                  },
                ),

              // 7. Go to Artist (Only shown when artist information exists)
              if (track.user != null && track.user!.id.isNotEmpty)
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

              // 8. Download / Offline status tile
              TrackOptionsDownloadTile(track: track),

              // 9. Remove from this Playlist (Only shown if opened in a playlist context)
              if (onRemoveFromPlaylist != null)
                ListTile(
                  leading: const Icon(
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
      ),
    ),
    );
  }
}
