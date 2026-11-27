import 'package:audifi/app.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/library/domain/entities/user_library.dart';
import 'package:audifi/features/library/presentation/controllers/listening_history_controller.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/widgets/mini_player/mini_player.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/shared/widgets/audifi_media_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  const testTrack1 = Track(
    id: 't_align_1',
    title: 'Solar Echoes',
    duration: 210,
    user: User(id: 'u_1', name: 'Nigel', handle: 'nigel'),
  );

  const testTrack2 = Track(
    id: 't_align_2',
    title: 'Neon Drift',
    duration: 185,
    user: User(id: 'u_2', name: 'Kavinsky', handle: 'kavinsky'),
  );

  Widget createSubject({
    List<Track> history = const [],
    List<Track> likedTracks = const [],
    void Function(WidgetRef ref)? onRef,
  }) {
    final stubTrack = StubTrackRepository();
    final stubLib = StubLibraryRepository();
    if (likedTracks.isNotEmpty) {
      stubLib.libraryState = UserLibrary(likedTracks: likedTracks);
    }

    return ProviderScope(
      overrides: [
        ...createStubRepositoryOverrides(
          trackRepo: stubTrack,
          libraryRepo: stubLib,
        ),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          onRef?.call(ref);
          return const AudifiApp();
        },
      ),
    );
  }

  group('Landscape Home Screen Alignment & Spacing Polish', () {
    testWidgets('1. Portrait phone (390x844) preserves existing layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        createSubject(
          history: [testTrack1, testTrack2],
          likedTracks: [testTrack1],
          onRef: (ref) => capturedRef = ref,
        ),
      );
      await tester.pumpAndSettle();

      // Seed history for Resume listening & Recently Played
      await capturedRef
          .read(listeningHistoryProvider.notifier)
          .addTrack(testTrack1);
      await tester.pumpAndSettle();

      // Portrait: bottom nav bar visible, no NavigationRail
      expect(find.byType(NavigationRail), findsNothing);

      // Verify greeting and summary cards are present, and redundant hero button is removed
      final greetingFinder = find.textContaining('Good ');
      expect(greetingFinder, findsOneWidget);
      final greetingOffset = tester.getTopLeft(greetingFinder);
      expect(greetingOffset.dx, equals(20.0));

      expect(find.text('Resume listening'), findsNothing);

      final likedFinder = find.ancestor(
        of: find.text('Liked'),
        matching: find.byType(InkWell),
      );
      expect(likedFinder, findsOneWidget);
      final likedOffset = tester.getTopLeft(likedFinder);
      expect(likedOffset.dx, equals(20.0));

      // Summary cards span full available width (350dp) between 20dp paddings
      final deviceFinder = find.ancestor(
        of: find.text('Device'),
        matching: find.byType(InkWell),
      );
      final deviceCardBox = tester.renderObject<RenderBox>(deviceFinder);
      final deviceRightEdge =
          tester.getTopLeft(deviceFinder).dx + deviceCardBox.size.width;
      expect(deviceRightEdge, closeTo(370.0, 1.0)); // 390 - 20 = 370
    });

    testWidgets(
      '2. Landscape phone (853x394, POCO F7): starts higher, aligns left, cards not stretched',
      (tester) async {
        tester.view.physicalSize = const Size(853, 394);
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = const FakeViewPadding(
          top: 24,
          bottom: 16,
          left: 0,
          right: 0,
        );
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetPadding();
        });

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          createSubject(
            history: [testTrack1, testTrack2],
            likedTracks: [testTrack1],
            onRef: (ref) => capturedRef = ref,
          ),
        );
        await tester.pumpAndSettle();

        await capturedRef
            .read(listeningHistoryProvider.notifier)
            .addTrack(testTrack1);
        await tester.pumpAndSettle();

        // 1. NavigationRail is present on wide/landscape screen
        expect(find.byType(NavigationRail), findsOneWidget);
        final railBox = tester.renderObject<RenderBox>(
          find.byType(NavigationRail),
        );
        final railWidth = railBox.size.width; // 72.0
        final dividerWidth = 1.0;
        final expectedLeftMargin = railWidth + dividerWidth + 24.0; // 97.0

        // 2. Greeting header starts higher and aligns to the left (not centered!)
        final greetingFinder = find.textContaining('Good ');
        expect(greetingFinder, findsOneWidget);
        final greetingOffset = tester.getTopLeft(greetingFinder);
        expect(greetingOffset.dx, equals(expectedLeftMargin));
        // Top spacing is compact: topInset (24) + 2.0 topSpacing + 2.0 padding = 28.0
        expect(greetingOffset.dy, equals(28.0));

        // 3. Redundant hero button is removed to avoid playback clash
        expect(find.text('Resume listening'), findsNothing);

        // 4. Summary cards are left-aligned with greeting
        final likedFinder = find.ancestor(
          of: find.text('Liked'),
          matching: find.byType(InkWell),
        );
        expect(likedFinder, findsOneWidget);
        final likedOffset = tester.getTopLeft(likedFinder);
        expect(likedOffset.dx, equals(expectedLeftMargin));

        // 5. Summary cards do NOT stretch across the screen: constrained to 420dp
        final deviceFinder = find.ancestor(
          of: find.text('Device'),
          matching: find.byType(InkWell),
        );
        final deviceBox = tester.renderObject<RenderBox>(deviceFinder);
        final totalCardsWidth =
            (tester.getTopLeft(deviceFinder).dx + deviceBox.size.width) -
            likedOffset.dx;
        expect(totalCardsWidth, closeTo(420.0, 1.0));

        // 6. Section headings align on the exact same left coordinate
        final recentlyPlayedFinder = find.text('Recently Played');
        expect(recentlyPlayedFinder, findsOneWidget);
        final sectionOffset = tester.getTopLeft(recentlyPlayedFinder);
        expect(sectionOffset.dx, equals(expectedLeftMargin));

        // 7. Horizontal carousel starts at expectedLeftMargin and is wide enough to show items
        final firstMediaCard = find.widgetWithText(
          AudifiMediaCard,
          'Solar Echoes',
        );
        expect(firstMediaCard, findsOneWidget);
        final mediaCardOffset = tester.getTopLeft(firstMediaCard);
        expect(mediaCardOffset.dx, equals(expectedLeftMargin));

        // 8. MiniPlayer remains correctly positioned
        capturedRef
            .read(playbackControllerProvider.notifier)
            .playTrack(testTrack1);
        await tester.pumpAndSettle();
        expect(find.byType(MiniPlayer), findsOneWidget);
        final miniPlayerBox = tester.renderObject<RenderBox>(
          find.byType(MiniPlayer),
        );
        expect(miniPlayerBox.size.width, closeTo(853.0 - railWidth - 1.0, 1.0));
      },
    );

    testWidgets('3. Tablet portrait (768x1024) alignment and constraints', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        createSubject(
          history: [testTrack1],
          likedTracks: [testTrack1],
          onRef: (ref) => capturedRef = ref,
        ),
      );
      await tester.pumpAndSettle();

      await capturedRef
          .read(listeningHistoryProvider.notifier)
          .addTrack(testTrack1);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      final railWidth = tester
          .renderObject<RenderBox>(find.byType(NavigationRail))
          .size
          .width;
      final expectedLeftMargin = railWidth + 1.0 + 24.0;

      final greetingOffset = tester.getTopLeft(find.textContaining('Good '));
      expect(greetingOffset.dx, equals(expectedLeftMargin));

      expect(find.text('Resume listening'), findsNothing);

      final sectionOffset = tester.getTopLeft(find.text('Recently Played'));
      expect(sectionOffset.dx, equals(expectedLeftMargin));
    });

    testWidgets('4. Tablet landscape (1024x768) alignment and constraints', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        createSubject(
          history: [testTrack1],
          likedTracks: [testTrack1],
          onRef: (ref) => capturedRef = ref,
        ),
      );
      await tester.pumpAndSettle();

      await capturedRef
          .read(listeningHistoryProvider.notifier)
          .addTrack(testTrack1);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      final railWidth = tester
          .renderObject<RenderBox>(find.byType(NavigationRail))
          .size
          .width;
      final expectedLeftMargin = railWidth + 1.0 + 24.0;

      // Greeting, cards, section headers all align at expectedLeftMargin
      expect(
        tester.getTopLeft(find.textContaining('Good ')).dx,
        equals(expectedLeftMargin),
      );
      expect(find.text('Resume listening'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Recently Played')).dx,
        equals(expectedLeftMargin),
      );

      // Carousel item taps trigger playback
      await tester.tap(find.widgetWithText(AudifiMediaCard, 'Solar Echoes'));
      await tester.pumpAndSettle();
      expect(
        capturedRef.read(playbackControllerProvider).currentTrack?.title,
        equals('Solar Echoes'),
      );
    });

    testWidgets('5. Wider landscape viewport (1440x900)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        createSubject(
          history: [testTrack1],
          likedTracks: [testTrack1],
          onRef: (ref) => capturedRef = ref,
        ),
      );
      await tester.pumpAndSettle();

      await capturedRef
          .read(listeningHistoryProvider.notifier)
          .addTrack(testTrack1);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      final railWidth = tester
          .renderObject<RenderBox>(find.byType(NavigationRail))
          .size
          .width;
      final expectedLeftMargin = railWidth + 1.0 + 24.0;

      // Ensure content starts near upper-left (at expectedLeftMargin) instead of centered at 720
      final greetingX = tester.getTopLeft(find.textContaining('Good ')).dx;
      expect(greetingX, equals(expectedLeftMargin));
      expect(
        greetingX,
        lessThan(200.0),
      ); // Far to the left, not centered at 720!

      // Summary cards width is still constrained to 420dp and doesn't span 1300dp
      final likedFinder = find.ancestor(
        of: find.text('Liked'),
        matching: find.byType(InkWell),
      );
      final deviceFinder = find.ancestor(
        of: find.text('Device'),
        matching: find.byType(InkWell),
      );
      final deviceBox = tester.renderObject<RenderBox>(deviceFinder);
      final totalCardsWidth =
          (tester.getTopLeft(deviceFinder).dx + deviceBox.size.width) -
          tester.getTopLeft(likedFinder).dx;
      expect(totalCardsWidth, closeTo(420.0, 1.0));
    });
  });
}
