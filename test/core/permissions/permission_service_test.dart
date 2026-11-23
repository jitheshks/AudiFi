import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:audifi/core/permissions/permission_providers.dart';
import 'package:audifi/core/permissions/permission_service.dart';
import 'package:audifi/features/settings/presentation/views/notifications_view.dart';
import 'package:audifi/features/settings/presentation/views/privacy_view.dart';

/// Test double implementing [PermissionService] with controllable responses.
class FakePermissionService implements PermissionService {
  PermissionStatus mockStatus = PermissionStatus.denied;
  bool mockShouldShowRationale = false;
  bool mockOpenSettingsResult = true;

  int checkStatusCallCount = 0;
  int requestCallCount = 0;
  int openSettingsCallCount = 0;

  @override
  Future<PermissionStatus> checkStatus(Permission permission) async {
    checkStatusCallCount++;
    return mockStatus;
  }

  @override
  Future<bool> isGranted(Permission permission) async {
    final status = await checkStatus(permission);
    return status.isGranted;
  }

  @override
  Future<bool> isDenied(Permission permission) async {
    final status = await checkStatus(permission);
    return status.isDenied;
  }

  @override
  Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await checkStatus(permission);
    return status.isPermanentlyDenied;
  }

  @override
  Future<bool> isRestricted(Permission permission) async {
    final status = await checkStatus(permission);
    return status.isRestricted;
  }

  @override
  Future<bool> shouldShowRationale(Permission permission) async {
    return mockShouldShowRationale;
  }

  @override
  Future<PermissionResult> request(Permission permission) async {
    requestCallCount++;
    return PermissionResult(
      permission: permission,
      status: mockStatus,
      shouldShowRationale: mockShouldShowRationale,
    );
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCallCount++;
    return mockOpenSettingsResult;
  }

  int openNotificationSettingsCallCount = 0;
  bool mockOpenNotificationSettingsResult = true;

  @override
  Future<bool> openNotificationSettings() async {
    openNotificationSettingsCallCount++;
    return mockOpenNotificationSettingsResult;
  }

  @override
  Future<PermissionStatus> checkNotificationPermission() =>
      checkStatus(Permission.notification);

  @override
  Future<bool> isNotificationGranted() => isGranted(Permission.notification);

  @override
  Future<PermissionResult> requestNotificationPermission() =>
      request(Permission.notification);
}

