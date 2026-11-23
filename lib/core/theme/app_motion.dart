import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'theme_controller.dart';

/// Navigation transition types supported by [AppMotion].
enum AppTransitionType {
  /// Smooth cross-fade transition.
  fade,

  /// Subtle horizontal slide with simultaneous cross-fade.
  slideFade,

  /// Upward slide with simultaneous cross-fade (e.g. for Now Playing).
  slideUp,
}

/// Centralized motion configuration for the Audifi application.
///
/// Provides a unified, predictable, and cohesive motion language across
/// micro-interactions, component state changes, screen transitions, and sheets.
///
/// Adheres to motion design principles:
/// - Smooth & natural: easing curves model physical deceleration.
/// - Lightweight & responsive: short durations prevent interaction delays.
/// - Accessible: seamlessly respects [animationModeProvider] ('Full' vs 'Reduced')
///   and platform accessibility reduced-motion settings.
abstract final class AppMotion {
  // ---------------------------------------------------------------------------
  // Durations
  // ---------------------------------------------------------------------------

  /// Fast micro-interactions: icon color morphs, badge updates, tap press feedback.
  static const Duration durationFast = Duration(milliseconds: 150);

  /// Standard subtle down-scale factor applied during tap press feedback.
  static const double pressScale = 0.98;

  /// Standard component state changes: switches, tabs selection, button states.
  static const Duration durationShort = Duration(milliseconds: 200);

  /// Destination & route page transitions: Home -> Discover, Settings sub-screens.
  static const Duration durationPage = Duration(milliseconds: 250);

  /// Standard component transitions: bottom sheets entrance/exit, dialogs, cards.
  static const Duration durationMedium = Duration(milliseconds: 300);

  /// Emphasized transitions: full modal reveal, Now Playing expansion.
  static const Duration durationEmphasized = Duration(milliseconds: 400);

  // ---------------------------------------------------------------------------
  // Easing Curves
  // ---------------------------------------------------------------------------

  /// Standard curve for natural acceleration and deceleration.
  static const Curve curveStandard = Curves.easeInOutCubic;

  /// Deceleration curve for incoming elements, state switches, and interactive responses.
  static const Curve curveDecelerate = Curves.easeOutCubic;

  /// Acceleration curve for exiting elements and dismissals.
  static const Curve curveAccelerate = Curves.easeInCubic;

  /// Emphasized curve for dramatic yet refined visual focus transitions.
  static const Curve curveEmphasized = Curves.easeInOutCubicEmphasized;

  // ---------------------------------------------------------------------------
  // Reduced-Motion Resolution
  // ---------------------------------------------------------------------------

  /// Determines whether reduced-motion is active.
  ///
  /// Checks application-level preference ([isReduced] or [isReducedMotionProvider])
  /// or the platform-level accessibility setting ([MediaQuery.disableAnimations]).
  static bool isReducedMotion({bool isReduced = false, BuildContext? context}) {
    if (isReduced) return true;
    if (context != null && context.mounted) {
      final mediaQueryDisabled =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (mediaQueryDisabled) return true;
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        if (container.read(isReducedMotionProvider)) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Resolves the effective duration given the standard duration and reduced-motion state.
  ///
  /// Returns [Duration.zero] if reduced motion is active, eliminating unnecessary
  /// movement while ensuring immediate state feedback.
  static Duration resolveDuration(
    Duration standardDuration, {
    bool isReduced = false,
    BuildContext? context,
  }) {
    if (isReducedMotion(isReduced: isReduced, context: context)) {
      return Duration.zero;
    }
    return standardDuration;
  }

  // ---------------------------------------------------------------------------
  // Component Switcher Transitions
  // ---------------------------------------------------------------------------

  /// A standardized scale and fade transition builder for [AnimatedSwitcher],
  /// used across Play/Pause controls, button state morphs, and indicators.
  static Widget scaleFadeSwitcherTransition(
    Widget child,
    Animation<double> animation, {
    double beginScale = 0.85,
  }) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: beginScale, end: 1.0).animate(animation),
        child: child,
      ),
    );
  }

  /// A standardized cross-fade transition builder for content switching in [AnimatedSwitcher],
  /// used for tabs, loading->data, loading->error, and empty->populated transitions.
  static Widget contentFadeSwitcherTransition(
    Widget child,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppMotion.curveDecelerate,
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Modal & Dialog Transitions
  // ---------------------------------------------------------------------------

  /// Creates a standardized [AnimationStyle] for modal dialogs and bottom sheets.
  ///
  /// Conforms to [durationMedium] (300ms) with [curveDecelerate] entrance and
  /// [curveAccelerate] dismissal. When reduced motion is active, returns
  /// [AnimationStyle.noAnimation] for immediate presentation.
  static AnimationStyle modalAnimationStyle({
    BuildContext? context,
    bool isReduced = false,
    Duration duration = durationMedium,
    Duration? reverseDuration,
    Curve curve = curveDecelerate,
    Curve reverseCurve = curveAccelerate,
  }) {
    if (isReducedMotion(isReduced: isReduced, context: context)) {
      return AnimationStyle.noAnimation;
    }
    return AnimationStyle(
      duration: duration,
      reverseDuration: reverseDuration ?? duration,
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  /// Displays a standardized modal bottom sheet conforming to [AppMotion].
  static Future<T?> showModalSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    Color? backgroundColor,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showDragHandle = false,
    bool useSafeArea = false,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
    AnimationStyle? sheetAnimationStyle,
  }) {
    final effectiveStyle =
        sheetAnimationStyle ?? modalAnimationStyle(context: context);

    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      sheetAnimationStyle: effectiveStyle,
    );
  }

  /// Displays a standardized dialog conforming to [AppMotion].
  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    AnimationStyle? animationStyle,
  }) {
    final effectiveStyle =
        animationStyle ?? modalAnimationStyle(context: context);

    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      animationStyle: effectiveStyle,
    );
  }

  // ---------------------------------------------------------------------------
  // Page Transition Factory
  // ---------------------------------------------------------------------------

  /// Creates a [Page] with a standardized transition curve and dynamic duration.
  ///
  /// Respects reduced motion settings dynamically at the time the transition
  /// occurs without requiring router recreation.
  static Page<T> createPage<T>({
    required LocalKey key,
    required Widget child,
    AppTransitionType type = AppTransitionType.slideFade,
    bool isReduced = false,
    Duration duration = durationPage,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return AudifiTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      type: type,
      duration: isReduced ? Duration.zero : duration,
      child: child,
    );
  }
}

