import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/audifi_card.dart';

/// Full-screen Privacy settings page adhering strictly to the Appearance reference design.
/// Dedicated exclusively to data-handling transparency, local storage isolation,
/// Audius decentralized protocol communication, and verified absence of tracking.
class PrivacyView extends ConsumerWidget {
  const PrivacyView({super.key});

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

              // Heading: Privacy
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                  child: Text(
                    'Privacy',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Section: DATA & PRIVACY
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  child: Text(
                    'DATA & PRIVACY',
                    style: TextStyle(
                      fontSize: 12.0,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),

              // Card: Data storage and privacy transparency
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: Column(
                  children: [
                    // Row 1: Local Data Storage
                    MergeSemantics(
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
                                    'On-device data storage',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    'Favorites, custom playlists, listening history, and search history are stored locally on your device.',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ExcludeSemantics(
                              child: Icon(
                                Icons.phone_android_rounded,
                                color: colors.accent,
                                size: 20.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      color: colors.surface2.withValues(alpha: 0.6),
                      height: 1.0,
                    ),

                    // Row 2: Audius Protocol Communication
                    MergeSemantics(
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
                                    'Decentralized Audius protocol',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    'Music discovery and streaming use the public Audius API. AudiFi is an independent client and does not require an account or authentication.',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ExcludeSemantics(
                              child: Icon(
                                Icons.public_rounded,
                                color: colors.accent,
                                size: 20.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      color: colors.surface2.withValues(alpha: 0.6),
                      height: 1.0,
                    ),

                    // Row 3: Zero Analytics & Tracking
                    MergeSemantics(
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
                                    'Zero analytics & tracking',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    'AudiFi contains no analytics SDKs, advertising frameworks, or user telemetry.',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ExcludeSemantics(
                              child: Icon(
                                Icons.verified_user_rounded,
                                color: colors.accent,
                                size: 20.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
