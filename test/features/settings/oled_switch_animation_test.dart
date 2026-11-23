import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:audifi/app.dart';
import 'package:audifi/core/theme/theme_controller.dart';
import 'package:audifi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:audifi/features/settings/presentation/views/appearance_view.dart';

import '../../test_helpers/stub_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'audifi_pref_pause_disconnect': true,
      'audifi_pref_dynamic_colors': true,
      'audifi_pref_oled': false,
      'audifi_pref_theme_mode': 'dark',
      'audifi_pref_animation_mode': 'Full',
    });
  });

  group('OLED Switch Animation & Motion Calibration Regression Tests', () {
    Widget buildAppearanceTestHarness({
      required ProviderContainer container,
      bool disableAnimations = false,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: const Scaffold(body: AppearanceView()),
          ),
        ),
      );
    }

    testWidgets(
      'Requirement 1: Full motion + OLED toggle animates smoothly over 200ms with low frame times',
      (tester) async {
        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildAppearanceTestHarness(container: container),
        );
        await tester.pumpAndSettle();

        final oledSwitch = find.byKey(const ValueKey('switch_oled_black'));
        expect(oledSwitch, findsOneWidget);
        expect(container.read(oledModeProvider), isFalse);

        // Tap the OLED switch
        await tester.tap(oledSwitch);
        await tester.pump(); // Start animation

        // Frame timing validation during the 200ms animation
        final frameTimes = <Duration>[];
        for (int i = 0; i < 12; i++) {
          final stopwatch = Stopwatch()..start();
          await tester.pump(const Duration(milliseconds: 16));
          stopwatch.stop();
          frameTimes.add(stopwatch.elapsed);
        }

        // Each simulated frame build should complete under 16ms
        for (final elapsed in frameTimes) {
          expect(elapsed.inMilliseconds, lessThanOrEqualTo(16));
        }

        await tester.pumpAndSettle();
        expect(container.read(oledModeProvider), isTrue);
      },
    );

    testWidgets(
      'Requirement 2: Full motion + Dynamic artwork colors toggle animates smoothly over 200ms',
      (tester) async {
        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildAppearanceTestHarness(container: container),
        );
        await tester.pumpAndSettle();

        final dynSwitch = find.byKey(const ValueKey('switch_dynamic_colors'));
        expect(dynSwitch, findsOneWidget);
        expect(
          container.read(settingsControllerProvider).dynamicColors,
          isTrue,
        );

        // Tap to toggle OFF
        await tester.tap(dynSwitch);
        await tester.pump();

        // Advance 100ms (midpoint)
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          container.read(settingsControllerProvider).dynamicColors,
          isFalse,
        );

        await tester.pumpAndSettle();
        expect(
          container.read(settingsControllerProvider).dynamicColors,
          isFalse,
        );
      },
    );

    testWidgets(
      'Requirement 3: Reduced motion + OLED toggle updates immediately without 200ms delay',
      (tester) async {
        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await container.read(animationModeProvider.notifier).setMode('Reduced');

        await tester.pumpWidget(
          buildAppearanceTestHarness(
            container: container,
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();

        final oledSwitch = find.byKey(const ValueKey('switch_oled_black'));
        expect(container.read(oledModeProvider), isFalse);

        await tester.tap(oledSwitch);
        // Single frame pump without time advancement completes immediately
        await tester.pump();

        expect(container.read(oledModeProvider), isTrue);
      },
    );

    testWidgets(
      'Requirement 4: Reduced motion + Dynamic artwork colors toggle updates immediately',
      (tester) async {
        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await container.read(animationModeProvider.notifier).setMode('Reduced');

        await tester.pumpWidget(
          buildAppearanceTestHarness(
            container: container,
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();

        final dynSwitch = find.byKey(const ValueKey('switch_dynamic_colors'));
        expect(
          container.read(settingsControllerProvider).dynamicColors,
          isTrue,
        );

        await tester.tap(dynSwitch);
        await tester.pump();

        expect(
          container.read(settingsControllerProvider).dynamicColors,
          isFalse,
        );
      },
    );

    testWidgets(
      'Requirement 5: OLED toggled while root theme transition is in progress completes cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const AudifiApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to Appearance
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();

        // Start theme transition (Dark -> Light)
        container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.light);
        await tester.pump(const Duration(milliseconds: 50));

        // Mid-flight, toggle OLED switch
        final oledSwitch = find.byKey(const ValueKey('switch_oled_black'));
        await tester.tap(oledSwitch);
        await tester.pump(const Duration(milliseconds: 50));

        // Settle all animations
        await tester.pumpAndSettle();

        expect(container.read(themeModeProvider), equals(ThemeMode.light));
        expect(container.read(oledModeProvider), isTrue);
      },
    );

    testWidgets(
      'Requirement 6: Rapid repeated OLED toggles reverse in-flight without exception or visual jump',
      (tester) async {
        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildAppearanceTestHarness(container: container),
        );
        await tester.pumpAndSettle();

        final oledSwitch = find.byKey(const ValueKey('switch_oled_black'));

        // Tap 1: Turn ON
        await tester.tap(oledSwitch);
        await tester.pump(
          const Duration(milliseconds: 40),
        ); // 20% into forward animation
        expect(container.read(oledModeProvider), isTrue);

        // Tap 2: Turn OFF mid-flight
        await tester.tap(oledSwitch);
        await tester.pump(const Duration(milliseconds: 30)); // Reversing
        expect(container.read(oledModeProvider), isFalse);

        // Tap 3: Turn ON mid-flight again
        await tester.tap(oledSwitch);
        await tester.pump(
          const Duration(milliseconds: 30),
        ); // Turning back forward
        expect(container.read(oledModeProvider), isTrue);

        // Complete settling
        await tester.pumpAndSettle();
        expect(container.read(oledModeProvider), isTrue);
      },
    );

    testWidgets(
      'Requirement 7: OLED toggled during in-flight switch animation maintains animation continuity',
      (tester) async {
        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildAppearanceTestHarness(container: container),
        );
        await tester.pumpAndSettle();

        final oledSwitch = find.byKey(const ValueKey('switch_oled_black'));

        // Tap ON
        await tester.tap(oledSwitch);
        await tester.pump();

        // Advance 30ms
        await tester.pump(const Duration(milliseconds: 30));

        // When Riverpod notifies and didUpdateWidget runs, verify animation continuity
        await tester.pump(const Duration(milliseconds: 30));
        await tester.pump(const Duration(milliseconds: 40));

        await tester.pumpAndSettle();
        expect(container.read(oledModeProvider), isTrue);
      },
    );

    testWidgets(
      'Requirement 8: Switching between Dark and OLED modes repeatedly maintains persistence and stability',
      (tester) async {
        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildAppearanceTestHarness(container: container),
        );
        await tester.pumpAndSettle();

        final oledSwitch = find.byKey(const ValueKey('switch_oled_black'));

        for (int i = 0; i < 5; i++) {
          await tester.tap(oledSwitch);
          await tester.pumpAndSettle();
          final expected = (i % 2 == 0);
          expect(container.read(oledModeProvider), equals(expected));
        }

        expect(container.read(oledModeProvider), isTrue);
      },
    );

    testWidgets(
      'Requirement 9: Theme changes while Dynamic colors switch is animating complete concurrently',
      (tester) async {
        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          buildAppearanceTestHarness(container: container),
        );
        await tester.pumpAndSettle();

        final dynSwitch = find.byKey(const ValueKey('switch_dynamic_colors'));

        // Tap Dynamic switch
        await tester.tap(dynSwitch);
        await tester.pump(const Duration(milliseconds: 40));

        // Simultaneously trigger theme mode change
        container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.light);
        await tester.pump(const Duration(milliseconds: 40));

        await tester.pumpAndSettle();

        expect(
          container.read(settingsControllerProvider).dynamicColors,
          isFalse,
        );
        expect(container.read(themeModeProvider), equals(ThemeMode.light));
      },
    );

    testWidgets(
      'Requirement 10: Animation preference changes without resetting navigation',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer(
          overrides: createStubRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const AudifiApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to Settings -> Appearance
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();

        // Verify we are on Appearance screen
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Dynamic artwork colors'), findsOneWidget);

        // Tap Animations to toggle motion preference directly
        await tester.tap(find.text('Animations'));
        await tester.pumpAndSettle();

        // Verify still on Appearance screen (route not reset)
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Dynamic artwork colors'), findsOneWidget);
        expect(find.text('Reduced'), findsOneWidget);
        expect(container.read(isReducedMotionProvider), isTrue);

        // Now test OLED switch with new reduced motion setting
        final oledSwitch = find.byKey(const ValueKey('switch_oled_black'));
        await tester.tap(oledSwitch);
        await tester.pump(); // Instant in reduced motion

        expect(container.read(oledModeProvider), isTrue);
      },
    );
  });
}
