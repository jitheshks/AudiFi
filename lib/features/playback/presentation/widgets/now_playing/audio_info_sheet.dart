// ignore_for_file: experimental_member_use

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/device/device_info_provider.dart';
import '../../../../../core/network/network_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../downloads/presentation/controllers/download_controller.dart';
import '../../../../tracks/domain/entities/track.dart';
import 'sleep_timer_sheet.dart';

/// Bottom modal sheet displaying detailed audio technical metadata,
/// available output devices (including USB DAC / Bluetooth), and equalizer feasibility status.
/// Matches the Audio Information sheet in `references/UI/audifi.html`.
class AudioInfoSheet extends ConsumerStatefulWidget {
  const AudioInfoSheet({super.key, required this.track});

  final Track track;

  /// Convenience method to display the sheet modally.
  static Future<void> show(BuildContext context, {required Track track}) {
    return AppMotion.showModalSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AudioInfoSheet(track: track),
    );
  }

  @override
  ConsumerState<AudioInfoSheet> createState() => _AudioInfoSheetState();
}

class _AudioInfoSheetState extends ConsumerState<AudioInfoSheet> {
  String _availableOutputDevices = 'Detecting…';
  bool _isUsbDacDetected = false;

  @override
  void initState() {
    super.initState();
    _detectAudioDevices();
  }

