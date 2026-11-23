import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'log_level.dart';

/// Interface for output destinations (e.g. Console, future Crashlytics/Sentry adapter).
abstract interface class LogAdapter {
  void log({
    required LogLevel level,
    required String message,
    required String tag,
    required DateTime timestamp,
    Object? error,
    StackTrace? stackTrace,
  });
}

/// Default console log adapter using standard Dart developer log facility.
class ConsoleLogAdapter implements LogAdapter {
  const ConsoleLogAdapter();

  @override
  void log({
    required LogLevel level,
    required String message,
    required String tag,
    required DateTime timestamp,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timeStr = timestamp.toIso8601String().substring(11, 19);
    final formattedMessage = '[$timeStr] [${level.label}] [$tag] $message';

    developer.log(
      formattedMessage,
      time: timestamp,
      level: _levelToSeverity(level),
      name: 'audifi.$tag',
      error: error,
      stackTrace: stackTrace,
    );

    if (kDebugMode ||
        tag == 'PlaybackTiming' ||
        tag == 'StartupPerformance' ||
        tag == 'Bootstrap' ||
        tag == 'Playback') {
      debugPrint(formattedMessage);
    }
  }

  static int _levelToSeverity(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.none:
        return 0;
    }
  }
}

/// Production-conscious centralized application logger.
class AppLogger {
  AppLogger._();

  /// Minimum severity level to emit.
  static LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// Active log adapter destinations.
  static final List<LogAdapter> _adapters = [const ConsoleLogAdapter()];

  /// Registers an additional logging adapter (e.g., Crashlytics in future phases).
  static void addAdapter(LogAdapter adapter) {
    _adapters.add(adapter);
  }

  /// Replaces existing adapters with a custom list (useful for automated testing).
  @visibleForTesting
  static void setAdapters(List<LogAdapter> adapters) {
    _adapters
      ..clear()
      ..addAll(adapters);
  }

  /// Resets logger state back to defaults.
  @visibleForTesting
  static void reset() {
    minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;
    _adapters
      ..clear()
      ..add(const ConsoleLogAdapter());
  }

  /// Logs a debug message.
  static void debug(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.debug,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs an informational message.
  static void info(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs a warning message.
  static void warning(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.warning,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs an error message.
  static void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Core logging method that enforces level filtering, redaction, and safe execution.
  static void log(
    LogLevel level,
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final isPerfTag =
        tag == 'PlaybackTiming' ||
        tag == 'StartupPerformance' ||
        tag == 'Bootstrap' ||
        tag == 'Playback';
    if (!isPerfTag && (level < minLevel || level == LogLevel.none)) return;

    try {
      final sanitizedMessage = redactSensitive(message);
      final sanitizedError = error != null
          ? redactSensitive(error.toString())
          : null;
      final now = DateTime.now();

      for (final adapter in _adapters) {
        try {
          adapter.log(
            level: level,
            message: sanitizedMessage,
            tag: tag,
            timestamp: now,
            error: sanitizedError,
            stackTrace: stackTrace,
          );
        } catch (_) {
          // Prevent individual adapter failure from interrupting application execution
        }
      }
    } catch (_) {
      // Ensure logging never throws or causes application failure
    }
  }

  /// Patterns of sensitive data keys to redact.
  static final RegExp _sensitivePattern = RegExp(
    r'(api_key|token|access_token|refresh_token|secret|password|authorization)=([^&\s]+)',
    caseSensitive: false,
  );

  /// Bearer token pattern.
  static final RegExp _bearerPattern = RegExp(
    r'(Bearer\s+)[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  /// Sanitizes sensitive queries, secrets, and auth headers from logged strings.
  static String redactSensitive(String input) {
    if (input.isEmpty) return input;
    var sanitized = input.replaceAllMapped(
      _sensitivePattern,
      (match) => '${match.group(1)}=[REDACTED]',
    );
    sanitized = sanitized.replaceAllMapped(
      _bearerPattern,
      (match) => '${match.group(1)}[REDACTED]',
    );
    return sanitized;
  }
}
