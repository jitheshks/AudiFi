import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// A custom compact, screenshot-accurate switch matching `appearance.png`
/// and `.sw` in `audifi.html`.
///
/// Features:
/// - 46x28 dp track with 14 dp corner radius
/// - 22 dp diameter pure white circular thumb with subtle drop shadow
/// - Butter-smooth cubic transition driven by [AnimationController]
/// - Reversible in-flight animation on rapid repeated toggles
/// - Respects reduced-motion preference
/// - Accessible 52x48 dp interaction target area
/// - Integrated screen-reader semantics
class AudifiSwitch extends StatefulWidget {
  const AudifiSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor = Colors.white,
    this.semanticLabel,
  });

  /// Whether the switch is on or off.
  final bool value;

  /// Called when the user toggles the switch.
  final ValueChanged<bool>? onChanged;

  /// Track color when switch is on. Defaults to [AudifiThemeColors.accent].
  final Color? activeColor;

  /// Track color when switch is off. Defaults to [AudifiThemeColors.surface2].
  final Color? inactiveColor;

  /// Thumb color. Defaults to pure white [Colors.white].
  final Color thumbColor;

  /// Semantic description for accessibility.
  final String? semanticLabel;

  @override
  State<AudifiSwitch> createState() => _AudifiSwitchState();
}

class _AudifiSwitchState extends State<AudifiSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
      duration: AppMotion.durationShort,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveDecelerate,
      reverseCurve: AppMotion.curveDecelerate.flipped,
    );
  }

  @override
  void didUpdateWidget(covariant AudifiSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final isReduced = AppMotion.isReducedMotion(context: context);
      if (isReduced) {
        _controller.value = widget.value ? 1.0 : 0.0;
      } else {
        final target = widget.value ? 1.0 : 0.0;
        // If the controller is already animating smoothly towards this target,
        // do not interrupt, restart, or stutter the in-flight simulation.
        final isAlreadyAnimatingToTarget =
            _controller.isAnimating &&
            ((widget.value && _controller.status == AnimationStatus.forward) ||
                (!widget.value &&
                    _controller.status == AnimationStatus.reverse));
        if (!isAlreadyAnimatingToTarget && _controller.value != target) {
          if (widget.value) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onChanged == null) return;
    final newValue = !widget.value;
    final isReduced = AppMotion.isReducedMotion(context: context);
    if (isReduced) {
      _controller.value = newValue ? 1.0 : 0.0;
    } else {
      if (newValue) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
    widget.onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    // Only resolve inherited theme colors if caller did not provide explicit colors.
    // This reduces unnecessary inherited widget dependencies in the switch subtree.
    final effectiveActiveColor =
        widget.activeColor ?? context.audifiColors.accent;
    final effectiveInactiveColor =
        widget.inactiveColor ?? context.audifiColors.surface2;

    return Semantics(
      toggled: widget.value,
      enabled: widget.onChanged != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onChanged != null ? _handleTap : null,
        child: Container(
          width: 52.0,
          height: 48.0,
          alignment: Alignment.center,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final trackColor = Color.lerp(
                  effectiveInactiveColor,
                  effectiveActiveColor,
                  _animation.value,
                )!;
                final thumbLeft = 3.0 + (18.0 * _animation.value);

                return Container(
                  width: 46.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 3.0,
                        left: thumbLeft,
                        child: Container(
                          width: 22.0,
                          height: 22.0,
                          decoration: BoxDecoration(
                            color: widget.thumbColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 3.0,
                                offset: const Offset(0, 1),
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
          ),
        ),
      ),
    );
  }
}
