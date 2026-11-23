import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Lightweight platform-channel based external launcher.
/// Avoids extra third-party dependencies while launching web URLs cleanly via native intents
/// and directing users directly to app-specific system notification settings.
class ExternalLauncher {
  const ExternalLauncher._();

  static const MethodChannel _channel = MethodChannel(
    'com.jklabs.audifi/launcher',
  );

  /// Attempts to launch an external web URL in the system browser.
  /// Returns `true` if the native platform accepted the intent, `false` otherwise.
  static Future<bool> launchUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    try {
      final success = await _channel.invokeMethod<bool>('launchUrl', {
        'url': trimmed,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint(
        '[ExternalLauncher] PlatformException launching $trimmed: ${e.message}',
      );
      return false;
    } on MissingPluginException catch (e) {
      debugPrint('[ExternalLauncher] MissingPluginException: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[ExternalLauncher] Unexpected error launching $trimmed: $e');
      return false;
    }
  }

  /// Attempts to open the Android application notification settings page directly.
  /// Falls back to the general application settings page if notification settings cannot be opened.
  static Future<bool> openNotificationSettings() async {
    try {
      final success = await _channel.invokeMethod<bool>(
        'openNotificationSettings',
      );
      if (success == true) return true;
    } on PlatformException catch (e) {
      debugPrint(
        '[ExternalLauncher] PlatformException opening notification settings: ${e.message}',
      );
    } on MissingPluginException catch (e) {
      debugPrint('[ExternalLauncher] MissingPluginException: ${e.message}');
    } catch (e) {
      debugPrint(
        '[ExternalLauncher] Unexpected error opening notification settings: $e',
      );
    }

    // Graceful fallback to permission_handler openAppSettings()
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('[ExternalLauncher] Fallback openAppSettings failed: $e');
      return false;
    }
  }
}
