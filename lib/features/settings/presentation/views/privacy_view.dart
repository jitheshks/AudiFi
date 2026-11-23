import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/external_launcher.dart';
import '../../../../shared/widgets/audifi_card.dart';

/// Full-screen Privacy Policy settings page adhering strictly to the Appearance reference design.
/// Dedicated exclusively to verified data-handling transparency, local storage isolation,
/// Audius decentralized protocol communication, verified absence of tracking, and access
/// to the canonical online privacy policy.
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

              // Heading: Privacy Policy
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                  child: Text(
                    'Privacy Policy',
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

              // Card 1: Data storage and privacy transparency disclosures
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: Column(
                  children: [
                    // Row 1: On-device data storage
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

                    // Row 2: Audius services
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
                                    'Audius services',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    'Music discovery and streaming use the public Audius API and protocol. AudiFi does not require an account, registration, or user authentication. Requests to Audius services are necessary for online music discovery and streaming, and those independent services may receive standard network request information.',
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

                    // Row 3: Zero analytics & tracking
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
                                    'AudiFi contains no analytics SDKs, advertising frameworks, tracking code, or user telemetry.',
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

              // Section: ONLINE POLICY
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                  child: Text(
                    'ONLINE POLICY',
                    style: TextStyle(
                      fontSize: 12.0,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),

              // Card 2: View Privacy Policy Online action
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: Semantics(
                  button: true,
                  label: 'View Privacy Policy Online',
                  child: InkWell(
                    onTap: () async {
                      final launched = await ExternalLauncher.launchUrl(
                        ApiConstants.privacyPolicyUrl,
                      );
                      if (!launched && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Unable to open privacy policy in browser.',
                            ),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
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
                                  'View Privacy Policy Online',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  'Open complete policy document in browser',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            color: colors.accent,
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
