import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Centralized global error handling installation for framework, platform,
/// and unhandled asynchronous errors.
class GlobalErrorHandler {
  GlobalErrorHandler._();

  static bool _isInstalled = false;

  /// Whether the global error handler hooks have been installed.
  static bool get isInstalled => _isInstalled;

  /// Installs global hooks for Flutter framework and platform-level errors.
  static void initialize() {
    if (_isInstalled) return;
    _isInstalled = true;

    // 1. Flutter Framework Errors (layout overflows, build phase exceptions)
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        'Flutter framework error: ${details.exceptionAsString()}',
        tag: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );

      // Preserve default framework behavior (e.g. printing in debug mode)
      if (originalOnError != null) {
        originalOnError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    // 2. Uncaught Platform & Asynchronous Errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLogger.error(
        'Uncaught platform error',
        tag: 'PlatformDispatcher',
        error: error,
        stackTrace: stack,
      );
      return true; // Mark as handled to prevent abrupt application crash
    };
  }
}
