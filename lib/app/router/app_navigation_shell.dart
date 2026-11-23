import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/responsive/responsive_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../features/playback/presentation/controllers/playback_controller.dart';
import '../../features/playback/presentation/widgets/mini_player/mini_player.dart';
import '../../shared/widgets/audifi_nav_icons.dart';

/// Navigation shell wrapping [StatefulNavigationShell] to provide persistent
/// navigation across the primary Audifi destinations.
///
/// Features:
/// - Adapts between a screenshot-accurate bottom navigation bar on mobile
///   and a side navigation rail on tablets / wide viewports.
/// - Centralized route-based visibility: hides the bottom navigation bar on
///   Settings sub-screens (e.g. Appearance, Accent Color) matching reference screenshots.
class AppNavigationShell extends ConsumerWidget {
  const AppNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  static const List<String> _labels = [
    'Home',
    'Discover',
    'Search',
    'Library',
    'Settings',
  ];

  /// Centralized route-based visibility check conforming to Audifi specifications.
  /// The bottom navigation bar is visible on the 5 primary destinations and hidden
  /// on Settings sub-screens (e.g., Appearance, Accent Color).
  static bool isBottomNavVisible(String location) {
    if (location.startsWith('/settings/')) {
      return false;
    }
    return true;
  }

  static Widget _buildIcon(int index, Color color, double size) {
    switch (index) {
      case 0:
        return Icon(Icons.home_rounded, color: color, size: size);
      case 1:
        return AudifiWaveIcon(color: color, size: size);
      case 2:
        return Icon(Icons.search_rounded, color: color, size: size);
      case 3:
        return AudifiLibraryIcon(color: color, size: size);
      case 4:
        return Icon(Icons.tune_rounded, color: color, size: size);
      default:
        return Icon(Icons.circle, color: color, size: size);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final isWide = context.isWideScreen;
    final router = GoRouter.of(context);
    final hasActiveTrack = ref.watch(
      playbackControllerProvider.select((s) => s.currentTrack != null),
    );

    ref.listen<String?>(
      playbackControllerProvider.select((s) => s.error?.message),
      (previous, errorMessage) {
        final error = ref.read(playbackControllerProvider).error;
        if (errorMessage != null && error?.code == 'mobile_data_restricted') {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
    );

    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final location = router.state.matchedLocation;
        final showBottomNav = isBottomNavVisible(location);

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  scrollable: true,
                  useIndicator: false,
                  backgroundColor: colors.surface1,
                  indicatorColor: Colors.transparent,
                  selectedIconTheme: IconThemeData(
                    color: colors.accent,
                    size: 24,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: colors.textMuted,
                    size: 24,
                  ),
                  selectedLabelTextStyle: AppTypography.nav.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelTextStyle: AppTypography.nav.copyWith(
                    color: colors.textMuted,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: AudifiWaveIcon(color: colors.accent, size: 28.0),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: const Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: AudifiWaveIcon(color: colors.textMuted, size: 22.0),
                      selectedIcon: AudifiWaveIcon(
                        color: colors.accent,
                        size: 22.0,
                      ),
                      label: const Text('Discover'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.search_rounded),
                      selectedIcon: const Icon(Icons.search_rounded),
                      label: const Text('Search'),
                    ),
                    NavigationRailDestination(
                      icon: AudifiLibraryIcon(
                        color: colors.textMuted,
                        size: 22.0,
                      ),
                      selectedIcon: AudifiLibraryIcon(
                        color: colors.accent,
                        size: 22.0,
                      ),
                      label: const Text('Library'),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.tune_rounded),
                      selectedIcon: const Icon(Icons.tune_rounded),
                      label: const Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SafeArea(
                    top: false,
                    left: false,
                    child: Column(
                      children: [
                        Expanded(child: navigationShell),
                        const MiniPlayer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Bottom Navigation Bar Layout strictly matching screenshots
        // with smooth sliding selection and animated route visibility transitions.
        final isReduced = AppMotion.isReducedMotion(context: context);

        final bottomBar = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            AudifiBottomNavVisibility(
              visible: showBottomNav,
              hasActiveTrack: hasActiveTrack,
              isReduced: isReduced,
              child: AudifiBottomNavBar(
                currentIndex: navigationShell.currentIndex,
                onTap: _onDestinationSelected,
                colors: colors,
                isReduced: isReduced,
              ),
            ),
          ],
        );

        return Scaffold(body: navigationShell, bottomNavigationBar: bottomBar);
      },
    );
  }
}

/// Screenshot-accurate bottom navigation bar with a smooth sliding selection transition.
///
/// Features:
/// - Active icon and label remain red using the global accent color.
/// - Inactive items remain muted.
/// - Zero pill, square, outline, or background selection shape.
/// - Smoothly slides the active selection highlight across destinations using [AppMotion.durationPage]
///   and [AppMotion.curveDecelerate].
/// - Respects Reduced Motion with immediate state updates.
class AudifiBottomNavBar extends StatefulWidget {
  const AudifiBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.colors,
    this.isReduced = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final AudifiThemeColors colors;
  final bool isReduced;

  @override
  State<AudifiBottomNavBar> createState() => _AudifiBottomNavBarState();
}

class _AudifiBottomNavBarState extends State<AudifiBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _fromPosition = 0.0;
  double _toPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _fromPosition = widget.currentIndex.toDouble();
    _toPosition = widget.currentIndex.toDouble();
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
  void didUpdateWidget(covariant AudifiBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      final isReduced =
          widget.isReduced || AppMotion.isReducedMotion(context: context);
      if (isReduced) {
        _fromPosition = widget.currentIndex.toDouble();
        _toPosition = widget.currentIndex.toDouble();
        _controller.value = 1.0;
      } else {
        _fromPosition = _currentPosition;
        _toPosition = widget.currentIndex.toDouble();
        _controller.forward(from: 0.0);
      }
    }
  }

