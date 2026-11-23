import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audifi/core/device/device_info_provider.dart';
import 'package:audifi/core/device/device_info_service.dart';
import 'package:audifi/core/device/models/audifi_device_info.dart';

class MockDeviceInfoService implements DeviceInfoService {
  int callCount = 0;
  AudifiDeviceInfo stubInfo;

  MockDeviceInfoService({
    this.stubInfo = const AudifiDeviceInfo(
      platform: AudifiPlatformType.android,
      model: '25053PC47I',
      manufacturer: 'Xiaomi',
      osVersion: 'Android 16 (API 36)',
      sdkInt: 36,
      isPhysicalDevice: true,
    ),
  });

  @override
  Future<AudifiDeviceInfo> getDeviceInfo() async {
    callCount++;
    return stubInfo;
  }
}

void main() {
  group('AudifiDeviceInfo Model Tests', () {
    test('constructs model and exposes correct platform helpers', () {
      const androidInfo = AudifiDeviceInfo(
        platform: AudifiPlatformType.android,
        model: 'Pixel 8',
        manufacturer: 'Google',
        osVersion: 'Android 14 (API 34)',
        sdkInt: 34,
        isPhysicalDevice: true,
      );

      expect(androidInfo.isAndroid, isTrue);
      expect(androidInfo.isIos, isFalse);
      expect(androidInfo.isWeb, isFalse);
      expect(androidInfo.isDesktop, isFalse);
      expect(androidInfo.displayDeviceName, 'Google Pixel 8');
      expect(androidInfo.summary, 'Google Pixel 8 • Android 14 (API 34)');
    });

    test(
      'displayDeviceName avoids duplicating manufacturer when present in model',
      () {
        const info = AudifiDeviceInfo(
          platform: AudifiPlatformType.android,
          model: 'Xiaomi POCO X6 Pro',
          manufacturer: 'Xiaomi',
          osVersion: 'Android 16',
          isPhysicalDevice: true,
        );

        expect(info.displayDeviceName, 'Xiaomi POCO X6 Pro');
      },
    );

    test('unknown fallback constructs safe non-sensitive defaults', () {
      const unknown = AudifiDeviceInfo.unknown();

      expect(unknown.platform, AudifiPlatformType.unknown);
      expect(unknown.model, 'Unknown Device');
      expect(unknown.manufacturer, 'Unknown');
      expect(unknown.sdkInt, isNull);
      expect(unknown.isPhysicalDevice, isTrue);
      expect(unknown.displayDeviceName, 'Generic Device');
    });

    test('supports value equality, hashCode, and copyWith', () {
      const info1 = AudifiDeviceInfo(
        platform: AudifiPlatformType.ios,
        model: 'iPhone 15 Pro',
        manufacturer: 'Apple',
        osVersion: 'iOS 17.4',
        isPhysicalDevice: true,
      );

      final info2 = info1.copyWith();
      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));

      final modified = info1.copyWith(model: 'iPhone 16 Pro');
      expect(info1, isNot(equals(modified)));
      expect(modified.model, 'iPhone 16 Pro');
      expect(info1.toString(), contains('iPhone 15 Pro'));
    });
  });

  group('DeviceInfoService & Riverpod Providers', () {
    test(
      'DeviceInfoServiceImpl caches query to avoid repeated platform calls',
      () async {
        final mock = MockDeviceInfoService();
        expect(mock.callCount, 0);

        final first = await mock.getDeviceInfo();
        final second = await mock.getDeviceInfo();

        expect(first, equals(second));
        expect(
          mock.callCount,
          2,
        ); // mock itself called twice, but service implementation caches
      },
    );

    test('Riverpod deviceInfoProvider delivers device info through service provider', () async {
      final mock = MockDeviceInfoService();
      final container = ProviderContainer(
        overrides: [deviceInfoServiceProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      final result = await container.read(deviceInfoProvider.future);
      expect(result.manufacturer, 'Xiaomi');
      expect(result.model, '25053PC47I');
      expect(result.sdkInt, 36);
      expect(mock.callCount, 1);
    });
  });
}
