import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/core/permissions/permission_providers.dart';
import 'package:audifi/features/settings/presentation/views/about_view.dart';
import 'package:audifi/features/settings/presentation/views/audio_view.dart';
import 'package:audifi/features/settings/presentation/views/music_view.dart';
import 'package:audifi/features/settings/presentation/views/playback_view.dart';
import 'package:audifi/features/settings/presentation/views/privacy_view.dart';
import 'package:audifi/features/settings/presentation/views/settings_view.dart';
import 'package:audifi/shared/widgets/audifi_switch.dart';

import '../../../../test/core/permissions/permission_service_test.dart';

void main() {
  group('Settings UX Consistency & Full-Page Navigation Tests', () {
    late FakePermissionService fakeService;

    setUp(() {
      fakeService = FakePermissionService();
    });

    Widget createTestHarness(
      Widget child, {
      List<dynamic> overrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(fakeService),
          ...overrides.cast(),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets('SettingsView displays all 7 categories in exact order', (
      tester,
    ) async {
      await tester.pumpWidget(createTestHarness(const SettingsView()));
      await tester.pumpAndSettle();

      // Verify page title
      expect(find.text('Settings'), findsOneWidget);

      // Verify category headers
      expect(find.text('PLAYBACK'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('AUDIO'), findsOneWidget);
      expect(find.text('MUSIC'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('PRIVACY'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);

      // Verify category titles
      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets(
      'PlaybackView renders full-screen layout with functional switches',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const PlaybackView()));
        await tester.pumpAndSettle();

        expect(find.text('‹ Settings'), findsOneWidget);
        expect(find.text('Playback'), findsOneWidget);
        expect(find.text('AUDIO BEHAVIOR'), findsOneWidget);
        expect(find.text('Pause when headphones disconnect'), findsOneWidget);
        expect(find.text('Stream on mobile data'), findsOneWidget);
        expect(find.text('SLEEP TIMER'), findsOneWidget);
        expect(find.text('Sleep timer'), findsOneWidget);

        // Verify switches exist
        expect(find.byType(AudifiSwitch), findsNWidgets(2));
      },
    );

    testWidgets(
      'AudioView renders streaming quality and removes Volume Normalization',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const AudioView()));
        await tester.pumpAndSettle();

        expect(find.text('‹ Settings'), findsOneWidget);
        expect(find.text('Audio'), findsOneWidget);
        expect(find.text('AUDIO INFORMATION'), findsOneWidget);
        expect(find.text('Audio information'), findsOneWidget);
        expect(find.text('STREAMING QUALITY'), findsOneWidget);
        expect(find.text('Streaming Quality'), findsOneWidget);
        expect(find.text('High Definition (320 kbps MP3)'), findsOneWidget);

        // Verify unsupported volume normalization is removed
        expect(find.text('Volume Normalization'), findsNothing);
        expect(
          find.text('Not supported by progressive audio streams'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'MusicView renders Library Management & Downloads with confirmation dialogs',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const MusicView()));
        await tester.pumpAndSettle();

        expect(find.text('‹ Settings'), findsOneWidget);
        expect(find.text('Music & Storage'), findsOneWidget);
        expect(find.text('LIBRARY MANAGEMENT'), findsOneWidget);
        expect(find.text('Clear favorites'), findsOneWidget);
        expect(find.text('Clear listening history'), findsOneWidget);
        expect(find.text('Clear search history'), findsOneWidget);
        expect(find.text('DOWNLOADS & STORAGE'), findsOneWidget);
        expect(find.text('Clear downloaded music'), findsOneWidget);

        // Tap Clear favorites to verify confirmation dialog
        await tester.tap(find.text('Clear favorites'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Clear all favorites?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Clear Favorites'), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'PrivacyView renders data isolation principles and zero tracking',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const PrivacyView()));
        await tester.pumpAndSettle();

        expect(find.text('‹ Settings'), findsOneWidget);
        expect(find.text('Privacy'), findsOneWidget);
        expect(find.text('DATA & PRIVACY'), findsOneWidget);
        expect(find.text('On-device data storage'), findsOneWidget);
        expect(find.text('Decentralized Audius protocol'), findsOneWidget);
        expect(find.text('Zero analytics & tracking'), findsOneWidget);
        // Privacy Policy must have its single canonical entry point in About
        expect(find.text('POLICY & LEGAL'), findsNothing);
        expect(find.text('Privacy Policy'), findsNothing);

        // Verify notifications are NOT present in Privacy
        expect(find.text('Media Notifications'), findsNothing);
        expect(find.text('Notification Permission'), findsNothing);
        expect(find.text('SYSTEM PERMISSIONS'), findsNothing);
      },
    );

    testWidgets(
      'AboutView renders app identity, description, Audius attribution, and legal entries without unestablished support',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const AboutView()));
        await tester.pumpAndSettle();

        expect(find.text('‹ Settings'), findsOneWidget);
        expect(find.text('About'), findsOneWidget);
        expect(find.text('APPLICATION'), findsOneWidget);
        expect(find.text('AudiFi'), findsOneWidget);
        expect(find.text('Version 1.0.0 (Build 1)'), findsOneWidget);
        expect(
          find.text(
            'An independent music client for discovering and streaming music through the Audius protocol.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'AudiFi is an independent third-party application powered by the Audius protocol. It is not affiliated with, sponsored by, or endorsed by Audius.',
          ),
          findsOneWidget,
        );
        expect(find.text('LEGAL & LICENSES'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('Third-party licenses'), findsOneWidget);
        expect(find.text('Open-source licenses'), findsNothing);

        // Verify unestablished support information is completely removed
        expect(find.text('SUPPORT'), findsNothing);
        expect(find.text('Support & Inquiries'), findsNothing);
        expect(find.text('support@jklabs.dev'), findsNothing);
      },
    );

    testWidgets('AboutView tapping Third-party licenses opens LicensePage', (
      tester,
    ) async {
      await tester.pumpWidget(createTestHarness(const AboutView()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Third-party licenses'), 100.0);
      await tester.tap(find.text('Third-party licenses'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text('AudiFi'), findsWidgets);
      expect(find.text('1.0.0 (Build 1)'), findsOneWidget);
      expect(find.textContaining('JK Labs'), findsNothing);
    });

    testWidgets(
      'AboutView tapping Privacy Policy safely routes to in-app privacy disclosures',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const AboutView()));
        await tester.pumpAndSettle();

        // Tap Privacy Policy
        await tester.scrollUntilVisible(find.text('Privacy Policy'), 100.0);
        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();

        // Safely navigates to PrivacyView without placeholder domains or broken external links
        expect(find.byType(PrivacyView), findsOneWidget);
        expect(find.text('On-device data storage'), findsOneWidget);
        expect(find.text('Decentralized Audius protocol'), findsOneWidget);
        expect(find.text('Zero analytics & tracking'), findsOneWidget);
      },
    );

    testWidgets('PrivacyView meets accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(createTestHarness(const PrivacyView()));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('AboutView meets accessibility guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(createTestHarness(const AboutView()));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