void main() {
  group('PermissionResult Entity', () {
    test('reports boolean properties matching PermissionStatus', () {
      const grantedResult = PermissionResult(
        permission: Permission.notification,
        status: PermissionStatus.granted,
      );
      expect(grantedResult.isGranted, isTrue);
      expect(grantedResult.isDenied, isFalse);
      expect(grantedResult.isPermanentlyDenied, isFalse);
      expect(grantedResult.isRestricted, isFalse);

      const deniedResult = PermissionResult(
        permission: Permission.notification,
        status: PermissionStatus.denied,
        shouldShowRationale: true,
      );
      expect(deniedResult.isGranted, isFalse);
      expect(deniedResult.isDenied, isTrue);
      expect(deniedResult.shouldShowRationale, isTrue);

      const permanentlyDeniedResult = PermissionResult(
        permission: Permission.notification,
        status: PermissionStatus.permanentlyDenied,
      );
      expect(permanentlyDeniedResult.isPermanentlyDenied, isTrue);
      expect(permanentlyDeniedResult.isGranted, isFalse);
    });

    test('value equality and toString function correctly', () {
      const r1 = PermissionResult(
        permission: Permission.notification,
        status: PermissionStatus.granted,
      );
      const r2 = PermissionResult(
        permission: Permission.notification,
        status: PermissionStatus.granted,
      );
      const r3 = PermissionResult(
        permission: Permission.notification,
        status: PermissionStatus.denied,
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
      expect(r1.toString(), contains('Permission.notification'));
    });
  });

  group('PermissionService & Riverpod Integration', () {
    late FakePermissionService fakeService;

    setUp(() {
      fakeService = FakePermissionService();
    });

    test('checks and reports granted status', () async {
      fakeService.mockStatus = PermissionStatus.granted;

      final container = ProviderContainer(
        overrides: [permissionServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final service = container.read(permissionServiceProvider);
      expect(await service.isNotificationGranted(), isTrue);
      expect(await service.isDenied(Permission.notification), isFalse);
      expect(fakeService.checkStatusCallCount, equals(2));
    });

    test('NotificationPermissionNotifier requests and updates state', () async {
      fakeService.mockStatus = PermissionStatus.denied;

      final container = ProviderContainer(
        overrides: [permissionServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        notificationPermissionControllerProvider.notifier,
      );

      // Initial status load
      final initial = await container.read(
        notificationPermissionControllerProvider.future,
      );
      expect(initial, equals(PermissionStatus.denied));

      // User grants permission on request
      fakeService.mockStatus = PermissionStatus.granted;
      final result = await notifier.request();

      expect(result.isGranted, isTrue);
      expect(
        container.read(notificationPermissionControllerProvider).value,
        equals(PermissionStatus.granted),
      );
    });

    test(
      'NotificationPermissionNotifier openSettings delegates to service',
      () async {
        final container = ProviderContainer(
          overrides: [permissionServiceProvider.overrideWithValue(fakeService)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(
          notificationPermissionControllerProvider.notifier,
        );

        final opened = await notifier.openSettings();
        expect(opened, isTrue);
        expect(fakeService.openSettingsCallCount, equals(1));
      },
    );
  });

  group('NotificationsView Permission UI Tests', () {
    late FakePermissionService fakeService;

    setUp(() {
      fakeService = FakePermissionService();
    });

    testWidgets('renders Granted state with checkmark', (tester) async {
      fakeService.mockStatus = PermissionStatus.granted;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [permissionServiceProvider.overrideWithValue(fakeService)],
          child: const MaterialApp(home: Scaffold(body: NotificationsView())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('PERMISSION STATUS'), findsOneWidget);
      expect(find.text('Notification Permission'), findsOneWidget);
      expect(find.text('Allowed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Enable Notifications'), findsNothing);
      expect(find.text('Open Notification Settings'), findsOneWidget);
    });

    testWidgets(
      'renders Denied state with "Enable Notifications" action button',
      (tester) async {
        fakeService.mockStatus = PermissionStatus.denied;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionServiceProvider.overrideWithValue(fakeService),
            ],
            child: const MaterialApp(home: Scaffold(body: NotificationsView())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Not allowed'), findsOneWidget);
        expect(find.text('Enable Notifications'), findsOneWidget);
        expect(find.text('Open Notification Settings'), findsOneWidget);

        // Tapping invokes request
        await tester.tap(find.text('Enable Notifications'));
        await tester.pumpAndSettle();

        expect(fakeService.requestCallCount, equals(1));
      },
    );

    testWidgets(
      'renders Permanently Denied state with "Open Notification Settings" button',
      (tester) async {
        fakeService.mockStatus = PermissionStatus.permanentlyDenied;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              permissionServiceProvider.overrideWithValue(fakeService),
            ],
            child: const MaterialApp(home: Scaffold(body: NotificationsView())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Not allowed'), findsOneWidget);
        expect(find.text('Open Notification Settings'), findsOneWidget);

        // Tapping invokes openNotificationSettings
        await tester.tap(find.text('Open Notification Settings'));
        await tester.pumpAndSettle();

        expect(fakeService.openNotificationSettingsCallCount, equals(1));
      },
    );

    testWidgets('PrivacyView does NOT contain notification permissions', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [permissionServiceProvider.overrideWithValue(fakeService)],
          child: const MaterialApp(home: Scaffold(body: PrivacyView())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('On-device data storage'), findsOneWidget);
      expect(find.text('Decentralized Audius protocol'), findsOneWidget);
      expect(find.text('Zero analytics & tracking'), findsOneWidget);
      // Privacy Policy has its canonical single entry point in AboutView
      expect(find.text('Privacy Policy'), findsNothing);

      // Verify no notification controls remain in Privacy
      expect(find.text('Media Notifications'), findsNothing);
      expect(find.text('Notification Permission'), findsNothing);
      expect(find.text('Enable Notifications'), findsNothing);
      expect(find.text('SYSTEM PERMISSIONS'), findsNothing);
    });
  });
}
