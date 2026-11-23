import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/audifi_card.dart';
import '../../../../shared/widgets/audifi_nav_icons.dart';
import '../../../../shared/widgets/audifi_page_container.dart';

/// Settings destination view strictly matching `settings.png` and `audifi.html`.
/// Presents drill-down navigation cards for Playback, Notifications, Audio, Music,
/// Appearance, Privacy, and About using consistent full-page routes.
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _isNavigating = false;

  void _navigateTo(String path) {
    if (_isNavigating) return;
    _isNavigating = true;
    context.push(path).then((_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  Widget _buildSectionItem({
    required BuildContext context,
    required AudifiThemeColors colors,
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AudifiCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              // Icon container with rounded square background (.ico in audifi.html)
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11.0),
                ),
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13.0, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textMuted.withValues(alpha: 0.5),
                size: 20.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;

    return Scaffold(
      body: AudifiPageContainer(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safe Area Top Padding
            SizedBox(height: MediaQuery.paddingOf(context).top + 10.0),

            // Heading: Settings matching settings.png
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 14.0),
              child: Text(
                'Settings',
                style: AppTypography.h1.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // PLAYBACK
            _buildSectionHeader(colors, 'PLAYBACK'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSectionItem(
                context: context,
                colors: colors,
                icon: Icon(
                  Icons.play_arrow_rounded,
                  color: colors.accent,
                  size: 24.0,
                ),
                title: 'Playback',
                subtitle: 'Resume, autoplay, queue and sleep timer',
                onTap: () => _navigateTo(RoutePaths.settingsPlayback),
              ),
            ),

            // NOTIFICATIONS
            _buildSectionHeader(colors, 'NOTIFICATIONS'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSectionItem(
                context: context,
                colors: colors,
                icon: Icon(
                  Icons.notifications_outlined,
                  color: colors.accent,
                  size: 22.0,
                ),
                title: 'Notifications',
                subtitle: 'Notification permissions and system settings',
                onTap: () => _navigateTo(RoutePaths.settingsNotifications),
              ),
            ),

            // AUDIO
            _buildSectionHeader(colors, 'AUDIO'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSectionItem(
                context: context,
                colors: colors,
                icon: AudifiWaveIcon(color: colors.accent, size: 20.0),
                title: 'Audio',
                subtitle: 'Equalizer and track information',
                onTap: () => _navigateTo(RoutePaths.settingsAudio),
              ),
            ),

            // MUSIC
            _buildSectionHeader(colors, 'MUSIC'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSectionItem(
                context: context,
                colors: colors,
                icon: AudifiLibraryIcon(color: colors.accent, size: 20.0),
                title: 'Music',
                subtitle: 'Clear favorites, history and cache',
                onTap: () => _navigateTo(RoutePaths.settingsMusic),
              ),
            ),

            // APPEARANCE
            _buildSectionHeader(colors, 'APPEARANCE'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSectionItem(
                context: context,
                colors: colors,
                icon: Icon(
                  Icons.palette_rounded,
                  color: colors.accent,
                  size: 22.0,
                ),
                title: 'Appearance',
                subtitle: 'Theme, colors and animations',
                onTap: () => _navigateTo(RoutePaths.settingsAppearance),
              ),
            ),

            // PRIVACY
            _buildSectionHeader(colors, 'PRIVACY'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSectionItem(
                context: context,
                colors: colors,
                icon: Icon(
                  Icons.lock_rounded,
                  color: colors.accent,
                  size: 20.0,
                ),
                title: 'Privacy',
                subtitle: 'Data storage and disclosures',
                onTap: () => _navigateTo(RoutePaths.settingsPrivacy),
              ),
            ),

            // ABOUT
            _buildSectionHeader(colors, 'ABOUT'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildSectionItem(
                context: context,
                colors: colors,
                icon: Icon(
                  Icons.info_rounded,
                  color: colors.accent,
                  size: 22.0,
                ),
                title: 'About',
                subtitle: 'Version and licenses',
                onTap: () => _navigateTo(RoutePaths.settingsAbout),
              ),
            ),

            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AudifiThemeColors colors, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 6.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.0,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: colors.textMuted,
        ),
      ),
    );
  }
}
