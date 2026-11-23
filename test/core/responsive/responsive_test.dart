import 'package:audifi/core/responsive/responsive_breakpoints.dart';
import 'package:audifi/core/responsive/responsive_builder.dart';
import 'package:audifi/core/responsive/responsive_container.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('Responsive Breakpoints', () {
    testWidgets('identifies compact mobile for width 320', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      DeviceType? detectedType;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              detectedType = context.deviceType;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(detectedType, DeviceType.compactMobile);
    });

    testWidgets('identifies standard mobile for widths 360, 375, 390, 430', (
      tester,
    ) async {
      const mobileWidths = [360.0, 375.0, 390.0, 430.0];

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        DeviceType? detectedType;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                detectedType = context.deviceType;
                return const SizedBox();
              },
            ),
          ),
        );

        expect(detectedType, DeviceType.mobile);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('identifies tablet for width 600+', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      DeviceType? detectedType;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              detectedType = context.deviceType;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(detectedType, DeviceType.tablet);
    });
  });

  group('ResponsiveBuilder', () {
    testWidgets(
      'renders mobile layout on small widths and tablet layout on >= 600',
      (tester) async {
        Widget buildTestSubject() {
          return MaterialApp(
            home: ResponsiveBuilder(
              mobile: (context, constraints) => const Text('Mobile Content'),
              tablet: (context, constraints) => const Text('Tablet Content'),
            ),
          );
        }

        // Test mobile size
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestSubject());
        expect(find.text('Mobile Content'), findsOneWidget);
        expect(find.text('Tablet Content'), findsNothing);

        // Test tablet size
        tester.view.physicalSize = const Size(720, 1080);
        await tester.pumpWidget(buildTestSubject());
        expect(find.text('Tablet Content'), findsOneWidget);
        expect(find.text('Mobile Content'), findsNothing);

        tester.view.resetPhysicalSize();
      },
    );
  });

  group('ResponsiveContainer', () {
    testWidgets('applies maximum width constraint on wide screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveContainer(
              maxWidth: 430.0,
              child: SizedBox(width: double.infinity, height: 100),
            ),
          ),
        ),
      );

      final renderBox = tester.renderObject<RenderBox>(find.byType(SizedBox));
      expect(renderBox.size.width, 430.0);
    });
  });
}