/// A custom transition page that dynamically resolves its transition duration
/// and curve using [AppMotion], ensuring route transitions immediately adapt
/// when the user or platform toggles Reduced Motion.
class AudifiTransitionPage<T> extends Page<T> {
  const AudifiTransitionPage({
    required this.child,
    this.type = AppTransitionType.slideFade,
    this.duration = AppMotion.durationPage,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The widget content for this page.
  final Widget child;

  /// The transition style to use when entering and exiting.
  final AppTransitionType type;

  /// The standard duration when reduced motion is not active.
  final Duration duration;

  @override
  Route<T> createRoute(BuildContext context) =>
      _AudifiPageRoute<T>(this, context);
}

class _AudifiPageRoute<T> extends PageRoute<T> {
  _AudifiPageRoute(this.page, this._routeContext) : super(settings: page);

  final AudifiTransitionPage<T> page;
  final BuildContext _routeContext;

  @override
  Duration get transitionDuration =>
      AppMotion.resolveDuration(page.duration, context: _effectiveContext);

  @override
  Duration get reverseTransitionDuration =>
      AppMotion.resolveDuration(page.duration, context: _effectiveContext);

  BuildContext? get _effectiveContext =>
      navigator?.context ?? (_routeContext.mounted ? _routeContext : null);

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: page.child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.isReducedMotion(context: context)) {
      return child;
    }

    switch (page.type) {
      case AppTransitionType.fade:
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AppMotion.curveDecelerate,
          ),
          child: child,
        );

      case AppTransitionType.slideFade:
        // Primary transition for the incoming route (slide in from right + gentle fade).
        final primarySlide =
            Tween<Offset>(
              begin: const Offset(0.10, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: AppMotion.curveDecelerate,
              ),
            );

        final primaryFade = CurvedAnimation(
          parent: animation,
          curve: AppMotion.curveDecelerate,
        );

        // Secondary transition for the outgoing route (subtle parallax left + gentle dim).
        final secondarySlide =
            Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.04, 0.0),
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: AppMotion.curveDecelerate,
              ),
            );

        final secondaryFade = Tween<double>(begin: 1.0, end: 0.90).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: AppMotion.curveDecelerate,
          ),
        );

        return SlideTransition(
          position: secondarySlide,
          child: FadeTransition(
            opacity: secondaryFade,
            child: SlideTransition(
              position: primarySlide,
              child: FadeTransition(opacity: primaryFade, child: child),
            ),
          ),
        );

      case AppTransitionType.slideUp:
        final slideUpAnimation =
            Tween<Offset>(
              begin: const Offset(0.0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: AppMotion.curveDecelerate,
              ),
            );
        return SlideTransition(
          position: slideUpAnimation,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppMotion.curveDecelerate,
            ),
            child: child,
          ),
        );
    }
  }
}

/// A custom transition page container for GoRouter route branches.
///
/// Smoothly transitions between branch views via a cross-fade without unmounting
/// or resetting any branch navigator state.
///
/// Ensures inactive branches remain off-stage when not animating, maintaining
/// accessibility semantics, performance, and standard test finder behavior.
class AnimatedBranchContainer extends StatefulWidget {
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
    this.isReduced = false,
  });

  /// The active branch index.
  final int currentIndex;

  /// The list of branch navigator widgets.
  final List<Widget> children;

  /// Whether reduced-motion is enabled.
  final bool isReduced;

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _lastIndex = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _lastIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationPage,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveDecelerate,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _currentIndex) {
      _lastIndex = _currentIndex;
      _currentIndex = widget.currentIndex;

      final isReduced =
          widget.isReduced || AppMotion.isReducedMotion(context: context);

      if (isReduced) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final isAnimating = _controller.isAnimating;

        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (index) {
            final isIncoming = index == _currentIndex;
            final isOutgoing = index == _lastIndex && isAnimating;
            final isOnstage = isIncoming || isOutgoing;

            double opacity = 0.0;
            if (isIncoming) {
              opacity = isAnimating ? _animation.value : 1.0;
            } else if (isOutgoing) {
              opacity = 1.0 - _animation.value;
            }

            return Offstage(
              offstage: !isOnstage,
              child: IgnorePointer(
                ignoring: !isIncoming,
                child: TickerMode(
                  enabled: isIncoming,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: widget.children[index],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
