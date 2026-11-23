import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/audifi_card.dart';
import '../../../../shared/widgets/audifi_switch.dart';
import '../../../playback/presentation/controllers/sleep_timer_controller.dart';
import '../../../playback/presentation/widgets/now_playing/sleep_timer_sheet.dart';
import '../controllers/settings_controller.dart';

/// Full-screen Playback settings page adhering strictly to the Appearance reference design.
class PlaybackView extends ConsumerWidget {
  const PlaybackView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final settings = ref.watch(settingsControllerProvider);

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

              // Heading: Playback
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                child: Text(
                  'Playback',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Section: AUDIO BEHAVIOR
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Text(
                  'AUDIO BEHAVIOR',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // Settings Card: Headphone disconnect & Mobile data
              AudifiCard(
                padding: EdgeInsets.zero,
                hasShadow: false,
                child: Column(
                  children: [
                    Container(
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
                                  'Pause when headphones disconnect',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  'Pause music when headphones or Bluetooth devices disconnect.',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          AudifiSwitch(
                            value: settings.pauseOnHeadphonesDisconnect,
                            semanticLabel: 'Pause when headphones disconnect',
                            onChanged: (val) {
                              ref
                                  .read(settingsControllerProvider.notifier)
                                  .setPauseOnHeadphonesDisconnect(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: colors.surface2.withValues(alpha: 0.6),
                      height: 1.0,
                    ),
                    Container(
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
                                  'Stream on mobile data',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  'Allow music streaming when not connected to Wi-Fi.',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          AudifiSwitch(
                            value: settings.streamOnMobileData,
                            semanticLabel: 'Stream on mobile data',
                            onChanged: (val) {
                              ref
                                  .read(settingsControllerProvider.notifier)
                                  .setStreamOnMobileData(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Section: SLEEP TIMER
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  'SLEEP TIMER',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // Sleep Timer Card
              Consumer(
                builder: (context, ref, _) {
                  final sleep = ref.watch(sleepTimerProvider);
                  return AudifiCard(
                    padding: EdgeInsets.zero,
                    hasShadow: false,
                    child: InkWell(
                      onTap: () => SleepTimerSheet.show(context),
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
                                    'Sleep timer',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    sleep.isActive
                                        ? 'Pauses playback in ${sleep.formattedRemaining}'
                                        : 'Automatically stop playback after a selected time.',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      color: sleep.isActive
                                          ? colors.accent
                                          : colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (sleep.isActive) ...[
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
                                  sleep.formattedRemaining,
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: colors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                            ],
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
                },
              ),

              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
