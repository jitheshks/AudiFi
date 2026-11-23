import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';

/// Riverpod [ProviderObserver] that logs unexpected provider lifecycle errors
/// through [AppLogger] while redacting sensitive states.
final class AppRiverpodObserver extends ProviderObserver {
  const AppRiverpodObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.error(
      'Provider "${context.provider.name ?? context.provider.runtimeType}" failed',
      tag: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
