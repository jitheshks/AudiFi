import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'models/audifi_device_info.dart';

/// Contract for retrieving platform and hardware metadata safely.
abstract interface class DeviceInfoService {
  /// Fetches platform-aware device information.
  /// Implementations should cache this data after the first successful lookup.
  Future<AudifiDeviceInfo> getDeviceInfo();
}

/// Production implementation of [DeviceInfoService] backed by `device_info_plus`.
class DeviceInfoServiceImpl implements DeviceInfoService {
  final DeviceInfoPlugin _plugin;
  AudifiDeviceInfo? _cachedInfo;

  DeviceInfoServiceImpl({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  @override
  Future<AudifiDeviceInfo> getDeviceInfo() async {
    if (_cachedInfo != null) {
      return _cachedInfo!;
    }

    try {
      if (kIsWeb) {
        final web = await _plugin.webBrowserInfo;
        _cachedInfo = AudifiDeviceInfo(
          platform: AudifiPlatformType.web,
          model: web.browserName.name,
          manufacturer: web.vendor ?? 'Browser',
          osVersion: web.userAgent ?? 'Web',
          isPhysicalDevice: true,
        );
      } else if (Platform.isAndroid) {
        final android = await _plugin.androidInfo;
        _cachedInfo = AudifiDeviceInfo(
          platform: AudifiPlatformType.android,
          model: android.model,
          manufacturer: android.manufacturer,
          osVersion:
              'Android ${android.version.release} (API ${android.version.sdkInt})',
          sdkInt: android.version.sdkInt,
          isPhysicalDevice: android.isPhysicalDevice,
        );
      } else if (Platform.isIOS) {
        final ios = await _plugin.iosInfo;
        _cachedInfo = AudifiDeviceInfo(
          platform: AudifiPlatformType.ios,
          model: ios.model,
          manufacturer: 'Apple',
          osVersion: '${ios.systemName} ${ios.systemVersion}',
          sdkInt: null,
          isPhysicalDevice: ios.isPhysicalDevice,
        );
      } else if (Platform.isLinux) {
        final linux = await _plugin.linuxInfo;
        _cachedInfo = AudifiDeviceInfo(
          platform: AudifiPlatformType.linux,
          model: linux.name,
          manufacturer: linux.id,
          osVersion: linux.versionId ?? 'Linux',
          sdkInt: null,
          isPhysicalDevice: true,
        );
      } else if (Platform.isMacOS) {
        final mac = await _plugin.macOsInfo;
        _cachedInfo = AudifiDeviceInfo(
          platform: AudifiPlatformType.macos,
          model: mac.model,
          manufacturer: 'Apple',
          osVersion: 'macOS ${mac.osRelease}',
          sdkInt: null,
          isPhysicalDevice: true,
        );
      } else if (Platform.isWindows) {
        final win = await _plugin.windowsInfo;
        _cachedInfo = AudifiDeviceInfo(
          platform: AudifiPlatformType.windows,
          model: win.productName,
          manufacturer: 'Microsoft',
          osVersion: 'Windows (Build ${win.buildNumber})',
          sdkInt: null,
          isPhysicalDevice: true,
        );
      } else {
        _cachedInfo = const AudifiDeviceInfo.unknown();
      }
    } catch (_) {
      _cachedInfo = const AudifiDeviceInfo.unknown();
    }

    return _cachedInfo!;
  }
}
