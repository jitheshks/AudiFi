import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/presentation/widgets/now_playing/audio_info_sheet.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

void main() {
  group('AudioInfoSheet Widget', () {
    const testTrack = Track(
      id: 'track_info_1',
      title: 'High Fidelity Dream',
      duration: 240,
      user: User(id: 'u1', name: 'Audiophile Producer', handle: 'audiophile'),
      isDownloadable: true,
      isDownloadGated: false,
    );

    testWidgets('renders track metadata, Audius format and quality specs', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AudioInfoSheet(track: testTrack)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header & titles
      expect(find.text('Audio Information'), findsOneWidget);
      expect(find.text('High Fidelity Dream'), findsOneWidget);
      expect(find.text('Audiophile Producer'), findsOneWidget);

      // Verify Audius audio quality specifications
      expect(find.text('FORMAT'), findsOneWidget);
      expect(find.text('MP3 (Standard Audius Stream)'), findsOneWidget);
      expect(find.text('QUALITY'), findsOneWidget);
      expect(find.text('320 kbps, 48 kHz (Published Spec)'), findsOneWidget);
      expect(find.text('DELIVERY'), findsOneWidget);
      expect(find.text('HTTP Range Request (Progressive)'), findsOneWidget);

      // Verify Output Devices & Equalizer labels
      expect(find.text('AVAILABLE OUTPUT DEVICES'), findsOneWidget);
      expect(find.text('EQUALIZER'), findsOneWidget);
      expect(find.text('System Default (Unaltered)'), findsOneWidget);

      // Verify close button
      expect(find.text('Close'), findsOneWidget);

      // Verify creator-authorized download button is shown
      expect(find.text('Download for Offline Playback'), findsOneWidget);
    });

    testWidgets('renders disabled download button for creator-disabled track', (
      tester,
    ) async {
      const disabledTrack = Track(
        id: 'track_disabled',
        title: 'Closed Track',
        duration: 180,
        isDownloadable: false,
        isDownloadGated: false,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AudioInfoSheet(track: disabledTrack)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download Unavailable'), findsOneWidget);
      expect(
        find.text("Downloads aren't available for this track."),
        findsOneWidget,
      );
    });

    testWidgets('renders gated download button for access-gated track', (
      tester,
    ) async {
      const gatedTrack = Track(
        id: 'track_gated',
        title: 'Gated Track',
        duration: 200,
        isDownloadable: true,
        isDownloadGated: true,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AudioInfoSheet(track: gatedTrack)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download Gated'), findsOneWidget);
      expect(
        find.text('This download requires creator access.'),
        findsOneWidget,
      );
    });

    testWidgets('passes tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AudioInfoSheet(track: testTrack)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });
  });
}
