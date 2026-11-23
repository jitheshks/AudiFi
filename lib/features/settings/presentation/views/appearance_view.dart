import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/audifi_card.dart';
import '../../../../shared/widgets/audifi_switch.dart';
import '../controllers/settings_controller.dart';

/// Appearance sub-screen faithfully calibrated against `appearance.png`
/// and `.grp.f` in `references/UI/audifi.html`.
class AppearanceView extends ConsumerStatefulWidget {
  const AppearanceView({super.key});

  @override
  ConsumerState<AppearanceView> createState() => _AppearanceViewState();
}

class _AppearanceViewState extends ConsumerState<AppearanceView> {
  bool _isNavigating = false;

  void _navigateToAccent() {
    if (_isNavigating) return;
    _isNavigating = true;
    context.push(RoutePaths.settingsAccent).then((_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final currentMode = ref.read(themeModeProvider);

    AppMotion.showModalSheet<void>(
      context: context,
      backgroundColor: colors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: colors.surface2,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
                  child: Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                ...ThemeMode.values.map((mode) {
                  final isSelected = mode == currentMode;
                  return ListTile(
                    title: Text(
                      _themeLabel(mode),
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected ? colors.accent : colors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: colors.accent)
                        : null,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8.0),

              // Back button "‹ Settings" matching .bk in audifi.html and appearance.png
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    if (context.canPop()) context.pop();
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '‹ Settings',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ),
              ),

              // Heading: Appearance matching .stt in audifi.html
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                child: Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Section: THEME
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Text(
                  'THEME',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // THEME Card (minHeight: 66.0)
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: InkWell(
                  onTap: () => _showThemeDialog(context, ref),
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 66.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Theme',
                                style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                'Light, dark or system',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final currentThemeMode = ref.watch(
                              themeModeProvider,
                            );
                            return Text(
                              _themeLabel(currentThemeMode),
                              style: TextStyle(
                                fontSize: 14.0,
                                color: colors.textMuted,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4.0),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textMuted.withValues(alpha: 0.5),
                          size: 20.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Section: ACCENT
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  'ACCENT',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // ACCENT Card (minHeight: 66.0)
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: InkWell(
                  onTap: _navigateToAccent,
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 66.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Accent color',
                                style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                'Choose color',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final currentAccent = ref.watch(
                              accentColorProvider,
                            );
                            return Text(
                              currentAccent.name,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: colors.textMuted,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4.0),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textMuted.withValues(alpha: 0.5),
                          size: 20.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Section: PLAYER
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  'PLAYER',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // PLAYER Card (Combined 2-row card with subtle divider)
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: Column(
                  children: [
                    // Row 1: Dynamic artwork colors
                    Container(
                      constraints: const BoxConstraints(minHeight: 66.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Dynamic artwork colors',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  'Use colors from the current album artwork',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final dynamicColors = ref.watch(
                                settingsControllerProvider.select(
                                  (s) => s.dynamicColors,
                                ),
                              );
                              return AudifiSwitch(
                                key: const ValueKey('switch_dynamic_colors'),
                                value: dynamicColors,
                                activeColor: colors.accent,
                                inactiveColor: colors.surface2,
                                semanticLabel: 'Dynamic artwork colors',
                                onChanged: (val) {
                                  ref
                                      .read(settingsControllerProvider.notifier)
                                      .setDynamicColors(val);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: colors.textPrimary.withValues(alpha: 0.08),
                      height: 1.0,
                      thickness: 1.0,
                    ),
                    // Row 2: OLED black
                    Container(
                      constraints: const BoxConstraints(minHeight: 66.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'OLED black',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  'Use a pure black background in dark mode',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final isOled = ref.watch(oledModeProvider);
                              return AudifiSwitch(
                                key: const ValueKey('switch_oled_black'),
                                value: isOled,
                                activeColor: colors.accent,
                                inactiveColor: colors.surface2,
                                semanticLabel: 'OLED black',
                                onChanged: (val) {
                                  ref
                                      .read(oledModeProvider.notifier)
                                      .setOled(val);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Section: ANIMATION
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  'ANIMATION',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // ANIMATION Card (minHeight: 66.0)
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: InkWell(
                  onTap: () {
                    ref.read(animationModeProvider.notifier).toggle();
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 66.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Animations',
                                style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                'Full or reduced motion',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final animationMode = ref.watch(
                              animationModeProvider,
                            );
                            return Text(
                              animationMode,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: colors.textMuted,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48.0),
            ],
          ),
        ),
      ),
    );
  }
}
