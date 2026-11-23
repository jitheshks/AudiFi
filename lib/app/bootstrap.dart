import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors/global_error_handler.dart';
import '../core/logging/app_logger.dart';
import '../core/storage/storage_providers.dart';
import '../features/playback/data/services/audifi_audio_handler.dart';
import '../features/playback/data/services/audio_player_service.dart';
import '../features/playback/data/services/just_audio_player_service.dart';
import '../features/playback/presentation/controllers/audio_player_providers.dart';

/// Bootstraps the application by initializing core bindings, configuring
/// logging, installing global error handlers, initializing background audio,
/// and running inside a protected Zone.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  // Wrap entire application lifecycle inside an asynchronous guarded zone
  // to ensure WidgetsFlutterBinding and runApp execute in the exact same zone,
  // preventing BindingBase.debugCheckZone mismatches.
  await runZonedGuarded<Future<void>>(
    () async {
      final startupStopwatch = Stopwatch()..start();

      // 1. Ensure Flutter engine and widget bindings are initialized inside the zone
      final bindingStopwatch = Stopwatch()..start();
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      final isTesting =
          !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      if (!isTesting) {
        FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      }
      bindingStopwatch.stop();

      // 2. Initialize global framework and platform error handlers
      final errorStopwatch = Stopwatch()..start();
      GlobalErrorHandler.initialize();
      errorStopwatch.stop();

      // 3. Preload SharedPreferences synchronously for initial frame theme accuracy
      if (!isTesting) {
        try {
          final prefs = await SharedPreferences.getInstance();
          setPreloadedSharedPreferences(prefs);
        } catch (e) {
          AppLogger.warning(
            'Failed to preload SharedPreferences: $e',
            tag: 'Bootstrap',
          );
        }
      }

      AppLogger.info(
        'Audifi application bootstrapping started inside protected zone '
        '(binding: ${bindingStopwatch.elapsedMilliseconds}ms, errorHandler: ${errorStopwatch.elapsedMilliseconds}ms)',
        tag: 'Bootstrap',
      );

      // 3. Initialize background audio service and player engine exactly once
      AudioPlayerService audioPlayerService;
      AudioHandler audioHandler;

      if (isBootstrapAudioInitialized) {
        AppLogger.info(
          'Bootstrap audio services already initialized; reusing existing singletons',
          tag: 'Bootstrap',
        );
        audioPlayerService = getBootstrapAudioPlayerService()!;
        audioHandler = getBootstrapAudioHandler()!;
      } else {
        audioPlayerService = JustAudioPlayerService();
        final audioStopwatch = Stopwatch()..start();
        try {
          AppLogger.info(
            'Initializing AudioService background media notification handler',
            tag: 'Bootstrap',
          );
          audioHandler = await AudioService.init(
            builder: () =>
                AudifiAudioHandler(playerService: audioPlayerService),
            config: const AudioServiceConfig(
              androidNotificationChannelId: 'com.jklabs.audifi.channel.audio',
              androidNotificationChannelName: 'Audifi Playback',
              androidNotificationChannelDescription:
                  'Audifi background music playback controls',
              androidNotificationIcon: 'drawable/ic_notification',
              androidNotificationClickStartsActivity: true,
              androidNotificationOngoing: false,
              androidStopForegroundOnPause: false,
              artDownscaleWidth: 512,
              artDownscaleHeight: 512,
            ),
          );
          audioStopwatch.stop();
          AppLogger.info(
            'AudioService successfully initialized in ${audioStopwatch.elapsedMilliseconds}ms',
            tag: 'Bootstrap',
          );
        } catch (e, st) {
          audioStopwatch.stop();
          AppLogger.warning(
            'AudioService.init() unavailable or platform unsupported (${audioStopwatch.elapsedMilliseconds}ms); using standalone AudifiAudioHandler',
            tag: 'Bootstrap',
            error: e,
            stackTrace: st,
          );
          audioHandler = AudifiAudioHandler(playerService: audioPlayerService);
        }

        setBootstrapAudioServices(
          audioHandler: audioHandler,
          audioPlayerService: audioPlayerService,
        );
      }

      // 4. Build and run application widget
      final builderStopwatch = Stopwatch()..start();
      final appWidget = await builder();
      builderStopwatch.stop();

      AppLogger.info(
        'Executing runApp() at ${startupStopwatch.elapsedMilliseconds}ms '
        '(builder: ${builderStopwatch.elapsedMilliseconds}ms)',
        tag: 'StartupPerformance',
      );

      // Schedule first-frame instrumentation to capture exact time to first frame and remove native splash
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isTesting) {
          FlutterNativeSplash.remove();
        }
        AppLogger.info(
          'First frame successfully rendered in ${startupStopwatch.elapsedMilliseconds}ms total from bootstrap start',
          tag: 'StartupPerformance',
        );
      });

      runApp(appWidget);
    },
    (error, stackTrace) {
      AppLogger.error(
        'Unhandled zone error caught during runtime',
        tag: 'Zone',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
