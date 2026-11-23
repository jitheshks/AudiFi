import 'dart:io';
import 'dart:ui' as ui;

import 'package:audifi/app.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/library/domain/entities/user_library.dart';
import 'package:audifi/features/library/presentation/controllers/listening_history_controller.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  const testTrack1 = Track(
    id: 't_demo_1',
    title: 'OT, Wouldn\'t Be Right',
    duration: 215,
    user: User(id: 'u_slackin', name: 'Slackin Beats', handle: 'slackin'),
  );

  const testTrack2 = Track(
    id: 't_demo_2',
    title: 'OBSESSION - TH...',
    duration: 198,
    user: User(id: 'u_mortala', name: 'Mortala.', handle: 'mortala'),
  );

  const testTrack3 = Track(
    id: 't_demo_3',
    title: 'Overkill',
    duration: 240,
    user: User(id: 'u_rubber', name: 'Rubberband', handle: 'rubberband'),
  );

  Future<void> captureScreen(
    WidgetTester tester,
    GlobalKey repaintKey,
    String outputPath,
  ) async {
    await tester.runAsync(() async {
      final boundary =
          repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      File(outputPath).writeAsBytesSync(pngBytes);
    });
  }

  testWidgets('Generate Landscape and Portrait Screenshots for POCO F7', (
    tester,
  ) async {
    final repaintKey = GlobalKey();

    Widget buildSubject(WidgetRef ref) {
      return RepaintBoundary(key: repaintKey, child: const AudifiApp());
    }

    final stubTrack = StubTrackRepository();
    final stubLib = StubLibraryRepository();
    stubLib.libraryState = const UserLibrary(likedTracks: [testTrack1]);

    // 1. CAPTURE LANDSCAPE (POCO F7: 853x394)
    tester.view.physicalSize = const Size(853, 394);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });

    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...createStubRepositoryOverrides(
            trackRepo: stubTrack,
            libraryRepo: stubLib,
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return buildSubject(ref);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Populate history and playing track to match reference screenshots
    await capturedRef
        .read(listeningHistoryProvider.notifier)
        .addTrack(testTrack1);
    await capturedRef
        .read(listeningHistoryProvider.notifier)
        .addTrack(testTrack2);
    await capturedRef
        .read(listeningHistoryProvider.notifier)
        .addTrack(testTrack3);
    capturedRef
        .read(playbackControllerProvider.notifier)
        .playTrack(
          testTrack1,
          contextTracks: [testTrack1, testTrack2, testTrack3],
        );
    await tester.pumpAndSettle();

    await captureScreen(tester, repaintKey, 'tmp/device_landscape_after.png');

    // 2. CAPTURE PORTRAIT (390x844)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...createStubRepositoryOverrides(
            trackRepo: stubTrack,
            libraryRepo: stubLib,
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return buildSubject(ref);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await captureScreen(tester, repaintKey, 'tmp/device_portrait_after.png');
  });
}
