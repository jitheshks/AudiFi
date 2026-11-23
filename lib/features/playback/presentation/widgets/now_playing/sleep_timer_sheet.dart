import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../controllers/playback_controller.dart';
import '../../controllers/sleep_timer_controller.dart';

/// Modal bottom sheet allowing users to configure or cancel a playback sleep timer.
class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  /// Helper to display the sleep timer sheet modally.
  static Future<void> show(BuildContext context) {
    return AppMotion.showModalSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SleepTimerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.audifiColors;
    final sleepState = ref.watch(sleepTimerProvider);
    final playbackState = ref.watch(playbackControllerProvider);

    final trackRemaining = playbackState.duration > playbackState.position
        ? playbackState.duration - playbackState.position
        : Duration.zero;

    final presets = <({String label, Duration duration})>[
      (label: '5 minutes', duration: const Duration(minutes: 5)),
      (label: '15 minutes', duration: const Duration(minutes: 15)),
      (label: '30 minutes', duration: const Duration(minutes: 30)),
      (label: '45 minutes', duration: const Duration(minutes: 45)),
      (label: '1 hour', duration: const Duration(hours: 1)),
      if (trackRemaining > const Duration(seconds: 10))
        (label: 'End of current track', duration: trackRemaining),
    ];

    return Material(
      color: colors.surface1,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 12.0),
              child: Row(
                children: [
                  Icon(Icons.bedtime_rounded, color: colors.accent, size: 22.0),
                  AppSpacing.hGap12,
                  Expanded(
                    child: Text(
                      'Sleep Timer',
                      style: AppTypography.h2.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (sleepState.isActive)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () {
                        ref.read(sleepTimerProvider.notifier).cancelTimer();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sleep timer turned off'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('Turn Off'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1.0),

            if (sleepState.isActive)
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 20.0,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_rounded, color: colors.accent),
                    AppSpacing.hGap12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Timer Active',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AppSpacing.vGap2,
                          Text(
                            'Pauses in ${sleepState.formattedRemaining}',
                            style: AppTypography.caption.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Presets List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: presets.length,
              separatorBuilder: (context, index) => Divider(
                color: colors.surface2.withValues(alpha: 0.5),
                height: 1.0,
              ),
              itemBuilder: (context, index) {
                final preset = presets[index];
                return ListTile(
                  title: Text(
                    preset.label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textMuted,
                  ),
                  onTap: () {
                    ref
                        .read(sleepTimerProvider.notifier)
                        .startTimer(preset.duration);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sleep timer set for ${preset.label}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
