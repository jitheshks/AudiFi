import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_info_service.dart';
import 'models/audifi_device_info.dart';

/// Provides access to the application's [DeviceInfoService] instance.
final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoServiceImpl();
});

/// Asynchronously loads and caches the platform's [AudifiDeviceInfo].
/// Because hardware metadata is static per session, this future caches safely.
final deviceInfoProvider = FutureProvider<AudifiDeviceInfo>((ref) async {
  final service = ref.watch(deviceInfoServiceProvider);
  return service.getDeviceInfo();
});
