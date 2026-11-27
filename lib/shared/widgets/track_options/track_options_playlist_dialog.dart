import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/playlists/presentation/controllers/custom_playlists_controller.dart';
import '../../../features/playlists/presentation/widgets/create_playlist_dialog.dart';
import '../../../features/tracks/domain/entities/track.dart';

/// Modal bottom sheet allowing the user to create or select a playlist for a [Track].
class TrackOptionsPlaylistDialog {
  const TrackOptionsPlaylistDialog._();

  static void show(BuildContext context, WidgetRef ref, Track track) {
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
}
