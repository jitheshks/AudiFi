import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../domain/entities/artwork_palette.dart';

/// Ambient multi-layer gradient background that dynamically adapts to the current track's artwork.
/// Matches `.np .amb` in `references/UI/audifi.html`.
class AmbientGradientBackground extends StatefulWidget {
  const AmbientGradientBackground({
    super.key,
    required this.palette,
    this.isOled = false,
    this.isReducedMotion = false,
    this.child,
  });

  /// The active extracted artwork palette.
  final ArtworkPalette palette;

  /// Whether OLED pure black background is active.
  final bool isOled;

  /// Whether animations should be suppressed per user preference or platform settings.
  final bool isReducedMotion;

  /// Optional child content placed on top of the ambient gradient.
  final Widget? child;

  @override
  State<AmbientGradientBackground> createState() =>
      _AmbientGradientBackgroundState();
}

class _AmbientGradientBackgroundState extends State<AmbientGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ArtworkPalette _previousPalette;
  late ArtworkPalette _targetPalette;

  @override
  void initState() {
    super.initState();
    _previousPalette = widget.palette;
    _targetPalette = widget.palette;

    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationEmphasized,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveDecelerate,
    );
  }

  @override
  void didUpdateWidget(covariant AmbientGradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.palette != widget.palette) {
      final effectiveReduced =
          widget.isReducedMotion || AppMotion.isReducedMotion(context: context);
      final shouldAnimate =
          !effectiveReduced && !kIsWeb && _shouldAnimateTransition();

      if (shouldAnimate) {
        _previousPalette = _currentDisplayPalette;
        _targetPalette = widget.palette;
        _controller.forward(from: 0.0);
      } else {
        _previousPalette = widget.palette;
        _targetPalette = widget.palette;
        _controller.value = 1.0;
      }
    }
  }

  bool _shouldAnimateTransition() {
    return _previousPalette != widget.palette;
  }

  ArtworkPalette get _currentDisplayPalette {
    if (_controller.isAnimating) {
      return ArtworkPalette.lerp(
        _previousPalette,
        _targetPalette,
        _animation.value,
      );
    }
    return _targetPalette;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final current = _currentDisplayPalette;

        // Tuning opacity according to theme and OLED mode
        final dominantAlpha = widget.isOled ? 0.24 : (isDark ? 0.36 : 0.26);
        final secondaryAlpha = widget.isOled ? 0.18 : (isDark ? 0.28 : 0.20);
        final accentAlpha = widget.isOled ? 0.12 : (isDark ? 0.18 : 0.12);

        final bgColor = widget.isOled ? Colors.black : colors.background;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Solid base background
            Container(color: bgColor),

            // Ambient glow layers
            ExcludeSemantics(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.85,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Top dominant radial glow
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.55, -0.75),
                            radius: 0.90,
                            colors: [
                              current.dominant.withValues(alpha: dominantAlpha),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.70],
                          ),
                        ),
                      ),

                      // Bottom-right secondary radial glow
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.75, 0.35),
                            radius: 0.95,
                            colors: [
                              current.secondary.withValues(
                                alpha: secondaryAlpha,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.70],
                          ),
                        ),
                      ),

                      // Center-top accent highlight
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.1, -0.2),
                            radius: 0.65,
                            colors: [
                              current.accent.withValues(alpha: accentAlpha),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.60],
                          ),
                        ),
                      ),

                      // Bottom gradient fade into background to maintain controls contrast
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              bgColor.withValues(alpha: 0.50),
                              bgColor.withValues(alpha: 0.92),
                              bgColor,
                            ],
                            stops: const [0.0, 0.45, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main foreground content
            if (widget.child != null) widget.child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}
