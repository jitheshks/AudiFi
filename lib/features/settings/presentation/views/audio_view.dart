import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/audifi_card.dart';
import '../../../playback/presentation/controllers/playback_controller.dart';
import '../../../playback/presentation/widgets/now_playing/audio_info_sheet.dart';

/// Full-screen Audio settings page adhering strictly to the Appearance reference design.
/// Only contains genuine, functional audio features supported by AudiFi.
class AudioView extends ConsumerWidget {
  const AudioView({super.key});

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

              // Heading: Audio
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                child: Text(
                  'Audio',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Section: AUDIO INFORMATION
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Text(
                  'AUDIO INFORMATION',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // Card 1: Audio Information drill-down
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: InkWell(
                  onTap: () {
                    final currentTrack = ref
                        .read(playbackControllerProvider)
                        .currentTrack;
                    if (currentTrack != null) {
                      AudioInfoSheet.show(context, track: currentTrack);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Start playing a track to view audio details',
                          ),
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
                                'Audio information',
                                style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                'See streaming specs, bitrate and output devices',
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

              // Section: STREAMING QUALITY
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  'STREAMING QUALITY',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // Card 2: Streaming Quality (supported specs)
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
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
                              'Streaming Quality',
                              style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              'High Definition (320 kbps MP3)',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          '320 kbps',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: colors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Icon(
                        Icons.check_rounded,
                        color: colors.accent,
                        size: 20.0,
                      ),
                    ],
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
