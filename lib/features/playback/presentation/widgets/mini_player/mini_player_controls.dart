import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';

/// Control buttons row for the mini player with accessible tap targets.
class MiniPlayerControls extends StatelessWidget {
  const MiniPlayerControls({
    super.key,
    required this.isPlaying,
    required this.isBuffering,
    required this.onPlayPause,
    required this.onNext,
  });

  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play / Pause button
        Semantics(
          label: isPlaying ? 'Pause audio' : 'Play audio',
          button: true,
          child: SizedBox(
            width: 48.0,
            height: 48.0,
            child: IconButton(
              onPressed: onPlayPause,
              icon: AnimatedSwitcher(
                duration: AppMotion.resolveDuration(
                  AppMotion.durationFast,
                  context: context,
                ),
                switchInCurve: AppMotion.curveDecelerate,
                switchOutCurve: AppMotion.curveAccelerate,
                transitionBuilder: AppMotion.scaleFadeSwitcherTransition,
                child: isBuffering
                    ? SizedBox(
                        key: const ValueKey('mini_buffering'),
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.accent,
                          ),
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey<bool>(isPlaying),
                        color: colors.textPrimary,
                        size: 26.0,
                      ),
              ),
              tooltip: isPlaying ? 'Pause' : 'Play',
            ),
          ),
        ),

        // Next track button
        Semantics(
          label: 'Next track',
          button: true,
          child: SizedBox(
            width: 48.0,
            height: 48.0,
            child: IconButton(
              onPressed: onNext,
              icon: Icon(
                Icons.skip_next_rounded,
                color: colors.textPrimary,
                size: 24.0,
              ),
              tooltip: 'Next track',
            ),
          ),
        ),
      ],
    );
  }
}
