import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/downloads/presentation/controllers/download_controller.dart';
import '../../../features/tracks/domain/entities/track.dart';

/// Permission-aware download action tile within [AudifiTrackOptionsSheet].
class TrackOptionsDownloadTile extends ConsumerWidget {
  const TrackOptionsDownloadTile({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final isDownloaded = ref.watch(isTrackDownloadedProvider(track.id));
    final progress = ref.watch(downloadProgressProvider(track.id));
    final permissionAsync = ref.watch(trackDownloadPermissionProvider(track));

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
          ref.read(downloadControllerProvider.notifier).removeDownload(track.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${track.title}" from downloads'),
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
            ref.read(downloadControllerProvider.notifier).cancelDownload(track.id);
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
              ref.read(downloadControllerProvider.notifier).downloadTrack(track);
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
        onTap: () => ref.refresh(trackDownloadPermissionProvider(track)),
      ),
    );
  }
}
