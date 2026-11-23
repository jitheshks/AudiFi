import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_motion.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/playback/presentation/controllers/playback_controller.dart';
import 'router/app_router.dart';

/// Root application widget for Audifi.
/// Integrates Riverpod for theme management and GoRouter for declarative routing.
class AudifiApp extends ConsumerStatefulWidget {
  const AudifiApp({super.key});

  @override
  ConsumerState<AudifiApp> createState() => _AudifiAppState();
}

class _AudifiAppState extends ConsumerState<AudifiApp> {
  ThemeMode? _previousThemeMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final playbackState = ref.read(playbackControllerProvider);
        if (!playbackState.hasTrack) {
          ref.read(playbackControllerProvider.notifier).restoreSavedQueue();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isOled = ref.watch(oledModeProvider);
    final accent = ref.watch(accentColorProvider);

    // Only interpolate root theme if themeMode (brightness mode) actually changed.
    // For OLED black toggles within dark mode or accent color adjustments, avoiding
    // root ThemeData interpolation eliminates continuous 250ms rebuild loops that
    // starve local micro-animations of UI thread frame budget.
    final themeModeChanged =
        _previousThemeMode != null && _previousThemeMode != themeMode;
    _previousThemeMode = themeMode;

    final isReduced = ref.watch(isReducedMotionProvider);
    final themeDuration = themeModeChanged
        ? AppMotion.resolveDuration(
            AppMotion.durationPage,
            isReduced: isReduced,
          )
        : Duration.zero;

    return MaterialApp.router(
      title: 'AudiFi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeWith(accent.color),
      darkTheme: isOled
          ? AppTheme.oledThemeWith(accent.color)
          : AppTheme.darkThemeWith(accent.color),
      themeMode: themeMode,
      themeAnimationDuration: themeDuration,
      themeAnimationCurve: AppMotion.curveStandard,
      routerConfig: router,
    );
  }
}
