import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:audifi/app/bootstrap.dart';
import 'package:audifi/core/errors/global_error_handler.dart';
import 'package:audifi/core/logging/app_logger.dart';
import 'package:audifi/core/logging/log_level.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';

class CapturingLogAdapter implements LogAdapter {
  final List<String> errorMessages = [];

  @override
  void log({
    required LogLevel level,
    required String message,
    required String tag,
    required DateTime timestamp,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level == LogLevel.error) {
      errorMessages.add('$tag: $message');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CapturingLogAdapter adapter;

  setUp(() {
    adapter = CapturingLogAdapter();
    AppLogger.setAdapters([adapter]);
    AppLogger.minLevel = LogLevel.debug;
  });

  tearDown(() {
    AppLogger.reset();
    resetBootstrapAudioServices();
  });

  group('GlobalErrorHandler & Bootstrap', () {
    test('installs global error hooks idempotently', () {
      GlobalErrorHandler.initialize();
      GlobalErrorHandler.initialize(); // Second call is safe no-op

      expect(GlobalErrorHandler.isInstalled, isTrue);
    });

    test('FlutterError.onError routes framework errors to AppLogger', () {
      GlobalErrorHandler.initialize();

      FlutterError.onError?.call(
        FlutterErrorDetails(
          exception: Exception('Simulated widget tree error'),
          library: 'widget library',
          context: ErrorDescription('while building custom tree'),
        ),
      );

      expect(adapter.errorMessages.isNotEmpty, isTrue);
      expect(adapter.errorMessages.first, contains('FlutterError'));
    });

    test(
      'PlatformDispatcher.onError routes uncaught platform errors to AppLogger',
      () {
        GlobalErrorHandler.initialize();

        final handled = PlatformDispatcher.instance.onError?.call(
          Exception('Uncaught platform async exception'),
          StackTrace.current,
        );

        expect(handled, isTrue);
        expect(
          adapter.errorMessages.any((msg) => msg.contains('Platform')),
          isTrue,
        );
      },
    );

    testWidgets('bootstrap starts builder successfully', (tester) async {
      var builderCalled = false;

      await bootstrap(() {
        builderCalled = true;
        return const MaterialApp(
          home: Scaffold(body: Text('Bootstrapped App')),
        );
      });

      expect(builderCalled, isTrue);
    });
  });
}
