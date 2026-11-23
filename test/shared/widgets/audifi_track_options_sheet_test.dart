import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/presentation/controllers/queue_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/widgets/audifi_track_options_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../test_helpers/stub_repositories.dart';

void main() {
  group('AudifiTrackOptionsSheet', () {
    const testTrack = Track(
      id: 'opt_1',
      title: 'Midnight Drive',
      duration: 210,
      user: User(id: 'artist_1', name: 'Synthwave Star', handle: 'synthstar'),
    );

    testWidgets('renders track options and actions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createStubRepositoryOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: AudifiTrackOptionsSheet(track: testTrack)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Midnight Drive'), findsOneWidget);
      expect(find.text('Synthwave Star'), findsOneWidget);
      expect(find.text('Play Next'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);
      expect(find.text('Add to Playlist'), findsOneWidget);
      expect(find.text('Go to Artist'), findsOneWidget);
    });

    testWidgets('triggers playNext and addToQueue', (tester) async {
      final container = ProviderContainer(
        overrides: createStubRepositoryOverrides(),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: AudifiTrackOptionsSheet(track: testTrack)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Play Next
      await tester.tap(find.text('Play Next'));
      await tester.pumpAndSettle();

      final queue = container.read(queueControllerProvider);
      expect(queue.items.any((t) => t.id == 'opt_1'), isTrue);
    });

    testWidgets('renders creator-disabled download state accurately', (
      tester,
    ) async {
      const disabledTrack = Track(
        id: 'opt_disabled',
        title: 'Private Beat',
        duration: 180,
        isDownloadable: false,
        isDownloadGated: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createStubRepositoryOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: AudifiTrackOptionsSheet(track: disabledTrack)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download Unavailable'), findsOneWidget);
      expect(
        find.text("Downloads aren't available for this track."),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.file_download_off_rounded), findsOneWidget);
    });

    testWidgets('renders download-gated state accurately', (tester) async {
      const gatedTrack = Track(
        id: 'opt_gated',
        title: 'Premium Track',
        duration: 200,
        isDownloadable: true,
        isDownloadGated: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createStubRepositoryOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: AudifiTrackOptionsSheet(track: gatedTrack)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download Gated'), findsOneWidget);
      expect(
        find.text('This download requires creator access.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('renders authorized download state accurately', (tester) async {
      const authTrack = Track(
        id: 'opt_auth',
        title: 'Free Beat',
        duration: 200,
        isDownloadable: true,
        isDownloadGated: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: createStubRepositoryOverrides(),
          child: const MaterialApp(
            home: Scaffold(body: AudifiTrackOptionsSheet(track: authTrack)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Listen offline without internet'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });
  });
}