  Future<void> _detectAudioDevices() async {
    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices(
        includeInputs: false,
        includeOutputs: true,
      );

      if (!mounted) return;

      if (devices.isEmpty) {
        setState(() {
          _availableOutputDevices = 'Built-in Speaker';
          _isUsbDacDetected = false;
        });
        return;
      }

      final descriptions = <String>[];
      bool usbFound = false;

      for (final d in devices) {
        switch (d.type) {
          case AudioDeviceType.usbAudio:
            usbFound = true;
            descriptions.add(
              d.name.isNotEmpty ? 'USB DAC (${d.name})' : 'USB DAC',
            );
          case AudioDeviceType.bluetoothA2dp:
          case AudioDeviceType.bluetoothSco:
            descriptions.add(
              d.name.isNotEmpty ? 'Bluetooth (${d.name})' : 'Bluetooth Audio',
            );
          case AudioDeviceType.wiredHeadphones:
          case AudioDeviceType.wiredHeadset:
            descriptions.add(
              d.name.isNotEmpty ? 'Wired (${d.name})' : 'Wired Headphones',
            );
          case AudioDeviceType.builtInSpeaker:
            descriptions.add('Built-in Speaker');
          case AudioDeviceType.builtInEarpiece:
            descriptions.add('Built-in Earpiece');
          case AudioDeviceType.lineAnalog:
          case AudioDeviceType.lineDigital:
            descriptions.add('Line Out');
          case AudioDeviceType.hdmi:
          case AudioDeviceType.hdmiArc:
            descriptions.add('HDMI Audio');
          default:
            if (d.name.isNotEmpty) {
              descriptions.add(d.name);
            }
        }
      }

      final distinctDescriptions = descriptions.toSet().toList();

      setState(() {
        _availableOutputDevices = distinctDescriptions.isNotEmpty
            ? distinctDescriptions.join(', ')
            : 'Default Audio';
        _isUsbDacDetected = usbFound;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _availableOutputDevices = 'Default Audio Output';
          _isUsbDacDetected = false;
        });
      }
    }
  }

  Widget _buildKeyValueRow(
    BuildContext context,
    String key,
    String value, {
    Color? valueColor,
    bool isHighlighted = false,
  }) {
    final colors = context.audifiColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130.0,
            child: Text(
              key.toUpperCase(),
              style: AppTypography.micro.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          AppSpacing.hGap12,
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                color: valueColor ?? colors.textPrimary,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.audifiColors;
    final isDownloaded = ref.watch(isTrackDownloadedProvider(widget.track.id));
    final downloadProgress = ref.watch(
      downloadProgressProvider(widget.track.id),
    );
    final permissionAsync = ref.watch(
      trackDownloadPermissionProvider(widget.track),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 32.0,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle matching .sheet .grab in audifi.html
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
              AppSpacing.vGap16,

              // Header
              Text(
                'Audio Information',
                style: AppTypography.h2.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.vGap4,
              Text(
                'Technical stream and playback output details.',
                style: AppTypography.caption.copyWith(color: colors.textMuted),
              ),
              AppSpacing.vGap16,

              // Track & Stream Specifications
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colors.surface2.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: colors.surface2.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    _buildKeyValueRow(context, 'Title', widget.track.title),
                    _buildKeyValueRow(
                      context,
                      'Artist',
                      widget.track.user?.name ?? 'Unknown Artist',
                    ),
                    _buildKeyValueRow(
                      context,
                      'Format',
                      'MP3 (Standard Audius Stream)',
                    ),
                    _buildKeyValueRow(
                      context,
                      'Quality',
                      '320 kbps, 48 kHz (Published Spec)',
                    ),
                    _buildKeyValueRow(
                      context,
                      'Delivery',
                      isDownloaded
                          ? 'Local Offline Storage (On Device)'
                          : 'HTTP Range Request (Progressive)',
                      valueColor: isDownloaded ? colors.accent : null,
                      isHighlighted: isDownloaded,
                    ),
                    _buildKeyValueRow(
                      context,
                      'Available Output Devices',
                      _availableOutputDevices,
                      valueColor: _isUsbDacDetected ? colors.accent : null,
                      isHighlighted: _isUsbDacDetected,
                    ),
                    _buildKeyValueRow(
                      context,
                      'Equalizer',
                      'System Default (Unaltered)',
                    ),
                    _buildKeyValueRow(
                      context,
                      'Device',
                      ref.watch(deviceInfoProvider).value?.displayDeviceName ??
                          'Detecting...',
                    ),
                    _buildKeyValueRow(
                      context,
                      'Network',
                      ref.watch(networkStateProvider).description,
                    ),
                  ],
                ),
              ),
              AppSpacing.vGap16,

              // Educational notes matching audifi.html and platform realities
              Text(
                'Audius streams are encoded as standard 320 kbps MP3 at 48 kHz per published Audius specifications. '
                'Android automatically routes media playback to connected USB DACs, Bluetooth devices, and headphones based on system audio policy. '
                'Hardware routing is managed by the Android OS; standard Android AudioTrack does not provide direct bit-perfect hardware takeover.',
                style: AppTypography.caption.copyWith(
                  color: colors.textMuted,
                  height: 1.4,
                ),
              ),
              AppSpacing.vGap24,

              // Download / Offline action button
              SizedBox(
                height: 48.0,
                child: isDownloaded
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                          side: BorderSide(
                            color: colors.error.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        icon: const Icon(
                          Icons.download_done_rounded,
                          size: 20.0,
                        ),
                        label: const Text('Remove Download'),
                        onPressed: () {
                          ref
                              .read(downloadControllerProvider.notifier)
                              .removeDownload(widget.track.id);
                        },
                      )
                    : (downloadProgress != null &&
                          downloadProgress.isDownloading)
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.accent,
                          side: BorderSide(
                            color: colors.accent.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        icon: SizedBox(
                          width: 16.0,
                          height: 16.0,
                          child: CircularProgressIndicator(
                            value: downloadProgress.progress > 0
                                ? downloadProgress.progress
                                : null,
                            strokeWidth: 2.0,
                            color: colors.accent,
                          ),
                        ),
                        label: Text(
                          'Downloading (${(downloadProgress.progress * 100).toInt()}%)... Cancel',
                        ),
                        onPressed: () {
                          ref
                              .read(downloadControllerProvider.notifier)
                              .cancelDownload(widget.track.id);
                        },
                      )
                    : permissionAsync.when(
                        data: (perm) {
                          if (perm.isAuthorized) {
                            return OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.accent,
                                side: BorderSide(
                                  color: colors.accent.withValues(alpha: 0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 20.0,
                              ),
                              label: const Text(
                                'Download for Offline Playback',
                              ),
                              onPressed: () {
                                ref
                                    .read(downloadControllerProvider.notifier)
                                    .downloadTrack(widget.track);
                              },
                            );
                          }
                          if (perm.isGated) {
                            return OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.textMuted,
                                side: BorderSide(color: colors.surface2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              icon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20.0,
                              ),
                              label: const Text('Download Gated'),
                              onPressed: null,
                            );
                          }
                          return OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textMuted,
                              side: BorderSide(color: colors.surface2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            icon: const Icon(
                              Icons.file_download_off_rounded,
                              size: 20.0,
                            ),
                            label: const Text('Download Unavailable'),
                            onPressed: null,
                          );
                        },
                        loading: () => OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textMuted,
                            side: BorderSide(color: colors.surface2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          icon: SizedBox(
                            width: 16.0,
                            height: 16.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: colors.textMuted,
                            ),
                          ),
                          label: const Text('Checking Permissions…'),
                          onPressed: null,
                        ),
                        error: (_, _) => OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textMuted,
                            side: BorderSide(color: colors.surface2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 20.0),
                          label: const Text('Retry Permission Check'),
                          onPressed: () => ref.refresh(
                            trackDownloadPermissionProvider(widget.track),
                          ),
                        ),
                      ),
              ),
              if (!isDownloaded &&
                  (downloadProgress == null ||
                      !downloadProgress.isDownloading) &&
                  permissionAsync.hasValue &&
                  !permissionAsync.value!.isAuthorized) ...[
                AppSpacing.vGap4,
                Text(
                  permissionAsync.value!.isGated
                      ? 'This download requires creator access.'
                      : "Downloads aren't available for this track.",
                  style: AppTypography.caption.copyWith(
                    color: colors.textMuted,
                    fontSize: 11.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              AppSpacing.vGap12,

              // Sleep timer button
              SizedBox(
                height: 48.0,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accent,
                    side: BorderSide(
                      color: colors.accent.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  icon: const Icon(Icons.bedtime_rounded, size: 20.0),
                  label: const Text('Sleep Timer'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    SleepTimerSheet.show(context);
                  },
                ),
              ),
              AppSpacing.vGap12,

              // Close button
              SizedBox(
                height: 48.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.surface2,
                    foregroundColor: colors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
