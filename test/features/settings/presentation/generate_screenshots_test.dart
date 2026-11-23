import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/core/theme/app_theme.dart';
import 'package:audifi/features/settings/presentation/views/about_view.dart';
import 'package:audifi/features/settings/presentation/views/privacy_view.dart';
import 'package:audifi/features/settings/presentation/views/settings_view.dart';

void main() {
  testWidgets('Generate final screenshots of Settings, Privacy, and About screens', (
    tester,
  ) async {
    Future<void> capture(
      Widget widget,
      ThemeData theme,
      String fileName,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;

      final GlobalKey repaintKey = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: RepaintBoundary(
                key: repaintKey,
                child: widget,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary =
            repaintKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();

        final dir = Directory('assets/screenshots');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        File('assets/screenshots/$fileName').writeAsBytesSync(bytes);

        final artifactDir = Directory(
          '/home/blackhat/.gemini/antigravity-cli/brain/d1b881f1-066d-4082-9c1e-6b227736528e',
        );
        if (artifactDir.existsSync()) {
          File(
            '/home/blackhat/.gemini/antigravity-cli/brain/d1b881f1-066d-4082-9c1e-6b227736528e/$fileName',
          ).writeAsBytesSync(bytes);
        }
      });
    }

    await capture(
      const SettingsView(),
      AppTheme.darkTheme,
      'settings_screen_dark.png',
    );
    await capture(
      const SettingsView(),
      AppTheme.lightTheme,
      'settings_screen_light.png',
    );
    await capture(
      const PrivacyView(),
      AppTheme.darkTheme,
      'privacy_screen_dark.png',
    );
    await capture(
      const PrivacyView(),
      AppTheme.lightTheme,
      'privacy_screen_light.png',
    );
    await capture(
      const AboutView(),
      AppTheme.darkTheme,
      'about_screen_dark.png',
    );
    await capture(
      const AboutView(),
      AppTheme.lightTheme,
      'about_screen_light.png',
    );
  });
}
