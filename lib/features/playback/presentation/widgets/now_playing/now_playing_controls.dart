import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../domain/entities/repeat_mode.dart';

/// Control buttons row for the expanded Now Playing screen matching `.ctl` in `audifi.html`.
class NowPlayingControls extends StatelessWidget {
  const NowPlayingControls({
    super.key,
    required this.isPlaying,
    required this.isBuffering,
    this.hasError = false,
    required this.isShuffle,
    required this.repeatMode,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
  });

  final bool isPlaying;
  final bool isBuffering;
  final bool hasError;
  final bool isShuffle;
  final RepeatMode repeatMode;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeat;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final isReduced = AppMotion.isReducedMotion(context: context);
    final durationFast = isReduced ? Duration.zero : AppMotion.durationFast;

    final shuffleColor = isShuffle ? colors.accent : colors.textMuted;
    final repeatColor = repeatMode.isActive ? colors.accent : colors.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle button with secondary indicator & toggled trait (WCAG 1.4.1 & 4.1.2)
        Semantics(
          button: true,
          toggled: isShuffle,
          label: 'Shuffle',
          hint: isShuffle
              ? 'Double tap to turn shuffle off'
              : 'Double tap to turn shuffle on',
          child: SizedBox(
            width: 48.0,
            height: 48.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: onToggleShuffle,
                  icon: TweenAnimationBuilder<Color?>(
                    duration: durationFast,
                    curve: AppMotion.curveDecelerate,
                    tween: ColorTween(end: shuffleColor),
                    builder: (context, color, _) {
                      return Icon(
                        Icons.shuffle_rounded,
                        color: color ?? shuffleColor,
                        size: 24.0,
                      );
                    },
                  ),
                  tooltip: 'Shuffle: ${isShuffle ? "On" : "Off"}',
                ),
                Positioned(
                  bottom: 6.0,
                  child: AnimatedScale(
                    scale: isShuffle ? 1.0 : 0.0,
                    duration: durationFast,
                    curve: AppMotion.curveDecelerate,
                    child: Container(
                      width: 4.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Previous button
        SizedBox(
          width: 48.0,
          height: 48.0,
          child: IconButton(
            onPressed: onPrevious,
            icon: Icon(
              Icons.skip_previous_rounded,
              color: colors.textPrimary,
              size: 34.0,
            ),
            tooltip: 'Previous track',
          ),
        ),

        // Play / Pause / Retry circular 72x72 hero button matching .pp in audifi.html
        Semantics(
          button: true,
          label: hasError
              ? 'Retry playback'
              : (isBuffering
                    ? 'Buffering stream'
                    : (isPlaying ? 'Pause' : 'Play')),
          hint: hasError
              ? 'Double tap to retry playing track'
              : (isBuffering
                    ? null
                    : (isPlaying
                          ? 'Double tap to pause'
                          : 'Double tap to play')),
          child: Container(
            width: 72.0,
            height: 72.0,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.35),
                  blurRadius: 20.0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                focusColor: Colors.white.withValues(alpha: 0.4),
                onTap: onPlayPause,
                child: Center(
                  child: ExcludeSemantics(
                    child: AnimatedSwitcher(
                      duration: durationFast,
                      switchInCurve: AppMotion.curveDecelerate,
                      switchOutCurve: AppMotion.curveAccelerate,
                      transitionBuilder: AppMotion.scaleFadeSwitcherTransition,
                      child: hasError
                          ? Icon(
                              Icons.refresh_rounded,
                              key: const ValueKey('np_retry'),
                              color: colors.background,
                              size: 38.0,
                            )
                          : (isBuffering
                                ? SizedBox(
                                    key: const ValueKey('np_buffering'),
                                    width: 28.0,
                                    height: 28.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colors.background,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    key: ValueKey<bool>(isPlaying),
                                    color: colors.background,
                                    size: 38.0,
                                  )),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Next button
        SizedBox(
          width: 48.0,
          height: 48.0,
          child: IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.skip_next_rounded,
              color: colors.textPrimary,
              size: 34.0,
            ),
            tooltip: 'Next track',
          ),
        ),

        // Repeat button with secondary visual indicator & toggled trait
        Semantics(
          button: true,
          toggled: repeatMode.isActive,
          label: repeatMode.label,
          hint: 'Double tap to change repeat mode',
          child: SizedBox(
            width: 48.0,
            height: 48.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: onCycleRepeat,
                  icon: TweenAnimationBuilder<Color?>(
                    duration: durationFast,
                    curve: AppMotion.curveDecelerate,
                    tween: ColorTween(end: repeatColor),
                    builder: (context, color, _) {
                      return AnimatedSwitcher(
                        duration: durationFast,
                        switchInCurve: AppMotion.curveDecelerate,
                        switchOutCurve: AppMotion.curveAccelerate,
                        transitionBuilder:
                            AppMotion.scaleFadeSwitcherTransition,
                        child: Icon(
                          repeatMode == RepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          key: ValueKey<RepeatMode>(repeatMode),
                          color: color ?? repeatColor,
                          size: 24.0,
                        ),
                      );
                    },
                  ),
                  tooltip: repeatMode.label,
                ),
                Positioned(
                  bottom: 6.0,
                  child: AnimatedScale(
                    scale: repeatMode == RepeatMode.all ? 1.0 : 0.0,
                    duration: durationFast,
                    curve: AppMotion.curveDecelerate,
                    child: Container(
                      width: 4.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
