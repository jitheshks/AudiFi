import 'package:audifi/app.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/widgets/mini_player/mini_player.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers/stub_repositories.dart';

class ResponsiveConfig {
  const ResponsiveConfig({
    required this.name,
    required this.size,
    this.devicePixelRatio = 1.0,
    this.textScaleFactor = 1.0,
    this.padding = EdgeInsets.zero,
  });

  final String name;
  final Size size;
  final double devicePixelRatio;
  final double textScaleFactor;
  final EdgeInsets padding;
}

void main() {
  const testTrack = Track(
    id: 'test_track_resp_1',
    title: 'Midnight City',
    duration: 240,
    user: User(id: 'u1', name: 'M83', handle: 'm83'),
  );

  const configs = [
    // 1. Compact phone — portrait
    ResponsiveConfig(
      name: '1. Compact phone — portrait (320x640)',
      size: Size(320, 640),
      padding: EdgeInsets.only(top: 24, bottom: 16),
    ),
    // 2. Standard phone — portrait
    ResponsiveConfig(
      name: '2. Standard phone — portrait (390x844)',
      size: Size(390, 844),
      padding: EdgeInsets.only(top: 47, bottom: 34),
    ),
    // 3. Large phone — portrait
    ResponsiveConfig(
      name: '3. Large phone — portrait (412x915)',
      size: Size(412, 915),
      padding: EdgeInsets.only(top: 48, bottom: 24),
    ),
    // 4. Phone — landscape (POCO X6 Pro representative metrics)
    ResponsiveConfig(
      name: '4. Phone — landscape (853x394)',
      size: Size(853, 394),
      padding: EdgeInsets.only(top: 47, bottom: 16),
    ),
    // 5. Tablet — portrait
    ResponsiveConfig(
      name: '5. Tablet — portrait (768x1024)',
      size: Size(768, 1024),
      padding: EdgeInsets.only(top: 24, bottom: 20),
    ),
    // 6. Tablet — landscape
    ResponsiveConfig(
      name: '6. Tablet — landscape (1024x768)',
      size: Size(1024, 768),
      padding: EdgeInsets.only(top: 24, bottom: 20),
    ),
    // 7. Short-height landscape configuration
    ResponsiveConfig(
      name: '7. Short-height landscape (700x320)',
      size: Size(700, 320),
      padding: EdgeInsets.only(top: 24, bottom: 16),
    ),
    // 8. Large display/font scaling configuration
    ResponsiveConfig(
      name: '8. Large display/font scaling (853x394 @ 1.5x text scale)',
      size: Size(853, 394),
      textScaleFactor: 1.5,
      padding: EdgeInsets.only(top: 47, bottom: 16),
    ),
  ];

  for (final config in configs) {
    testWidgets('AudifiApp renders without overflows on ${config.name}', (
      tester,
    ) async {
      tester.view.physicalSize = config.size;
      tester.view.devicePixelRatio = config.devicePixelRatio;
      tester.view.padding = FakeViewPadding(
        top: config.padding.top,
        bottom: config.padding.bottom,
        left: config.padding.left,
        right: config.padding.right,
      );
      tester.platformDispatcher.textScaleFactorTestValue =
          config.textScaleFactor;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: createStubRepositoryOverrides(),
          child: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              return const AudifiApp();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Check Home screen elements
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Liked'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Device'), findsOneWidget);

      // 2. Trigger active playback to verify MiniPlayer layout under this configuration
      capturedRef
          .read(playbackControllerProvider.notifier)
          .playTrack(testTrack);
      await tester.pumpAndSettle();
      expect(find.byType(MiniPlayer), findsOneWidget);
      final miniPlayerTrackFinder = find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.text('Midnight City'),
      );
      expect(miniPlayerTrackFinder, findsOneWidget);

      // 3. Verify all 5 navigation destinations exist
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // 4. Navigate to Discover
      await tester.ensureVisible(find.text('Discover'));
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();
      expect(find.text('Genres'), findsOneWidget);

      // 5. Navigate to Search
      await tester.ensureVisible(find.text('Search'));
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Find What You Love'), findsOneWidget);

      // 6. Navigate to Library
      await tester.ensureVisible(find.text('Library'));
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(
        find.text('Your saved music and offline collection'),
        findsOneWidget,
      );

      // 7. Navigate to Settings — must never be clipped or inaccessible
      await tester.ensureVisible(find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('PLAYBACK'), findsOneWidget);

      // 8. Navigate to Appearance drill-down
      await tester.ensureVisible(find.text('Appearance'));
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      expect(find.text('THEME'), findsOneWidget);
      expect(find.text('ACCENT'), findsOneWidget);

      // 9. Confirm MiniPlayer remains functional and positioned without overflow
      expect(find.byType(MiniPlayer), findsOneWidget);
    });
  }
}
