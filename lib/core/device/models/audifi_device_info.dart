/// Supported platforms for AudiFi.
enum AudifiPlatformType { android, ios, linux, macos, windows, web, unknown }

/// An application-owned device information model.
///
/// Contains only non-sensitive hardware and operating system metadata required
/// for platform-adaptive behavior, UI disclosures, and capability detection.
/// Never collects, stores, or transmits personal identifiers or hardware IDs.
class AudifiDeviceInfo {
  final AudifiPlatformType platform;
  final String model;
  final String manufacturer;
  final String osVersion;
  final int? sdkInt;
  final bool isPhysicalDevice;

  const AudifiDeviceInfo({
    required this.platform,
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    this.sdkInt,
    required this.isPhysicalDevice,
  });

  /// Fallback device info when platform querying fails or is unsupported.
  const AudifiDeviceInfo.unknown()
    : platform = AudifiPlatformType.unknown,
      model = 'Unknown Device',
      manufacturer = 'Unknown',
      osVersion = 'Unknown OS',
      sdkInt = null,
      isPhysicalDevice = true;

  bool get isAndroid => platform == AudifiPlatformType.android;
  bool get isIos => platform == AudifiPlatformType.ios;
  bool get isWeb => platform == AudifiPlatformType.web;
  bool get isDesktop =>
      platform == AudifiPlatformType.linux ||
      platform == AudifiPlatformType.macos ||
      platform == AudifiPlatformType.windows;

  /// Human-friendly display string combining manufacturer and model when distinct.
  String get displayDeviceName {
    if (model.isEmpty || model.toLowerCase() == 'unknown device') {
      return manufacturer.isNotEmpty && manufacturer.toLowerCase() != 'unknown'
          ? manufacturer
          : 'Generic Device';
    }
    if (manufacturer.isNotEmpty &&
        manufacturer.toLowerCase() != 'unknown' &&
        !model.toLowerCase().contains(manufacturer.toLowerCase())) {
      return '$manufacturer $model';
    }
    return model;
  }

  /// Compact one-line summary (e.g. "Xiaomi 25053PC47I • Android 16 (API 36)").
  String get summary => '$displayDeviceName • $osVersion';

  AudifiDeviceInfo copyWith({
    AudifiPlatformType? platform,
    String? model,
    String? manufacturer,
    String? osVersion,
    int? sdkInt,
    bool? isPhysicalDevice,
  }) {
    return AudifiDeviceInfo(
      platform: platform ?? this.platform,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      osVersion: osVersion ?? this.osVersion,
      sdkInt: sdkInt ?? this.sdkInt,
      isPhysicalDevice: isPhysicalDevice ?? this.isPhysicalDevice,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudifiDeviceInfo &&
          runtimeType == other.runtimeType &&
          platform == other.platform &&
          model == other.model &&
          manufacturer == other.manufacturer &&
          osVersion == other.osVersion &&
          sdkInt == other.sdkInt &&
          isPhysicalDevice == other.isPhysicalDevice;

  @override
  int get hashCode => Object.hash(
    platform,
    model,
    manufacturer,
    osVersion,
    sdkInt,
    isPhysicalDevice,
  );

  @override
  String toString() =>
      'AudifiDeviceInfo(platform: $platform, model: $model, manufacturer: $manufacturer, osVersion: $osVersion, sdkInt: $sdkInt, isPhysicalDevice: $isPhysicalDevice)';
}
