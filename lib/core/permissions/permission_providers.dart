import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_service.dart';

/// Centralized provider delivering the application's [PermissionService] singleton.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return const PermissionServiceImpl();
});

/// Exposes the current status of the notification permission asynchronously.
final notificationPermissionStatusProvider = FutureProvider<PermissionStatus>((
  ref,
) async {
  final service = ref.watch(permissionServiceProvider);
  return service.checkNotificationPermission();
});

/// Reactive controller managing notification permission requests and status changes.
class NotificationPermissionNotifier extends AsyncNotifier<PermissionStatus> {
  @override
  Future<PermissionStatus> build() async {
    final service = ref.watch(permissionServiceProvider);
    return service.checkNotificationPermission();
  }

  /// Contextually requests notification permission from the system.
  Future<PermissionResult> request() async {
    final service = ref.read(permissionServiceProvider);
    final result = await service.requestNotificationPermission();
    state = AsyncData(result.status);
    return result;
  }

  /// Re-checks the current notification permission status (e.g. after returning from settings).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(permissionServiceProvider);
      return service.checkNotificationPermission();
    });
  }

  /// Opens the device settings page for the user to manually grant permissions.
  Future<bool> openSettings() async {
    final service = ref.read(permissionServiceProvider);
    return service.openSettings();
  }

  /// Opens the device notification settings page directly.
  Future<bool> openNotificationSettings() async {
    final service = ref.read(permissionServiceProvider);
    return service.openNotificationSettings();
  }
}

/// Provider managing notification permission state and actions.
final notificationPermissionControllerProvider =
    AsyncNotifierProvider<NotificationPermissionNotifier, PermissionStatus>(
      NotificationPermissionNotifier.new,
    );
