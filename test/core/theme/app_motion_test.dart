import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/core/theme/app_motion.dart';
import 'package:audifi/core/theme/theme_controller.dart';

void main() {
  group('AppMotion Tokens & Standards', () {
    test('Motion duration tokens follow defined specification', () {
      expect(AppMotion.durationFast, const Duration(milliseconds: 150));
      expect(AppMotion.durationShort, const Duration(milliseconds: 200));
      expect(AppMotion.durationPage, const Duration(milliseconds: 250));
      expect(AppMotion.durationMedium, const Duration(milliseconds: 300));
      expect(AppMotion.durationEmphasized, const Duration(milliseconds: 400));
    });

    test('Motion easing curves follow physical deceleration principles', () {
      expect(AppMotion.curveStandard, Curves.easeInOutCubic);
      expect(AppMotion.curveDecelerate, Curves.easeOutCubic);
      expect(AppMotion.curveAccelerate, Curves.easeInCubic);
      expect(AppMotion.curveEmphasized, Curves.easeInOutCubicEmphasized);
    });

    test('isReducedMotion evaluates correctly', () {
      expect(AppMotion.isReducedMotion(isReduced: false), isFalse);
      expect(AppMotion.isReducedMotion(isReduced: true), isTrue);
    });

    test(
      'resolveDuration returns Duration.zero when reduced motion is true',
      () {
        const normalDuration = Duration(milliseconds: 200);
        expect(
          AppMotion.resolveDuration(normalDuration, isReduced: false),
          normalDuration,
        );
        expect(
          AppMotion.resolveDuration(normalDuration, isReduced: true),
          Duration.zero,
        );
      },
    );

    testWidgets('isReducedMotion respects MediaQuery disableAnimations', (
      tester,
    ) async {
      late bool evaluatedNormal;
      late bool evaluatedDisabled;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              evaluatedNormal = AppMotion.isReducedMotion(context: context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(evaluatedNormal, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                evaluatedDisabled = AppMotion.isReducedMotion(context: context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(evaluatedDisabled, isTrue);
    });

    test(
      'isReducedMotionProvider updates state with animationModeProvider',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(isReducedMotionProvider), isFalse);

        container.read(animationModeProvider.notifier).setMode('Reduced');
        expect(container.read(isReducedMotionProvider), isTrue);

        container.read(animationModeProvider.notifier).setMode('Full');
        expect(container.read(isReducedMotionProvider), isFalse);
      },
    );
  });

  group('AnimatedBranchContainer Widget Tests', () {
    testWidgets(
      'Cross-fades between branches and sets offstage on completion',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnimatedBranchContainer(
                currentIndex: 0,
                children: [Text('Branch 0 Content'), Text('Branch 1 Content')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Branch 0 Content'), findsOneWidget);
        expect(find.text('Branch 1 Content'), findsNothing);

        // Switch to branch 1
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnimatedBranchContainer(
                currentIndex: 1,
                children: [Text('Branch 0 Content'), Text('Branch 1 Content')],
              ),
            ),
          ),
        );

        // Mid-animation: both branches are onstage for cross-fade
        await tester.pump(const Duration(milliseconds: 125));
        expect(find.text('Branch 1 Content'), findsOneWidget);

        // End of animation: branch 0 is offstage, branch 1 is visible
        await tester.pumpAndSettle();
        expect(find.text('Branch 1 Content'), findsOneWidget);
        expect(find.text('Branch 0 Content'), findsNothing);
      },
    );

    testWidgets(
      'Reduced motion switches branches instantly without animation delay',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnimatedBranchContainer(
                currentIndex: 0,
                isReduced: true,
                children: [Text('Branch 0 Content'), Text('Branch 1 Content')],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Branch 0 Content'), findsOneWidget);
        expect(find.text('Branch 1 Content'), findsNothing);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnimatedBranchContainer(
                currentIndex: 1,
                isReduced: true,
                children: [Text('Branch 0 Content'), Text('Branch 1 Content')],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Branch 1 Content'), findsOneWidget);
        expect(find.text('Branch 0 Content'), findsNothing);
      },
    );
  });

  group('AudifiTransitionPage & Route Transition Tests', () {
    testWidgets(
      'AudifiTransitionPage produces 250ms duration in Full Motion mode',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        late PageRoute<dynamic> createdRoute;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  final page = AppMotion.createPage<void>(
                    key: const ValueKey('test_full_page'),
                    child: const Text('Target Page'),
                    type: AppTransitionType.slideFade,
                  );
                  createdRoute =
                      page.createRoute(context) as PageRoute<dynamic>;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(createdRoute.transitionDuration, AppMotion.durationPage);
        expect(createdRoute.reverseTransitionDuration, AppMotion.durationPage);
      },
    );

    testWidgets(
      'AudifiTransitionPage produces Duration.zero in Reduced Motion mode',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(animationModeProvider.notifier).setMode('Reduced');

        late PageRoute<dynamic> createdRoute;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  final page = AppMotion.createPage<void>(
                    key: const ValueKey('test_reduced_page'),
                    child: const Text('Target Page'),
                    type: AppTransitionType.slideFade,
                  );
                  createdRoute =
                      page.createRoute(context) as PageRoute<dynamic>;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(createdRoute.transitionDuration, Duration.zero);
        expect(createdRoute.reverseTransitionDuration, Duration.zero);
      },
    );

    testWidgets(
      'AudifiTransitionPage dynamically updates duration when motion preference changes at runtime',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        late BuildContext capturedContext;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        // Initially Full Motion: durationPage (250ms)
        final page1 = AppMotion.createPage<void>(
          key: const ValueKey('page1'),
          child: const Text('P1'),
        );
        final route1 = page1.createRoute(capturedContext) as PageRoute<dynamic>;
        expect(route1.transitionDuration, AppMotion.durationPage);

        // Change mode to Reduced at runtime without recreating router
        container.read(animationModeProvider.notifier).setMode('Reduced');

        // Subsequent route resolution immediately picks up Reduced Motion: Duration.zero
        final page2 = AppMotion.createPage<void>(
          key: const ValueKey('page2'),
          child: const Text('P2'),
        );
        final route2 = page2.createRoute(capturedContext) as PageRoute<dynamic>;
        expect(route2.transitionDuration, Duration.zero);
        expect(route2.reverseTransitionDuration, Duration.zero);

        // Revert to Full Motion at runtime
        container.read(animationModeProvider.notifier).setMode('Full');
        final page3 = AppMotion.createPage<void>(
          key: const ValueKey('page3'),
          child: const Text('P3'),
        );
        final route3 = page3.createRoute(capturedContext) as PageRoute<dynamic>;
        expect(route3.transitionDuration, AppMotion.durationPage);
      },
    );

    testWidgets(
      'AudifiTransitionPage respects platform-level MediaQuery disableAnimations',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        late PageRoute<dynamic> createdRoute;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Builder(
                  builder: (context) {
                    final page = AppMotion.createPage<void>(
                      key: const ValueKey('platform_reduced_page'),
                      child: const Text('Target Page'),
                    );
                    createdRoute =
                        page.createRoute(context) as PageRoute<dynamic>;
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        );

        expect(createdRoute.transitionDuration, Duration.zero);
        expect(createdRoute.reverseTransitionDuration, Duration.zero);
      },
    );

    testWidgets('Builds correct transition widgets for all transition types', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final type in AppTransitionType.values) {
        final page = AppMotion.createPage<void>(
          key: ValueKey(type.name),
          child: Text('Content for ${type.name}'),
          type: type,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Navigator(pages: [page], onDidRemovePage: (page) {}),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Content for ${type.name}'), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });
  });
}
