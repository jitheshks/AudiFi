import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/audifi_card.dart';

/// Full-screen About settings page adhering strictly to the Appearance reference design.
/// Displays application identity, version, clear Audius protocol attribution,
/// and Flutter-provided third-party component licenses without duplicate privacy navigation.
class AboutView extends ConsumerWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

              // Back button "‹ Settings" matching Appearance reference
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: 'Back to Settings',
                  child: InkWell(
                    onTap: () {
                      if (context.canPop()) context.pop();
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48.0,
                        minWidth: 48.0,
                      ),
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
              ),

              // Heading: About
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Section: APPLICATION
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  child: Text(
                    'APPLICATION',
                    style: TextStyle(
                      fontSize: 12.0,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),

              // Card 1: Branding, Version, Description, and Attribution
              AudifiCard(
                padding: const EdgeInsets.all(20.0),
                hasShadow: false,
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 64.0,
                        height: 64.0,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white,
                          size: 36.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'AudiFi',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Version 1.0.0 (Build 1)',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'An independent music client for discovering and streaming music through the Audius protocol.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.0,
                        color: colors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Divider(
                      color: colors.surface2.withValues(alpha: 0.6),
                      height: 1.0,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'AudiFi is an independent third-party application powered by the Audius protocol. It is not affiliated with, sponsored by, or endorsed by Audius.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: colors.textMuted.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Section: LEGAL & LICENSES
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                  child: Text(
                    'LEGAL & LICENSES',
                    style: TextStyle(
                      fontSize: 12.0,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),

              // Card 2: Third-party licenses row
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: Semantics(
                  button: true,
                  label: 'Third-party licenses',
                  child: InkWell(
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'AudiFi',
                        applicationVersion: '1.0.0 (Build 1)',
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 48.0,
                            height: 48.0,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: const Icon(
                              Icons.graphic_eq_rounded,
                              color: Colors.white,
                              size: 28.0,
                            ),
                          ),
                        ),
                      );
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
                                  'Third-party licenses',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  'Software notices and licenses for included libraries',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: colors.textMuted,
                                  ),
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
                ),
              ),

              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
