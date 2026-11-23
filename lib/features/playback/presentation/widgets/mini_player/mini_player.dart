import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/router/route_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/theme_controller.dart';
import '../../../../tracks/domain/entities/track.dart';
import '../../controllers/playback_controller.dart';
import 'mini_player_artwork.dart';
import 'mini_player_controls.dart';
import 'mini_player_info.dart';
import 'mini_player_progress.dart';

/// Persistent floating mini-player bar matching `.mini` styling in `audifi.html`.
///
/// Automatically renders when an active track exists, animating its entrance
/// and exit with centralized [AppMotion] tokens, and navigates to the expanded
/// Now Playing view upon tap.
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Track? _lastTrack;

  @override
  void initState() {
    super.initState();
    final initialTrack = ref.read(playbackControllerProvider).currentTrack;
    _lastTrack = initialTrack;

    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationMedium,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveDecelerate,
      reverseCurve: AppMotion.curveAccelerate,
    );

    if (initialTrack != null) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    ref.listen<bool>(
      playbackControllerProvider.select((s) => s.currentTrack != null),
      (previous, hasTrack) {
        final isReduced = AppMotion.isReducedMotion(context: context);
        if (isReduced) {
          _controller.value = hasTrack ? 1.0 : 0.0;
        } else if (hasTrack) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      },
    );

    ref.listen<bool>(isReducedMotionProvider, (previous, isReduced) {
      if (isReduced) {
        final hasTrack =
            ref.read(playbackControllerProvider).currentTrack != null;
        _controller.value = hasTrack ? 1.0 : 0.0;
      }
    });

    final playbackState = ref.watch(playbackControllerProvider);
    final track = playbackState.currentTrack;
    if (track != null) {
      _lastTrack = track;
    }
    final displayTrack = track ?? _lastTrack;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        if (_controller.value == 0.0 && track == null) {
          return const SizedBox.shrink();
        }

        if (displayTrack == null) {
          return const SizedBox.shrink();
        }

        final isInteractive = track != null && _controller.value > 0.5;

        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: _animation.value,
            child: FractionalTranslation(
              translation: Offset(0.0, 0.25 * (1.0 - _animation.value)),
              child: Opacity(
                opacity: _animation.value.clamp(0.0, 1.0),
                child: IgnorePointer(
                  ignoring: !isInteractive,
                  child: Semantics(
                    container: true,
                    label:
                        'Mini audio player: ${displayTrack.title} by ${displayTrack.user?.name ?? "Unknown artist"}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface1,
                        borderRadius: BorderRadius.circular(18.0),
                        border: Border.all(color: colors.surface2, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 16.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => context.push(RoutePaths.nowPlaying),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10.0,
                                  8.0,
                                  4.0,
                                  8.0,
                                ),
                                child: Row(
                                  children: [
                                    MiniPlayerArtwork(
                                      imageUrl:
                                          displayTrack.artwork?.thumbnailUrl,
                                    ),
                                    const SizedBox(width: 12.0),
                                    MiniPlayerInfo(track: displayTrack),
                                    MiniPlayerControls(
                                      isPlaying: playbackState.isPlaying,
                                      isBuffering: playbackState.isBuffering,
                                      onPlayPause: () => ref
                                          .read(
                                            playbackControllerProvider.notifier,
                                          )
                                          .togglePlayPause(),
                                      onNext: () => ref
                                          .read(
                                            playbackControllerProvider.notifier,
                                          )
                                          .skipToNext(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            MiniPlayerProgress(
                              progress: playbackState.progress,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
