import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/logging/log_observer.dart';

void main() {
  bootstrap(
    () => const ProviderScope(
      observers: [AppRiverpodObserver()],
      child: AudifiApp(),
    ),
  );
}
