import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audifi/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'audifi_pref_pause_disconnect': true,
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state defaults to headphone disconnect enabled and dynamic colors on', () {
      final state = container.read(settingsControllerProvider);
      expect(state.pauseOnHeadphonesDisconnect, isTrue);
      expect(state.dynamicColors, isTrue);
      expect(state.streamQuality, equals('320 kbps (High)'));
    });

    test('setDynamicColors updates state and persists', () async {
      final controller = container.read(settingsControllerProvider.notifier);

      await controller.setDynamicColors(false);
      var state = container.read(settingsControllerProvider);
      expect(state.dynamicColors, isFalse);

      await controller.setDynamicColors(true);
      state = container.read(settingsControllerProvider);
      expect(state.dynamicColors, isTrue);
    });

    test('setPauseOnHeadphonesDisconnect updates state and persists', () async {
      final controller = container.read(settingsControllerProvider.notifier);

      await controller.setPauseOnHeadphonesDisconnect(false);
      var state = container.read(settingsControllerProvider);
      expect(state.pauseOnHeadphonesDisconnect, isFalse);

      await controller.setPauseOnHeadphonesDisconnect(true);
      state = container.read(settingsControllerProvider);
      expect(state.pauseOnHeadphonesDisconnect, isTrue);
    });
  });
}
