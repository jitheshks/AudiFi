import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_motion.dart';

/// Standardized animated switcher for content-state transitions (tabs, loading -> data,
/// loading -> error, empty -> populated).
///
/// Automatically resolves duration and curve through [AppMotion], respecting both
/// application-level and platform-level Reduced Motion preferences.
class AudifiContentSwitcher extends StatelessWidget {
  const AudifiContentSwitcher({
    super.key,
    required this.child,
    this.duration = AppMotion.durationShort,
    this.reverseDuration,
    this.switchInCurve = AppMotion.curveDecelerate,
    this.switchOutCurve = AppMotion.curveAccelerate,
    this.transitionBuilder = AppMotion.contentFadeSwitcherTransition,
    this.layoutBuilder = defaultLayoutBuilder,
  });

  /// The active content widget (must have a stable, distinct [Key] when switching content).
  final Widget child;

  /// Standard duration when reduced motion is not active (defaults to [AppMotion.durationShort]).
  final Duration duration;

  /// Optional reverse transition duration.
  final Duration? reverseDuration;

  /// Curve for the incoming content.
  final Curve switchInCurve;

  /// Curve for the outgoing content.
  final Curve switchOutCurve;

  /// Transition builder (defaults to [AppMotion.contentFadeSwitcherTransition]).
  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  /// Layout builder.
  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  /// Default layout builder pinning children to the top and preventing outgoing
  /// children from receiving touch events or interfering with semantics.
  static Widget defaultLayoutBuilder(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      alignment: Alignment.topCenter,
      fit: StackFit.loose,
      children: <Widget>[
        ...previousChildren.map(
          (child) => ExcludeSemantics(
            child: IgnorePointer(ignoring: true, child: child),
          ),
        ),
        ?currentChild,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AppMotion.resolveDuration(
      duration,
      context: context,
    );
    final effectiveReverseDuration = reverseDuration != null
        ? AppMotion.resolveDuration(reverseDuration!, context: context)
        : effectiveDuration;

    return AnimatedSwitcher(
      duration: effectiveDuration,
      reverseDuration: effectiveReverseDuration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: transitionBuilder,
      layoutBuilder: layoutBuilder,
      child: child,
    );
  }
}
