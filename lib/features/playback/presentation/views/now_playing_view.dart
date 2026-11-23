import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/audifi_empty_state.dart';
import '../controllers/artwork_palette_controller.dart';
import '../controllers/playback_controller.dart';
import '../widgets/now_playing/ambient_gradient_background.dart';
import '../widgets/now_playing/audio_info_sheet.dart';
import '../widgets/now_playing/now_playing_app_bar.dart';
import '../widgets/now_playing/now_playing_artwork.dart';
import '../widgets/now_playing/now_playing_controls.dart';
import '../widgets/now_playing/now_playing_progress.dart';
import '../widgets/now_playing/now_playing_track_info.dart';
import '../widgets/queue/queue_sheet.dart';

/// Full-screen expanded Now Playing view matching `.np` in `references/UI/audifi.html`.
class NowPlayingView extends ConsumerWidget {
  const NowPlayingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final isOled = ref.watch(oledModeProvider);
    final isAppReduced = ref.watch(isReducedMotionProvider);
    final isReducedMotion = AppMotion.isReducedMotion(
      isReduced: isAppReduced,
      context: context,
    );
    final paletteState = ref.watch(artworkPaletteProvider);
    final playbackState = ref.watch(playbackControllerProvider);
    final track = playbackState.currentTrack;

    if (track == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Minimize now playing screen',
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: AudifiEmptyState(
            title: 'No Active Track',
            description: 'Select a track to start listening.',
            icon: Icons.music_off_rounded,
            actionText: 'Browse Music',
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isOled ? Colors.black : colors.background,
      body: AmbientGradientBackground(
        palette: paletteState.palette,
        isOled: isOled,
        isReducedMotion: isReducedMotion,
        child: SafeArea(
          child: Column(
            children: [
              NowPlayingAppBar(
                onMoreTap: () => AudioInfoSheet.show(context, track: track),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460.0),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSpacing.vGap8,
                          NowPlayingArtwork(
                            imageUrl: track.artwork?.primaryUrl,
                            trackTitle: track.title,
                          ),
                          AppSpacing.vGap20,
                          NowPlayingTrackInfo(
                            track: track,
                            isBuffering: playbackState.isBuffering,
                          ),
                          if (playbackState.error != null) ...[
                            AppSpacing.vGap12,
                            Semantics(
                              container: true,
                              liveRegion: true,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 10.0,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? colors.error.withValues(alpha: 0.18)
                                      : const Color(0xFFFFECEB),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: colors.error.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ExcludeSemantics(
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? colors.error
                                            : const Color(0xFFC00010),
                                        size: 20.0,
                                      ),
                                    ),
                                    AppSpacing.hGap8,
                                    Expanded(
                                      child: Text(
                                        playbackState.error!.message,
                                        style: AppTypography.caption.copyWith(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? colors.textPrimary
                                              : const Color(0xFF90000A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 48.0,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(60, 48),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                        ),
                                        onPressed: () => ref
                                            .read(
                                              playbackControllerProvider
                                                  .notifier,
                                            )
                                            .playTrack(track),
                                        child: Text(
                                          'Retry',
                                          style: AppTypography.caption.copyWith(
                                            color: context.audifiColors.accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          AppSpacing.vGap16,
                          NowPlayingProgress(
                            position: playbackState.position,
                            duration: playbackState.duration,
                            formattedPosition: playbackState.formattedPosition,
                            formattedRemaining:
                                playbackState.formattedRemaining,
                            onSeek: (pos) => ref
                                .read(playbackControllerProvider.notifier)
                                .seek(pos),
                          ),
                          AppSpacing.vGap20,
                          NowPlayingControls(
                            isPlaying: playbackState.isPlaying,
                            isBuffering: playbackState.isBuffering,
                            hasError: playbackState.error != null,
                            isShuffle: playbackState.isShuffleEnabled,
                            repeatMode: playbackState.repeatMode,
                            onPlayPause: () => ref
                                .read(playbackControllerProvider.notifier)
                                .togglePlayPause(),
                            onNext: () => ref
                                .read(playbackControllerProvider.notifier)
                                .skipToNext(),
                            onPrevious: () => ref
                                .read(playbackControllerProvider.notifier)
                                .skipToPrevious(),
                            onToggleShuffle: () => ref
                                .read(playbackControllerProvider.notifier)
                                .toggleShuffle(),
                            onCycleRepeat: () => ref
                                .read(playbackControllerProvider.notifier)
                                .cycleRepeatMode(),
                          ),
                          AppSpacing.vGap16,

                          // Bottom action shortcuts matching .bot in audifi.html: Queue & Audio Info
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: colors.textMuted,
                                    minimumSize: const Size(0, 48),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.queue_music_rounded,
                                    size: 18.0,
                                  ),
                                  label: const Text('Queue', maxLines: 1),
                                  onPressed: () => QueueSheet.show(context),
                                ),
                              ),
                              AppSpacing.hGap12,
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: colors.textMuted,
                                    minimumSize: const Size(0, 48),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 18.0,
                                  ),
                                  label: const Text('Audio Info', maxLines: 1),
                                  onPressed: () => AudioInfoSheet.show(
                                    context,
                                    track: track,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vGap16,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
