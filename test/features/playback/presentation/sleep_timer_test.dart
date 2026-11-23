import 'package:audifi/features/playback/presentation/controllers/sleep_timer_controller.dart';
import 'package:audifi/features/playback/presentation/widgets/now_playing/sleep_timer_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  group('SleepTimerController', () {
    test('starts and cancels timer', () {
      final container = ProviderContainer(
        overrides: createStubRepositoryOverrides(),
      );
      addTearDown(container.dispose);

      final controller = container.read(sleepTimerProvider.notifier);
      expect(container.read(sleepTimerProvider).isActive, isFalse);

      controller.startTimer(const Duration(minutes: 15));
      final state = container.read(sleepTimerProvider);
      expect(state.isActive, isTrue);
      expect(state.remaining.inMinutes, 15);
      expect(state.formattedRemaining, '15:00');

      controller.cancelTimer();
      expect(container.read(sleepTimerProvider).isActive, isFalse);
    });
  });

  group('SleepTimerSheet Widget', () {
    testWidgets('renders sleep timer presets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createStubRepositoryOverrides(),
          child: const MaterialApp(home: Scaffold(body: SleepTimerSheet())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sleep Timer'), findsOneWidget);
      expect(find.text('5 minutes'), findsOneWidget);
      expect(find.text('15 minutes'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('45 minutes'), findsOneWidget);
      expect(find.text('1 hour'), findsOneWidget);
    });
  });
}
