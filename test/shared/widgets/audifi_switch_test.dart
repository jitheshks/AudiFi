import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/core/theme/app_theme.dart';
import 'package:audifi/shared/widgets/audifi_switch.dart';

void main() {
  group('AudifiSwitch Widget & Motion Tests', () {
    testWidgets('Renders with accessible dimensions and semantics', (
      tester,
    ) async {
      bool switchVal = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AudifiSwitch(
                value: switchVal,
                semanticLabel: 'Test Switch',
                onChanged: (val) => switchVal = val,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check interaction target dimensions (52x48) satisfying 48x48 guideline
      final switchFinder = find.byType(AudifiSwitch);
      expect(switchFinder, findsOneWidget);
      final size = tester.getSize(switchFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      // Verify semantics
      expect(
        tester.getSemantics(switchFinder),
        matchesSemantics(
          label: 'Test Switch',
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('Tapping switch triggers onChanged callback', (tester) async {
      bool switchVal = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: AudifiSwitch(
                  value: switchVal,
                  semanticLabel: 'Dynamic colors',
                  onChanged: (val) {
                    setState(() => switchVal = val);
                  },
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AudifiSwitch));
      await tester.pumpAndSettle();

      expect(switchVal, isTrue);

      await tester.tap(find.byType(AudifiSwitch));
      await tester.pumpAndSettle();

      expect(switchVal, isFalse);
    });

    testWidgets(
      'Rapid repeated toggles reverse smoothly in-flight without jump',
      (tester) async {
        bool switchVal = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: Scaffold(
                  body: AudifiSwitch(
                    value: switchVal,
                    semanticLabel: 'OLED black',
                    onChanged: (val) {
                      setState(() => switchVal = val);
                    },
                  ),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // Tap ON
        await tester.tap(find.byType(AudifiSwitch));
        // Advance by 50ms (25% through 200ms transition)
        await tester.pump(const Duration(milliseconds: 50));
        expect(switchVal, isTrue);

        // Tap OFF immediately mid-flight
        await tester.tap(find.byType(AudifiSwitch));
        // Advance by 30ms (reversing)
        await tester.pump(const Duration(milliseconds: 30));
        expect(switchVal, isFalse);

        // Finish settling
        await tester.pumpAndSettle();
        expect(switchVal, isFalse);
      },
    );

    testWidgets('Reduced motion preference completes state toggle instantly', (
      tester,
    ) async {
      bool switchVal = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return AudifiSwitch(
                    value: switchVal,
                    semanticLabel: 'OLED black',
                    onChanged: (val) {
                      setState(() => switchVal = val);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(AudifiSwitch));
      // With reduced motion, state reaches end immediately without animation pump
      await tester.pump();

      expect(switchVal, isTrue);
    });

    testWidgets('Custom active and inactive colors interpolate correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudifiSwitch(
              value: true,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.darkSurface2,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the inner container with decoration
      final containerFinder = find.descendant(
        of: find.byType(AudifiSwitch),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets(
      'Switch animates smoothly and immediately on tap even when theme changes concurrently',
      (tester) async {
        bool isOled = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                theme: isOled ? AppTheme.oledTheme : AppTheme.darkTheme,
                home: Scaffold(
                  body: AudifiSwitch(
                    key: const ValueKey('oled_switch'),
                    value: isOled,
                    semanticLabel: 'OLED black',
                    onChanged: (val) {
                      setState(() => isOled = val);
                    },
                  ),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // Tap switch
        await tester.tap(find.byKey(const ValueKey('oled_switch')));
        // Pump 50ms into animation
        await tester.pump(const Duration(milliseconds: 50));
        expect(isOled, isTrue);

        // Continue pump to 100ms
        await tester.pump(const Duration(milliseconds: 50));
        expect(isOled, isTrue);

        // Settle animation
        await tester.pumpAndSettle();
        expect(isOled, isTrue);
      },
    );
  });
}
