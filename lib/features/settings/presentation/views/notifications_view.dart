import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/permissions/permission_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/audifi_button.dart';
import '../../../../shared/widgets/audifi_card.dart';

/// Full-screen Notifications settings page adhering strictly to the Appearance reference design.
/// Displays genuine OS notification permission status and launches system notification settings.
class NotificationsView extends ConsumerStatefulWidget {
  const NotificationsView({super.key});

  @override
  ConsumerState<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends ConsumerState<NotificationsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationPermissionControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final permissionAsync = ref.watch(notificationPermissionControllerProvider);

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

              // Heading: Notifications
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Section: PERMISSION STATUS
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Text(
                  'PERMISSION STATUS',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // Card 1: Permission Status
              AudifiCard(
                padding: const EdgeInsets.all(16.0),
                hasShadow: false,
                child: permissionAsync.when(
                  loading: () => const SizedBox(
                    height: 80.0,
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                  error: (error, _) => Text(
                    'Unable to query system permissions: $error',
                    style: TextStyle(color: colors.error, fontSize: 13.0),
                  ),
                  data: (status) {
                    final isGranted = status.isGranted;
                    final isPermanentlyDenied = status.isPermanentlyDenied;
                    final isDenied = status.isDenied;
                    final isRestricted = status.isRestricted;

                    final String statusLabel;
                    final String statusDescription;
                    final IconData statusIcon;
                    final Color statusColor;

                    if (isGranted) {
                      statusLabel = 'Allowed';
                      statusDescription = 'Notifications are allowed. System media controls and download alerts are enabled.';
                      statusIcon = Icons.check_circle_rounded;
                      statusColor = colors.accent;
                    } else if (isPermanentlyDenied) {
                      statusLabel = 'Not allowed';
                      statusDescription = 'Notifications are disabled in system settings. Media controls may not appear in the notification drawer or lock screen.';
                      statusIcon = Icons.notifications_off_rounded;
                      statusColor = colors.textMuted;
                    } else if (isDenied) {
                      statusLabel = 'Not allowed';
                      statusDescription = 'Notification permission has not yet been granted. Allow notifications to display system media playback controls and download progress.';
                      statusIcon = Icons.notifications_none_rounded;
                      statusColor = colors.textMuted;
                    } else if (isRestricted) {
                      statusLabel = 'Restricted';
                      statusDescription = 'Notifications are restricted by device management or system policy.';
                      statusIcon = Icons.block_rounded;
                      statusColor = colors.textMuted;
                    } else {
                      statusLabel = 'Available through system settings';
                      statusDescription = 'Notifications are managed directly by operating system settings.';
                      statusIcon = Icons.notifications_outlined;
                      statusColor = colors.accent;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                statusIcon,
                                color: statusColor,
                                size: 22.0,
                              ),
                            ),
                            const SizedBox(width: 14.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notification Permission',
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isGranted
                                          ? colors.accent.withValues(alpha: 0.2)
                                          : colors.surface2,
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: isGranted
                                            ? colors.accent
                                            : colors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          statusDescription,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: colors.textMuted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        if (isDenied && !isPermanentlyDenied) ...[
                          AudifiButton(
                            text: 'Enable Notifications',
                            variant: AudifiButtonVariant.primary,
                            icon: const Icon(
                              Icons.notifications_active_rounded,
                              size: 18.0,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              final notifier = ref.read(
                                notificationPermissionControllerProvider
                                    .notifier,
                              );
                              final res = await notifier.request();
                              if (res.isPermanentlyDenied && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Notifications are disabled in system settings.',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Settings',
                                      onPressed: () =>
                                          notifier.openNotificationSettings(),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10.0),
                          AudifiButton(
                            text: 'Open Notification Settings',
                            variant: AudifiButtonVariant.secondary,
                            icon: Icon(
                              Icons.tune_rounded,
                              size: 18.0,
                              color: colors.textPrimary,
                            ),
                            onPressed: () => ref
                                .read(
                                  notificationPermissionControllerProvider
                                      .notifier,
                                )
                                .openNotificationSettings(),
                          ),
                        ] else ...[
                          AudifiButton(
                            text: 'Open Notification Settings',
                            variant: isGranted
                                ? AudifiButtonVariant.secondary
                                : AudifiButtonVariant.primary,
                            icon: Icon(
                              Icons.tune_rounded,
                              size: 18.0,
                              color: isGranted
                                  ? colors.textPrimary
                                  : Colors.white,
                            ),
                            onPressed: () => ref
                                .read(
                                  notificationPermissionControllerProvider
                                      .notifier,
                                )
                                .openNotificationSettings(),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // Section: PLAYBACK NOTIFICATION
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  'PLAYBACK NOTIFICATION',
                  style: TextStyle(
                    fontSize: 12.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),

              // Card 2: Playback Notification Information
              AudifiCard(
                padding: const EdgeInsets.all(16.0),
                hasShadow: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38.0,
                          height: 38.0,
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(11.0),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: colors.accent,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Media Controls',
                                style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                'Lock screen controls & notification drawer',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Playback notifications provide music controls and playback information while music is playing in the background.',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: colors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: colors.surface2.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16.0,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Android manages notification display and lock-screen visibility through system settings.',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: colors.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
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
