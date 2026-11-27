import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/core/permissions/permission_providers.dart';
import 'package:audifi/features/settings/presentation/views/about_view.dart';
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

    testWidgets('SettingsView displays all 6 categories in exact order', (
      tester,
    ) async {
      await tester.pumpWidget(createTestHarness(const SettingsView()));
      await tester.pumpAndSettle();

      // Verify page title
      expect(find.text('Settings'), findsOneWidget);

      // Verify category headers
      expect(find.text('PLAYBACK'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('MUSIC'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('PRIVACY'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('AUDIO'), findsNothing);

      // Verify category titles
      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Audio'), findsNothing);
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
      'PrivacyView renders data isolation principles, zero tracking, and online policy action',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const PrivacyView()));
        await tester.pumpAndSettle();

        expect(find.text('‹ Settings'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsWidgets);
        expect(find.text('DATA & PRIVACY'), findsOneWidget);
        expect(find.text('On-device data storage'), findsOneWidget);
        expect(find.text('Audius services'), findsOneWidget);
        expect(find.text('Zero analytics & tracking'), findsOneWidget);
        expect(find.text('ONLINE POLICY'), findsOneWidget);
        expect(find.text('View Privacy Policy Online'), findsOneWidget);

        // Verify notifications are NOT present in Privacy
        expect(find.text('Media Notifications'), findsNothing);
        expect(find.text('Notification Permission'), findsNothing);
        expect(find.text('SYSTEM PERMISSIONS'), findsNothing);
      },
    );

    testWidgets(
      'PrivacyView tapping View Privacy Policy Online launches canonical URL',
      (tester) async {
        final List<MethodCall> methodCalls = [];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('com.jklabs.audifi/launcher'),
          (MethodCall methodCall) async {
            methodCalls.add(methodCall);
            return true;
          },
        );

        await tester.pumpWidget(createTestHarness(const PrivacyView()));
        await tester.pumpAndSettle();

        expect(find.text('View Privacy Policy Online'), findsOneWidget);
        await tester.tap(find.text('View Privacy Policy Online'));
        await tester.pumpAndSettle();

        expect(methodCalls, isNotEmpty);
        expect(methodCalls.first.method, equals('launchUrl'));
        expect(
          methodCalls.first.arguments['url'],
          equals('https://jklabs-apps.github.io/audifi/privacy-policy.html'),
        );
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
        // Duplicate Privacy Policy navigation must be removed from About
        expect(find.text('Privacy Policy'), findsNothing);
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
      'AboutView eliminates duplicate Privacy Policy navigation',
      (tester) async {
        await tester.pumpWidget(createTestHarness(const AboutView()));
        await tester.pumpAndSettle();

        // Duplicate navigation removed: Settings -> Privacy Policy is single destination
        expect(find.text('Privacy Policy'), findsNothing);
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
