import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/core/logging/app_logger.dart';
import 'package:audifi/core/logging/log_level.dart';

class TestLogRecord {
  const TestLogRecord({
    required this.level,
    required this.message,
    required this.tag,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String message;
  final String tag;
  final Object? error;
  final StackTrace? stackTrace;
}

class MemoryLogAdapter implements LogAdapter {
  final List<TestLogRecord> records = [];

  @override
  void log({
    required LogLevel level,
    required String message,
    required String tag,
    required DateTime timestamp,
    Object? error,
    StackTrace? stackTrace,
  }) {
    records.add(
      TestLogRecord(
        level: level,
        message: message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}

class CrashingLogAdapter implements LogAdapter {
  @override
  void log({
    required LogLevel level,
    required String message,
    required String tag,
    required DateTime timestamp,
    Object? error,
    StackTrace? stackTrace,
  }) {
    throw Exception('Simulated adapter failure');
  }
}

void main() {
  late MemoryLogAdapter memoryAdapter;

  setUp(() {
    memoryAdapter = MemoryLogAdapter();
    AppLogger.setAdapters([memoryAdapter]);
    AppLogger.minLevel = LogLevel.debug;
  });

  tearDown(() {
    AppLogger.reset();
  });

  group('LogLevel', () {
    test('enforces strict priority comparisons', () {
      expect(LogLevel.debug < LogLevel.info, isTrue);
      expect(LogLevel.info < LogLevel.warning, isTrue);
      expect(LogLevel.warning < LogLevel.error, isTrue);
      expect(LogLevel.error < LogLevel.none, isTrue);
      expect(LogLevel.none > LogLevel.error, isTrue);
    });

    test('exposes correct display labels', () {
      expect(LogLevel.debug.label, 'DEBUG');
      expect(LogLevel.info.label, 'INFO');
      expect(LogLevel.warning.label, 'WARN');
      expect(LogLevel.error.label, 'ERROR');
      expect(LogLevel.none.label, 'NONE');
    });
  });

  group('AppLogger Filtering', () {
    test('discards logs below minLevel', () {
      AppLogger.minLevel = LogLevel.warning;

      AppLogger.debug('Debug msg', tag: 'Test');
      AppLogger.info('Info msg', tag: 'Test');
      AppLogger.warning('Warn msg', tag: 'Test');
      AppLogger.error('Error msg', tag: 'Test');

      expect(memoryAdapter.records.length, 2);
      expect(memoryAdapter.records[0].level, LogLevel.warning);
      expect(memoryAdapter.records[1].level, LogLevel.error);
    });

    test('LogLevel.none suppresses all logging', () {
      AppLogger.minLevel = LogLevel.none;

      AppLogger.error('Fatal crash message', tag: 'Critical');

      expect(memoryAdapter.records, isEmpty);
    });
  });

  group('AppLogger Redaction', () {
    test('redacts api_key, passwords, and tokens from message and query strings', () {
      AppLogger.info(
        'GET https://audius.co/api/tracks?app_name=Audifi&api_key=secret_12345',
        tag: 'Network',
      );
      AppLogger.info(
        'User login with password=superSecretPassword',
        tag: 'Auth',
      );
      AppLogger.info(
        'Token refresh token=abc123xyz access_token=tok456',
        tag: 'Auth',
      );

      expect(memoryAdapter.records.length, 3);
      expect(
        memoryAdapter.records[0].message,
        'GET https://audius.co/api/tracks?app_name=Audifi&api_key=[REDACTED]',
      );
      expect(
        memoryAdapter.records[1].message,
        'User login with password=[REDACTED]',
      );
      expect(
        memoryAdapter.records[2].message,
        'Token refresh token=[REDACTED] access_token=[REDACTED]',
      );
    });

    test('redacts Bearer tokens in headers and error strings', () {
      AppLogger.error(
        'Request unauthorized',
        error: 'Authorization header failed: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xyz',
        tag: 'Auth',
      );

      expect(memoryAdapter.records.length, 1);
      expect(
        memoryAdapter.records[0].error,
        'Authorization header failed: Bearer [REDACTED]',
      );
    });
  });

  group('AppLogger Resilience', () {
    test('isolates throwing log adapters and does not interrupt execution', () {
      final crashingAdapter = CrashingLogAdapter();
      AppLogger.setAdapters([crashingAdapter, memoryAdapter]);

      expect(
        () => AppLogger.error('Critical failure event', tag: 'Resilience'),
        returnsNormally,
      );

      expect(memoryAdapter.records.length, 1);
      expect(memoryAdapter.records.first.message, 'Critical failure event');
    });
  });
}
