import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../shared/widgets/audifi_card.dart';
import '../../../downloads/presentation/controllers/download_controller.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../library/presentation/controllers/listening_history_controller.dart';
import '../../../search/presentation/controllers/search_controller.dart';

/// Full-screen Music & Storage settings page adhering strictly to the Appearance reference design.
/// Provides library data management and offline storage controls with explicit confirmations.
class MusicView extends ConsumerWidget {
  const MusicView({super.key});

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    AppMotion.showAppDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared successfully')),
              );
            },
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8.0),

              // Back button "‹ Settings" matching Appearance reference
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    if (context.canPop()) context.pop();
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '‹ Settings',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ),
              ),

              // Heading: Music & Storage
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                child: Text(
                  'Music & Storage',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Section: LIBRARY MANAGEMENT
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Text(
                  'LIBRARY MANAGEMENT',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // Card 1: Library Management actions
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: Column(
                  children: [
                    // Clear favorites
                    InkWell(
                      onTap: () {
                        _confirmAction(
                          context,
                          title: 'Clear all favorites?',
                          message: 'This will remove all saved favorites from this device. Custom playlists remain untouched.',
                          confirmLabel: 'Clear Favorites',
                          onConfirm: () => ref
                              .read(libraryControllerProvider.notifier)
                              .clearLibrary(),
                        );
                      },
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16.0),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 66.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Clear favorites',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    'Remove all liked tracks from this device',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.delete_outline_rounded,
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.7),
                              size: 20.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      color: colors.surface2.withValues(alpha: 0.6),
                      height: 1.0,
                    ),
                    // Clear listening history
                    InkWell(
                      onTap: () {
                        _confirmAction(
                          context,
                          title: 'Clear listening history?',
                          message: 'This will clear all track history from this device.',
                          confirmLabel: 'Clear History',
                          onConfirm: () => ref
                              .read(listeningHistoryProvider.notifier)
                              .clearHistory(),
                        );
                      },
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 66.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Clear listening history',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    'Remove recently played tracks from this device',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.history_rounded,
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.7),
                              size: 20.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      color: colors.surface2.withValues(alpha: 0.6),
                      height: 1.0,
                    ),
                    // Clear search history
                    InkWell(
                      onTap: () {
                        _confirmAction(
                          context,
                          title: 'Clear search history?',
                          message: 'This will remove recent search suggestions from this device.',
                          confirmLabel: 'Clear Search History',
                          onConfirm: () => ref
                              .read(searchControllerProvider.notifier)
                              .clearRecentSearches(),
                        );
                      },
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16.0),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 66.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Clear search history',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    'Remove recent searches from this device',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.search_off_rounded,
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.7),
                              size: 20.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Section: DOWNLOADS & STORAGE
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  'DOWNLOADS & STORAGE',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // Card 2: Downloads storage management
              Consumer(
                builder: (context, ref, _) {
                  final storageSize =
                      ref.watch(downloadStorageSizeProvider).value ?? '0 B';
                  final downloadedTracks = ref.watch(downloadedTracksProvider);

                  return AudifiCard(
                    padding: EdgeInsets.zero,
                    hasShadow: false,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            _confirmAction(
                              context,
                              title: 'Clear all downloaded music?',
                              message:
                                  'This will delete all offline downloaded audio files ($storageSize · ${downloadedTracks.length} tracks) from this device. Local files are never deleted.',
                              confirmLabel: 'Delete Downloads',
                              onConfirm: () => ref
                                  .read(downloadControllerProvider.notifier)
                                  .clearAllDownloads(),
                            );
                          },
                          borderRadius: BorderRadius.circular(16.0),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 66.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 14.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Clear downloaded music',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                      const SizedBox(height: 3.0),
                                      Text(
                                        'Free up device storage ($storageSize · ${downloadedTracks.length} tracks)',
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.delete_sweep_rounded,
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.7),
                                  size: 22.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
