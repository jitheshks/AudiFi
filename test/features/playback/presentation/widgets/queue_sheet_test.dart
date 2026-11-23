import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/domain/entities/playback_queue.dart';
import 'package:audifi/features/playback/presentation/controllers/queue_controller.dart';
import 'package:audifi/features/playback/presentation/widgets/queue/queue_sheet.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../test_helpers/stub_repositories.dart';

class TestQueueController extends QueueController {
  TestQueueController(this.initialState);

  final PlaybackQueue initialState;

  @override
  PlaybackQueue build() {
    return initialState;
  }
}

void main() {
  group('QueueSheet', () {
    const t1 = Track(
      id: 'q1',
      title: 'First in Queue',
      user: User(id: 'u1', name: 'Curator 1', handle: 'c1'),
    );
    const t2 = Track(
      id: 'q2',
      title: 'Second in Queue',
      user: User(id: 'u2', name: 'Curator 2', handle: 'c2'),
    );

    testWidgets('renders queue header and tracks list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...createStubRepositoryOverrides(),
            queueControllerProvider.overrideWith(
              () => TestQueueController(
                const PlaybackQueue(items: [t1, t2], currentIndex: 0),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: QueueSheet())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Up Next'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2));
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('First in Queue'), findsOneWidget);
      expect(find.text('Second in Queue'), findsOneWidget);
      expect(find.byIcon(Icons.equalizer_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNWidgets(2));
    });

    testWidgets('renders empty state when queue is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createStubRepositoryOverrides(),
          child: const MaterialApp(home: Scaffold(body: QueueSheet())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Queue is Empty'), findsOneWidget);
      expect(
        find.text('Tracks you play or add will appear here.'),
        findsOneWidget,
      );
    });
  });
}
