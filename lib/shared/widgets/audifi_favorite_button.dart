import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// Standardized, accessible favourite toggle button with consistent heart pop
/// animation, subtle scale feedback, and colour transitions.
///
/// Conforms to WCAG 4.1.2 with explicit semantics and minimum touch target size.
class AudifiFavoriteButton extends StatefulWidget {
  const AudifiFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 22.0,
    this.activeColor,
    this.inactiveColor,
    this.tooltip,
    this.constraints = const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
  });

  /// Whether the item is currently favorited.
  final bool isFavorite;

  /// Callback invoked when the user toggles favourite state.
  final VoidCallback onToggle;

  /// Icon size in logical pixels.
  final double size;

  /// Active color when favorited (defaults to [AudifiThemeColors.accent]).
  final Color? activeColor;

  /// Inactive color when unfavorited (defaults to [AudifiThemeColors.textMuted]).
  final Color? inactiveColor;

  /// Optional tooltip override.
  final String? tooltip;

  /// Box constraints ensuring platform-compliant touch target sizes.
  final BoxConstraints constraints;

  @override
  State<AudifiFavoriteButton> createState() => _AudifiFavoriteButtonState();
}

class _AudifiFavoriteButtonState extends State<AudifiFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationShort,
    );
    _scaleAnimation = const AlwaysStoppedAnimation(1.0);
  }

  @override
  void didUpdateWidget(covariant AudifiFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite) {
      final isReduced = AppMotion.isReducedMotion(context: context);
      if (isReduced) {
        _scaleAnimation = const AlwaysStoppedAnimation(1.0);
        _controller.value = 1.0;
        return;
      }

      if (widget.isFavorite) {
        // Heart pop animation on like: 1.0 -> 1.25 -> 1.0
        _scaleAnimation = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.0,
              end: 1.25,
            ).chain(CurveTween(curve: AppMotion.curveDecelerate)),
            weight: 45,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.25,
              end: 1.0,
            ).chain(CurveTween(curve: AppMotion.curveStandard)),
            weight: 55,
          ),
        ]).animate(_controller);
      } else {
        // Gentle dip on unlike: 1.0 -> 0.88 -> 1.0
        _scaleAnimation = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.0,
              end: 0.88,
            ).chain(CurveTween(curve: AppMotion.curveDecelerate)),
            weight: 40,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.88,
              end: 1.0,
            ).chain(CurveTween(curve: AppMotion.curveStandard)),
            weight: 60,
          ),
        ]).animate(_controller);
      }

      _controller.forward(from: 0.0);
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
    final isReduced = AppMotion.isReducedMotion(context: context);
    final durationFast = isReduced ? Duration.zero : AppMotion.durationFast;

    final targetActiveColor = widget.activeColor ?? colors.accent;
    final targetInactiveColor = widget.inactiveColor ?? colors.textMuted;
    final targetColor = widget.isFavorite
        ? targetActiveColor
        : targetInactiveColor;

    final tooltipText =
        widget.tooltip ??
        (widget.isFavorite ? 'Remove from favorites' : 'Add to favorites');

    return Semantics(
      button: true,
      toggled: widget.isFavorite,
      label: tooltipText,
      child: IconButton(
        onPressed: widget.onToggle,
        constraints: widget.constraints,
        tooltip: tooltipText,
        icon: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = isReduced ? 1.0 : _scaleAnimation.value;
            return Transform.scale(
              key: const ValueKey('audifi_favorite_scale_transform'),
              scale: scale,
              child: TweenAnimationBuilder<Color?>(
                duration: durationFast,
                curve: AppMotion.curveDecelerate,
                tween: ColorTween(end: targetColor),
                builder: (context, color, _) {
                  return AnimatedSwitcher(
                    duration: durationFast,
                    switchInCurve: AppMotion.curveDecelerate,
                    switchOutCurve: AppMotion.curveAccelerate,
                    transitionBuilder: AppMotion.scaleFadeSwitcherTransition,
                    child: Icon(
                      widget.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey<bool>(widget.isFavorite),
                      color: color ?? targetColor,
                      size: widget.size,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
