import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:audifi/core/permissions/permission_providers.dart';
import 'package:audifi/features/settings/presentation/views/notifications_view.dart';

import '../../../../test/core/permissions/permission_service_test.dart';

void main() {
  group('NotificationsView Widget Tests', () {
    late FakePermissionService fakeService;

    setUp(() {
      fakeService = FakePermissionService();
    });

    Widget createTestWidget({
      required Widget child,
      FakePermissionService? service,
    }) {
      return ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(service ?? fakeService),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('renders Granted permission state correctly', (tester) async {
      fakeService.mockStatus = PermissionStatus.granted;

      await tester.pumpWidget(
        createTestWidget(child: const NotificationsView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('‹ Settings'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('PERMISSION STATUS'), findsOneWidget);
      expect(find.text('Notification Permission'), findsOneWidget);
      expect(find.text('Allowed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Open Notification Settings'), findsOneWidget);
      expect(find.text('Enable Notifications'), findsNothing);

      // Verify Playback Notification card
      expect(find.text('PLAYBACK NOTIFICATION'), findsOneWidget);
      expect(find.text('Media Controls'), findsOneWidget);
      expect(
        find.text(
          'Playback notifications provide music controls and playback information while music is playing in the background.',
        ),
        findsOneWidget,
      );

      // Verify technical metadata / channel IDs are NOT displayed (per prompt requirement)
      expect(find.text('Channel ID'), findsNothing);
      expect(find.text('com.jklabs.audifi.channel.audio'), findsNothing);
      expect(find.text('Service Type'), findsNothing);

      // Verify no fake in-app toggle exists
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets(
      'tapping Open Notification Settings invokes openNotificationSettings',
      (tester) async {
        fakeService.mockStatus = PermissionStatus.granted;

        await tester.pumpWidget(
          createTestWidget(child: const NotificationsView()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Notification Settings'));
        await tester.pumpAndSettle();

        expect(fakeService.openNotificationSettingsCallCount, equals(1));
      },
    );

    testWidgets(
      'renders Denied permission state with Enable Notifications and Open Notification Settings',
      (tester) async {
        fakeService.mockStatus = PermissionStatus.denied;

        await tester.pumpWidget(
          createTestWidget(child: const NotificationsView()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Not allowed'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
        expect(find.text('Enable Notifications'), findsOneWidget);
        expect(find.text('Open Notification Settings'), findsOneWidget);

        // Tap Enable Notifications
        await tester.tap(find.text('Enable Notifications'));
        await tester.pumpAndSettle();

        expect(fakeService.requestCallCount, equals(1));
      },
    );

    testWidgets(
      'renders Permanently Denied state with Open Notification Settings button',
      (tester) async {
        fakeService.mockStatus = PermissionStatus.permanentlyDenied;

        await tester.pumpWidget(
          createTestWidget(child: const NotificationsView()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Not allowed'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_off_rounded), findsOneWidget);
        expect(find.text('Enable Notifications'), findsNothing);
        expect(find.text('Open Notification Settings'), findsOneWidget);

        await tester.tap(find.text('Open Notification Settings'));
        await tester.pumpAndSettle();

        expect(fakeService.openNotificationSettingsCallCount, equals(1));
      },
    );
  });
}
