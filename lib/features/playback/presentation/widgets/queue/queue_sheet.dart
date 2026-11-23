import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../shared/widgets/audifi_empty_state.dart';
import '../../controllers/playback_controller.dart';
import '../../controllers/queue_controller.dart';
import 'queue_header.dart';
import 'queue_item_tile.dart';

/// Modal bottom sheet presenting the active playback queue, enabling
/// reordering, individual track removal, and queue clearing.
class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  /// Static helper to display the queue bottom sheet modally.
  static Future<void> show(BuildContext context) {
    return AppMotion.showModalSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final queue = ref.watch(queueControllerProvider);
    final currentTrack = queue.currentTrack;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border(top: BorderSide(color: colors.surface2, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QueueHeader(
              trackCount: queue.length,
              onClear: () {
                ref.read(queueControllerProvider.notifier).clearQueue();
              },
            ),
            const Divider(height: 1.0),
            Expanded(
              child: queue.isEmpty
                  ? const Center(
                      child: AudifiEmptyState(
                        title: 'Queue is Empty',
                        description: 'Tracks you play or add will appear here.',
                        icon: Icons.queue_music_rounded,
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: queue.items.length,
                      buildDefaultDragHandles: false,
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(queueControllerProvider.notifier)
                            .reorderQueue(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final track = queue.items[index];
                        final isCurrent = currentTrack?.id == track.id;

                        return QueueItemTile(
                          key: ValueKey('queue_${track.id}_$index'),
                          track: track,
                          index: index + 1,
                          isCurrent: isCurrent,
                          onTap: () {
                            ref
                                .read(playbackControllerProvider.notifier)
                                .playTrack(track);
                          },
                          onRemove: () {
                            ref
                                .read(queueControllerProvider.notifier)
                                .removeFromQueue(index);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
