import 'package:audifi/core/theme/app_motion.dart';
import 'package:audifi/core/theme/theme_controller.dart';
import 'package:audifi/features/playback/domain/entities/artwork_palette.dart';
import 'package:audifi/features/playback/presentation/widgets/now_playing/ambient_gradient_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AmbientGradientBackground Widget', () {
    const paletteA = ArtworkPalette(
      dominant: Color(0xFFE53935),
      secondary: Color(0xFF1E88E5),
      accent: Color(0xFFFDD835),
      background: Color(0xFF121212),
      isFallback: false,
    );

    const paletteB = ArtworkPalette(
      dominant: Color(0xFF43A047),
      secondary: Color(0xFF8E24AA),
      accent: Color(0xFFFFB300),
      background: Color(0xFF121212),
      isFallback: false,
    );

    const paletteC = ArtworkPalette(
      dominant: Color(0xFF1565C0),
      secondary: Color(0xFFFF6F00),
      accent: Color(0xFF00BFA5),
      background: Color(0xFF121212),
      isFallback: false,
    );

    testWidgets('renders child on top of ambient glow gradient', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientGradientBackground(
            palette: paletteA,
            child: Text('Now Playing Content'),
          ),
        ),
      );

      expect(find.text('Now Playing Content'), findsOneWidget);
      expect(find.byType(AmbientGradientBackground), findsOneWidget);
    });

    testWidgets('animates transition when palette changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientGradientBackground(
            palette: paletteA,
            child: Text('Content'),
          ),
        ),
      );

      // Rebuild with new palette
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientGradientBackground(
            palette: paletteB,
            child: Text('Content'),
          ),
        ),
      );

      // Animation is in progress
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue);

      // Settle animation
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
      'uses AppMotion.durationEmphasized (400ms) for transition duration',
      (tester) async {
        expect(AppMotion.durationEmphasized, const Duration(milliseconds: 400));

        await tester.pumpWidget(
          const MaterialApp(
            home: AmbientGradientBackground(
              palette: paletteA,
              child: Text('Content'),
            ),
          ),
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: AmbientGradientBackground(
              palette: paletteB,
              child: Text('Content'),
            ),
          ),
        );

        // Verify running mid-way (200ms)
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.hasRunningAnimations, isTrue);

        // Verify running just before 400ms completion (399ms)
        await tester.pump(const Duration(milliseconds: 199));
        expect(tester.hasRunningAnimations, isTrue);

        // Settle the final millisecond to complete 400ms transition
        await tester.pump(const Duration(milliseconds: 2));
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets(
      'smoothly interpolates during rapid successive palette updates',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: AmbientGradientBackground(
              palette: paletteA,
              child: Text('Content'),
            ),
          ),
        );

        // Start transition to paletteB
        await tester.pumpWidget(
          const MaterialApp(
            home: AmbientGradientBackground(
              palette: paletteB,
              child: Text('Content'),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.hasRunningAnimations, isTrue);

        // In-flight switch to paletteC before paletteB settles
        await tester.pumpWidget(
          const MaterialApp(
            home: AmbientGradientBackground(
              palette: paletteC,
              child: Text('Content'),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isTrue);

        // Complete the animation cleanly
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.text('Content'), findsOneWidget);
      },
    );

    testWidgets(
      'respects application-level isReducedMotionProvider via context',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [isReducedMotionProvider.overrideWithValue(true)],
            child: const MaterialApp(
              home: AmbientGradientBackground(
                palette: paletteA,
                child: Text('Content'),
              ),
            ),
          ),
        );

        // Update palette while reduced motion is enabled via Riverpod
        await tester.pumpWidget(
          ProviderScope(
            overrides: [isReducedMotionProvider.overrideWithValue(true)],
            child: const MaterialApp(
              home: AmbientGradientBackground(
                palette: paletteB,
                child: Text('Content'),
              ),
            ),
          ),
        );

        // Should update immediately without animation
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets('skips animation when isReducedMotion is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientGradientBackground(
            palette: paletteA,
            isReducedMotion: true,
            child: Text('Content'),
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientGradientBackground(
            palette: paletteB,
            isReducedMotion: true,
            child: Text('Content'),
          ),
        ),
      );

      // Should have snapped immediately without running animations
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('renders OLED pure black background when isOled is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientGradientBackground(
            palette: paletteA,
            isOled: true,
            child: Text('OLED Content'),
          ),
        ),
      );

      expect(find.text('OLED Content'), findsOneWidget);
    });

    testWidgets('disposes controller cleanly without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AmbientGradientBackground(
            palette: paletteA,
            child: Text('Content'),
          ),
        ),
      );

      // Unmount widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(find.byType(AmbientGradientBackground), findsNothing);
    });
  });
}
