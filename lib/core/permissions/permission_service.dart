import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../logging/app_logger.dart';
import '../utils/external_launcher.dart';

/// Encapsulates the structured result of a permission request.
@immutable
class PermissionResult {
  /// The target permission that was requested.
  final Permission permission;

  /// The resulting status returned by the operating system.
  final PermissionStatus status;

  /// Whether the app should display an educational rationale to the user.
  final bool shouldShowRationale;

  const PermissionResult({
    required this.permission,
    required this.status,
    this.shouldShowRationale = false,
  });

  /// Whether access to the capability has been granted by the user.
  bool get isGranted => status.isGranted;

  /// Whether access has been denied by the user.
  bool get isDenied => status.isDenied;

  /// Whether the permission has been permanently denied (cannot prompt again without settings redirect).
  bool get isPermanentlyDenied => status.isPermanentlyDenied;

  /// Whether the permission is restricted by parental controls or device policy.
  bool get isRestricted => status.isRestricted;

  /// Whether limited access has been granted (e.g. partial photo library access on iOS).
  bool get isLimited => status.isLimited;

  /// Whether provisional authorization has been granted (e.g. quiet notifications on iOS).
  bool get isProvisional => status.isProvisional;

  @override
  String toString() =>
      'PermissionResult(permission: $permission, status: $status, rationale: $shouldShowRationale)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionResult &&
          runtimeType == other.runtimeType &&
          permission == other.permission &&
          status == other.status &&
          shouldShowRationale == other.shouldShowRationale;

  @override
  int get hashCode => Object.hash(permission, status, shouldShowRationale);
}

/// Centralized service interface for runtime permission management.
abstract class PermissionService {
  /// Queries the current status of [permission] without prompting the user.
  Future<PermissionStatus> checkStatus(Permission permission);

  /// Checks if [permission] is currently granted.
  Future<bool> isGranted(Permission permission);

  /// Checks if [permission] has been denied.
  Future<bool> isDenied(Permission permission);

  /// Checks if [permission] has been permanently denied.
  Future<bool> isPermanentlyDenied(Permission permission);

  /// Checks if [permission] is restricted by parental controls or device policy.
  Future<bool> isRestricted(Permission permission);

  /// Checks whether an educational rationale should be shown before requesting [permission].
  Future<bool> shouldShowRationale(Permission permission);

  /// Contextually requests [permission] from the user and returns the structured [PermissionResult].
  Future<PermissionResult> request(Permission permission);

  /// Opens the device application settings screen so the user can manually grant permissions.
  Future<bool> openSettings();

  /// Opens the device notification settings screen directly.
  Future<bool> openNotificationSettings();

  /// Specialized helper to check the notification permission status.
  Future<PermissionStatus> checkNotificationPermission();

  /// Specialized helper to verify if notification permission is granted.
  Future<bool> isNotificationGranted();

  /// Specialized helper to contextually request notification permission.
  Future<PermissionResult> requestNotificationPermission();
}

/// Default production implementation of [PermissionService] backed by `permission_handler`.
class PermissionServiceImpl implements PermissionService {
  const PermissionServiceImpl();

  @override
  Future<PermissionStatus> checkStatus(Permission permission) async {
    try {
      final status = await permission.status;
      return status;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to query status for permission $permission: $e',
        tag: 'Permissions',
        error: e,
        stackTrace: st,
      );
      return PermissionStatus.denied;
    }
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
    try {
      return await permission.shouldShowRequestRationale;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<PermissionResult> request(Permission permission) async {
    try {
      final rationale = await shouldShowRationale(permission);
      final status = await permission.request();
      AppLogger.info(
        'Requested permission $permission: result=$status (rationaleBefore=$rationale)',
        tag: 'Permissions',
      );
      return PermissionResult(
        permission: permission,
        status: status,
        shouldShowRationale: rationale,
      );
    } catch (e, st) {
      AppLogger.error(
        'Exception requesting permission $permission: $e',
        tag: 'Permissions',
        error: e,
        stackTrace: st,
      );
      return PermissionResult(
        permission: permission,
        status: PermissionStatus.denied,
        shouldShowRationale: false,
      );
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      AppLogger.info(
        'Launching system application settings',
        tag: 'Permissions',
      );
      return await openAppSettings();
    } catch (e, st) {
      AppLogger.error(
        'Failed to open application settings: $e',
        tag: 'Permissions',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  @override
  Future<bool> openNotificationSettings() async {
    try {
      AppLogger.info(
        'Launching system notification settings',
        tag: 'Permissions',
      );
      return await ExternalLauncher.openNotificationSettings();
    } catch (e, st) {
      AppLogger.error(
        'Failed to open notification settings: $e',
        tag: 'Permissions',
        error: e,
        stackTrace: st,
      );
      return false;
    }
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
