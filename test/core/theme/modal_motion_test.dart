import 'package:audifi/core/theme/app_motion.dart';
import 'package:audifi/core/theme/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppMotion Modal & Dialog Transitions', () {
    test('modalAnimationStyle returns 300ms durationMedium in Full Motion', () {
      final style = AppMotion.modalAnimationStyle(isReduced: false);
      expect(style.duration, AppMotion.durationMedium);
      expect(style.reverseDuration, AppMotion.durationMedium);
      expect(style.curve, AppMotion.curveDecelerate);
      expect(style.reverseCurve, AppMotion.curveAccelerate);
    });

    test('modalAnimationStyle returns noAnimation in Reduced Motion', () {
      final style = AppMotion.modalAnimationStyle(isReduced: true);
      expect(style.duration, Duration.zero);
      expect(style.reverseDuration, Duration.zero);
    });

    testWidgets(
      'showModalSheet animates with durationMedium (300ms) in Full Motion',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [isReducedMotionProvider.overrideWithValue(false)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      AppMotion.showModalSheet<void>(
                        context: context,
                        builder: (ctx) => const SizedBox(
                          height: 200,
                          child: Text('Modal Content'),
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Open sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pump();

        // 150ms mid-way: animating
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.hasRunningAnimations, isTrue);

        // Settle sheet
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.text('Modal Content'), findsOneWidget);

        // Close sheet (tap scrim)
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.hasRunningAnimations, isTrue);

        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.text('Modal Content'), findsNothing);
      },
    );

    testWidgets(
      'showModalSheet opens instantly without animation in Reduced Motion',
      (tester) async {
        final sheetKey = UniqueKey();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [isReducedMotionProvider.overrideWithValue(true)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      AppMotion.showModalSheet<void>(
                        context: context,
                        builder: (ctx) => SizedBox(
                          key: sheetKey,
                          height: 200,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Open sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pump();

        // Under Reduced Motion (noAnimation), sheet is immediately mounted on the single frame
        expect(find.byKey(sheetKey), findsOneWidget);

        // Close sheet
        await tester.tap(find.text('Close'));
        await tester.pump();
        expect(find.byKey(sheetKey), findsNothing);
      },
    );

    testWidgets(
      'showAppDialog animates in Full Motion and opens instantly in Reduced Motion',
      (tester) async {
        // Full Motion
        await tester.pumpWidget(
          ProviderScope(
            overrides: [isReducedMotionProvider.overrideWithValue(false)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      AppMotion.showAppDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Dialog Title'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.hasRunningAnimations, isTrue);

        await tester.pumpAndSettle();
        expect(find.text('Dialog Title'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Dialog Title'), findsNothing);

        // Reduced Motion
        final dialogKey = UniqueKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [isReducedMotionProvider.overrideWithValue(true)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      AppMotion.showAppDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          key: dialogKey,
                          title: const Text('Dialog Title'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pump();
        expect(find.byKey(dialogKey), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pump();
        expect(find.byKey(dialogKey), findsNothing);
      },
    );
  });
}
