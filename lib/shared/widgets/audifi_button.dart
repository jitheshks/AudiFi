import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'audifi_loading_indicator.dart';

/// Style variants for [AudifiButton].
enum AudifiButtonVariant {
  /// Accent vibrant blurple background with white text.
  primary,

  /// Elevated surface 2 background with standard primary text.
  secondary,

  /// Inverted high-contrast pill (text primary background with background text).
  inverted,
}

/// Compatibility alias for [AudifiButtonVariant].
typedef AudifiButtonType = AudifiButtonVariant;

/// A reusable button styled after the Audifi design system pills and action buttons.
/// Guarantees a minimum 48x48 dp tap target for Android accessibility compliance,
/// and provides centralized, subtle press/release feedback and state transitions.
class AudifiButton extends StatefulWidget {
  const AudifiButton({
    super.key,
    required this.text,
    required this.onPressed,
    AudifiButtonVariant? variant,
    AudifiButtonVariant? type,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  }) : variant = type ?? variant ?? AudifiButtonVariant.primary;

  /// Button label text.
  final String text;

  /// Callback when pressed. If null or [isLoading] is true, the button is disabled.
  final VoidCallback? onPressed;

  /// Visual styling variant.
  final AudifiButtonVariant variant;

  /// Optional leading icon widget.
  final Widget? icon;

  /// Whether the button is in a loading state.
  final bool isLoading;

  /// Whether the button expands to fill available horizontal space.
  final bool isFullWidth;

  /// Custom padding inside the button.
  final EdgeInsetsGeometry? padding;

  @override
  State<AudifiButton> createState() => _AudifiButtonState();
}

class _AudifiButtonState extends State<AudifiButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final isReduced = AppMotion.isReducedMotion(context: context);

    Color backgroundColor;
    Color foregroundColor;

    switch (widget.variant) {
      case AudifiButtonVariant.primary:
        backgroundColor = colors.accent;
        foregroundColor = Colors.white;
      case AudifiButtonVariant.secondary:
        backgroundColor = colors.surface2;
        foregroundColor = colors.textPrimary;
      case AudifiButtonVariant.inverted:
        backgroundColor = colors.textPrimary;
        foregroundColor = colors.background;
    }

    final effectiveOnPressed = widget.isLoading ? null : widget.onPressed;
    final isEnabled = effectiveOnPressed != null;

    final targetBg = isEnabled
        ? backgroundColor
        : backgroundColor.withValues(alpha: 0.4);

    final targetFg = isEnabled
        ? foregroundColor
        : foregroundColor.withValues(alpha: 0.5);

    final durationFast = isReduced ? Duration.zero : AppMotion.durationFast;
    final durationShort = isReduced ? Duration.zero : AppMotion.durationShort;

    Widget content = AnimatedSwitcher(
      duration: durationFast,
      switchInCurve: AppMotion.curveDecelerate,
      switchOutCurve: AppMotion.curveAccelerate,
      transitionBuilder: AppMotion.scaleFadeSwitcherTransition,
      child: Row(
        key: ValueKey<bool>(widget.isLoading),
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isLoading) ...[
            AudifiLoadingIndicator(
              size: 16.0,
              strokeWidth: 2.0,
              color: foregroundColor,
            ),
            AppSpacing.hGap8,
          ] else if (widget.icon != null) ...[
            IconTheme(
              data: IconThemeData(color: targetFg, size: 18.0),
              child: widget.icon!,
            ),
            AppSpacing.hGap8,
          ],
          Flexible(
            fit: widget.isFullWidth ? FlexFit.tight : FlexFit.loose,
            child: AnimatedDefaultTextStyle(
              duration: durationFast,
              curve: AppMotion.curveDecelerate,
              style: AppTypography.button.copyWith(color: targetFg),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );

    final effectiveScale = (_isPressed && isEnabled && !isReduced)
        ? AppMotion.pressScale
        : 1.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 48.0,
        minWidth: widget.isFullWidth ? double.infinity : 48.0,
      ),
      child: AnimatedScale(
        scale: effectiveScale,
        duration: durationFast,
        curve: AppMotion.curveDecelerate,
        child: AnimatedContainer(
          duration: durationShort,
          curve: AppMotion.curveDecelerate,
          decoration: BoxDecoration(
            color: targetBg,
            borderRadius: AppRadius.pillBorder,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.pillBorder,
            child: InkWell(
              onTap: effectiveOnPressed,
              onHighlightChanged: (highlighted) {
                if (_isPressed != highlighted) {
                  setState(() => _isPressed = highlighted);
                }
              },
              borderRadius: AppRadius.pillBorder,
              child: Padding(
                padding:
                    widget.padding ??
                    const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 12.0,
                    ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