  double get _currentPosition {
    if (_controller.isAnimating) {
      return ui.lerpDouble(_fromPosition, _toPosition, _animation.value) ??
          _toPosition;
    }
    return _toPosition;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.colors.surface1,
        border: Border(
          top: BorderSide(
            color: widget.colors.surface2.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final currentPos = _currentPosition;

              return Row(
                children: List.generate(AppNavigationShell._labels.length, (
                  index,
                ) {
                  final isSelected = widget.currentIndex == index;
                  final label = AppNavigationShell._labels[index];

                  // Distance from the sliding active selection position
                  final distance = (currentPos - index).abs();
                  final factor = (1.0 - distance).clamp(0.0, 1.0);

                  final targetColor = Color.lerp(
                    widget.colors.textMuted,
                    widget.colors.accent,
                    factor,
                  )!;

                  final textStyle = TextStyle(
                    fontSize: 11.0,
                    fontWeight: factor > 0.5
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: targetColor,
                  );

                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: label,
                      child: InkWell(
                        onTap: () => widget.onTap(index),
                        borderRadius: BorderRadius.circular(16.0),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 5.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppNavigationShell._buildIcon(
                                index,
                                targetColor,
                                22.0,
                              ),
                              const SizedBox(height: 3.0),
                              DefaultTextStyle(
                                style: textStyle,
                                child: Text(
                                  label,
                                  style: textStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Animated visibility container for the mobile bottom navigation bar.
///
/// Smoothly slides down and collapses height when entering screens where the
/// navigation bar is hidden (e.g. Appearance, Accent Color), and smoothly
/// slides up when returning to primary destinations.
class AudifiBottomNavVisibility extends StatefulWidget {
  const AudifiBottomNavVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.hasActiveTrack = false,
    this.isReduced = false,
  });

  final bool visible;
  final Widget child;
  final bool hasActiveTrack;
  final bool isReduced;

  @override
  State<AudifiBottomNavVisibility> createState() =>
      _AudifiBottomNavVisibilityState();
}

class _AudifiBottomNavVisibilityState extends State<AudifiBottomNavVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationPage,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveDecelerate,
      reverseCurve: AppMotion.curveDecelerate,
    );
    _controller.value = widget.visible ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(covariant AudifiBottomNavVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      final isReduced =
          widget.isReduced || AppMotion.isReducedMotion(context: context);
      if (isReduced) {
        _controller.value = widget.visible ? 1.0 : 0.0;
      } else if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        if (_controller.value == 0.0 && !widget.visible) {
          if (widget.hasActiveTrack && bottomInset > 0) {
            return SizedBox(height: bottomInset);
          }
          return const SizedBox.shrink();
        }

        final extraPadding = widget.hasActiveTrack
            ? (1.0 - _animation.value) * bottomInset
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _animation.value,
                child: FractionalTranslation(
                  translation: Offset(0.0, 1.0 - _animation.value),
                  child: Opacity(
                    opacity: _animation.value.clamp(0.0, 1.0),
                    child: widget.child,
                  ),
                ),
              ),
            ),
            if (extraPadding > 0) SizedBox(height: extraPadding),
          ],
        );
      },
    );
  }
}
