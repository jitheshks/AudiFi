import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tracks/domain/entities/track.dart';
import '../controllers/download_controller.dart';

/// Reusable icon button displaying active download state and handling
/// user actions (download, cancel, retry, remove).
class DownloadButton extends ConsumerWidget {
  const DownloadButton({
    required this.track,
    super.key,
    this.size = 24.0,
    this.color,
  });

  final Track track;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final isDownloaded = ref.watch(isTrackDownloadedProvider(track.id));
    final progress = ref.watch(downloadProgressProvider(track.id));

    if (isDownloaded) {
      return IconButton(
        iconSize: size,
        icon: Icon(Icons.download_done_rounded, color: color ?? colors.accent),
        tooltip: 'Downloaded. Tap to remove',
        onPressed: () => _confirmRemove(context, ref),
      );
    }

    if (progress != null && progress.isDownloading) {
      return SizedBox(
        width: size + 16,
        height: size + 16,
        child: IconButton(
          iconSize: size,
          icon: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.progress > 0 ? progress.progress : null,
                strokeWidth: 2.5,
                color: colors.accent,
                backgroundColor: colors.surface2,
              ),
              Icon(
                Icons.close_rounded,
                size: size * 0.6,
                color: colors.textMuted,
              ),
            ],
          ),
          tooltip:
              'Downloading ${(progress.progress * 100).toInt()}%. Tap to cancel',
          onPressed: () {
            ref
                .read(downloadControllerProvider.notifier)
                .cancelDownload(track.id);
          },
        ),
      );
    }

    if (progress != null && progress.isQueued) {
      return IconButton(
        iconSize: size,
        icon: Icon(Icons.hourglass_top_rounded, color: colors.textMuted),
        tooltip: 'Queued for download. Tap to cancel',
        onPressed: () {
          ref
              .read(downloadControllerProvider.notifier)
              .cancelDownload(track.id);
        },
      );
    }

    if (progress != null && progress.isFailed) {
      return IconButton(
        iconSize: size,
        icon: Icon(Icons.refresh_rounded, color: const Color(0xFFEF4444)),
        tooltip: 'Download failed. Tap to retry',
        onPressed: () {
          ref.read(downloadControllerProvider.notifier).retryDownload(track);
        },
      );
    }

    final permissionAsync = ref.watch(trackDownloadPermissionProvider(track));

    return permissionAsync.when(
      data: (perm) {
        if (perm.isAuthorized) {
          return IconButton(
            iconSize: size,
            icon: Icon(
              Icons.download_rounded,
              color: color ?? colors.textMuted,
            ),
            tooltip: 'Download for offline playback',
            onPressed: () {
              ref
                  .read(downloadControllerProvider.notifier)
                  .downloadTrack(track);
            },
          );
        }
        if (perm.isGated) {
          return IconButton(
            iconSize: size,
            icon: Icon(
              Icons.lock_outline_rounded,
              color: colors.textMuted.withValues(alpha: 0.5),
            ),
            tooltip: 'This download requires creator access.',
            onPressed: null,
          );
        }
        if (perm.isError) {
          return IconButton(
            iconSize: size,
            icon: Icon(Icons.refresh_rounded, color: colors.textMuted),
            tooltip: 'Retry checking download permissions',
            onPressed: () =>
                ref.refresh(trackDownloadPermissionProvider(track)),
          );
        }
        return IconButton(
          iconSize: size,
          icon: Icon(
            Icons.file_download_off_rounded,
            color: colors.textMuted.withValues(alpha: 0.5),
          ),
          tooltip: "Downloads aren't available for this track.",
          onPressed: null,
        );
      },
      loading: () => SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: colors.textMuted,
          ),
        ),
      ),
      error: (_, _) => IconButton(
        iconSize: size,
        icon: Icon(Icons.refresh_rounded, color: colors.textMuted),
        tooltip: 'Retry checking download permissions',
        onPressed: () => ref.refresh(trackDownloadPermissionProvider(track)),
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface1,
        title: const Text('Remove Download'),
        content: Text('Remove "${track.title}" from downloaded music?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref
                  .read(downloadControllerProvider.notifier)
                  .removeDownload(track.id);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}
