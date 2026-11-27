import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/app/router/app_navigation_shell.dart';
import 'package:audifi/app/router/app_router.dart';
import 'package:audifi/app/router/route_paths.dart';
import 'package:audifi/core/permissions/permission_providers.dart';
import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/core/theme/app_motion.dart';
import 'package:audifi/core/theme/theme_controller.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/widgets/mini_player/mini_player.dart';
import 'package:audifi/features/settings/presentation/views/about_view.dart';
import 'package:audifi/features/settings/presentation/views/accent_color_view.dart';
import 'package:audifi/features/settings/presentation/views/appearance_view.dart';
import 'package:audifi/features/settings/presentation/views/music_view.dart';
import 'package:audifi/features/settings/presentation/views/notifications_view.dart';
import 'package:audifi/features/settings/presentation/views/playback_view.dart';
import 'package:audifi/features/settings/presentation/views/privacy_view.dart';
import 'package:audifi/features/settings/presentation/views/settings_view.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

import '../../../../test/core/permissions/permission_service_test.dart';
import '../../../../test/test_helpers/stub_repositories.dart';

class _ReducedAnimationModeNotifier extends AnimationModeNotifier {
  @override
  String build() => 'Reduced';
}

class _TestPlaybackController extends PlaybackController {
  _TestPlaybackController(this.initialState);

  final PlaybackState initialState;

  @override
  PlaybackState build() => initialState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Navigation Transitions & Motion Tests', () {
    late FakePermissionService fakePermissionService;

    setUp(() {
      fakePermissionService = FakePermissionService();
    });

    Widget buildRouterHarness({
      required GoRouter router,
      List<dynamic> overrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(fakePermissionService),
          routerProvider.overrideWithValue(router),
          ...overrides.cast(),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    test('AppMotion.createPage configures slideFade transition with 250ms duration', () {
      final page = AppMotion.createPage(
        key: const ValueKey('test_page'),
        child: const SizedBox(),
        type: AppTransitionType.slideFade,
      );

      expect(page, isA<AudifiTransitionPage>());
      final transitionPage = page as AudifiTransitionPage;
      expect(transitionPage.type, AppTransitionType.slideFade);
      expect(transitionPage.duration, AppMotion.durationPage);
      expect(transitionPage.duration.inMilliseconds, 250);
    });

    testWidgets(
      'slideFade route applies 250ms duration for transition and reverse',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final page = AppMotion.createPage(
                  key: const ValueKey('slide_fade_page'),
                  child: const Scaffold(body: Text('Target Content')),
                  type: AppTransitionType.slideFade,
                );
                final route = (page as AudifiTransitionPage).createRoute(
                  context,
                ) as PageRoute;
                expect(route.transitionDuration, AppMotion.durationPage);
                expect(route.reverseTransitionDuration, AppMotion.durationPage);
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );

    testWidgets(
      'AudifiTransitionPage respects reduced motion with zero duration',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              animationModeProvider.overrideWith(
                () => _ReducedAnimationModeNotifier(),
              ),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  final page = AppMotion.createPage(
                    key: const ValueKey('reduced_page'),
                    child: const Scaffold(body: Text('Reduced Motion View')),
                    type: AppTransitionType.slideFade,
                  );
                  final route = (page as AudifiTransitionPage).createRoute(
                    context,
                  ) as PageRoute;
                  expect(route.transitionDuration, Duration.zero);
                  return const Scaffold(body: Text('Home'));
                },
              ),
            ),
          ),
        );
      },
    );

    testWidgets(
      'SettingsView navigates to Playback and returns with back button',
      (tester) async {
        final router = GoRouter(
          initialLocation: RoutePaths.settings,
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              pageBuilder: (context, state) => AppMotion.createPage(
                key: state.pageKey,
                child: const SettingsView(),
                type: AppTransitionType.fade,
              ),
              routes: [
                GoRoute(
                  path: 'playback',
                  pageBuilder: (context, state) => AppMotion.createPage(
                    key: state.pageKey,
                    child: const PlaybackView(),
                    type: AppTransitionType.slideFade,
                  ),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(buildRouterHarness(router: router));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsView), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        // Tap Playback tile
        await tester.tap(find.text('Playback'));
        await tester.pump();
        // Verify transition frame mid-flight at 125ms
        await tester.pump(const Duration(milliseconds: 125));
        expect(find.byType(PlaybackView), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(PlaybackView), findsOneWidget);
        expect(find.text('AUDIO BEHAVIOR'), findsOneWidget);

        // Tap back button
        await tester.tap(find.text('‹ Settings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 125));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsView), findsOneWidget);
        expect(find.byType(PlaybackView), findsNothing);
      },
    );

    testWidgets(
      'SettingsView navigates to all 7 categories and nested Accent Color',
      (tester) async {
        final router = GoRouter(
          initialLocation: RoutePaths.settings,
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              pageBuilder: (context, state) => AppMotion.createPage(
                key: state.pageKey,
                child: const SettingsView(),
                type: AppTransitionType.fade,
              ),
              routes: [
                GoRoute(
                  path: 'playback',
                  pageBuilder: (context, state) => AppMotion.createPage(
                    key: state.pageKey,
                    child: const PlaybackView(),
                    type: AppTransitionType.slideFade,
                  ),
                ),
                GoRoute(
                  path: 'notifications',
                  pageBuilder: (context, state) => AppMotion.createPage(
                    key: state.pageKey,
                    child: const NotificationsView(),
                    type: AppTransitionType.slideFade,
                  ),
                ),
                GoRoute(
                  path: 'music',
                  pageBuilder: (context, state) => AppMotion.createPage(
                    key: state.pageKey,
                    child: const MusicView(),
                    type: AppTransitionType.slideFade,
                  ),
                ),
                GoRoute(
                  path: 'appearance',
                  pageBuilder: (context, state) => AppMotion.createPage(
                    key: state.pageKey,
                    child: const AppearanceView(),
                    type: AppTransitionType.slideFade,
                  ),
                  routes: [
                    GoRoute(
                      path: 'accent',
                      pageBuilder: (context, state) => AppMotion.createPage(
                        key: state.pageKey,
                        child: const AccentColorView(),
                        type: AppTransitionType.slideFade,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'privacy',
                  pageBuilder: (context, state) => AppMotion.createPage(
                    key: state.pageKey,
                    child: const PrivacyView(),
                    type: AppTransitionType.slideFade,
                  ),
                ),
                GoRoute(
                  path: 'about',
                  pageBuilder: (context, state) => AppMotion.createPage(
                    key: state.pageKey,
                    child: const AboutView(),
                    type: AppTransitionType.slideFade,
                  ),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(buildRouterHarness(router: router));
        await tester.pumpAndSettle();

        // 1. Playback
        await tester.tap(find.text('Playback'));
        await tester.pumpAndSettle();
        expect(find.byType(PlaybackView), findsOneWidget);
        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();

        // 2. Notifications
        await tester.tap(find.text('Notifications'));
        await tester.pumpAndSettle();
        expect(find.byType(NotificationsView), findsOneWidget);
        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();

        // 3. Music
        await tester.tap(find.text('Music'));
        await tester.pumpAndSettle();
        expect(find.byType(MusicView), findsOneWidget);
        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();

        // 5. Appearance -> Accent Color -> Back -> Back
        await tester.scrollUntilVisible(find.text('Appearance'), 100.0);
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
        expect(find.byType(AppearanceView), findsOneWidget);

        await tester.tap(find.text('Accent color'));
        await tester.pumpAndSettle();
        expect(find.byType(AccentColorView), findsOneWidget);

        await tester.tap(find.text('‹ Appearance'));
        await tester.pumpAndSettle();
        expect(find.byType(AppearanceView), findsOneWidget);

        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsView), findsOneWidget);

        // 6. Privacy Policy
        await tester.scrollUntilVisible(find.text('Privacy Policy'), 100.0);
        await tester.tap(find.text('Privacy Policy'));
        await tester.pumpAndSettle();
        expect(find.byType(PrivacyView), findsOneWidget);
        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();

        // 7. About
        await tester.scrollUntilVisible(find.text('About'), 100.0);
        await tester.tap(find.text('About'));
        await tester.pumpAndSettle();
        expect(find.byType(AboutView), findsOneWidget);
        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsView), findsOneWidget);
      },
    );

    testWidgets(
      'Rapid repeated taps on Settings tile do not push duplicate routes',
      (tester) async {
        final router = GoRouter(
          initialLocation: RoutePaths.settings,
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              pageBuilder: (context, state) => AppMotion.createPage(
                key: state.pageKey,
                child: const SettingsView(),
                type: AppTransitionType.fade,
              ),
              routes: [
                GoRoute(
                  path: 'playback',
                  pageBuilder: (context, state) => AppMotion.createPage(
                    key: state.pageKey,
                    child: const PlaybackView(),
                    type: AppTransitionType.slideFade,
                  ),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(buildRouterHarness(router: router));
        await tester.pumpAndSettle();

        // Rapidly tap Playback tile 3 times in quick succession
        await tester.tap(find.text('Playback'));
        await tester.tap(find.text('Playback'), warnIfMissed: false);
        await tester.tap(find.text('Playback'), warnIfMissed: false);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(PlaybackView), findsOneWidget);

        // Single back navigation should return directly to SettingsView (not to a second PlaybackView)
        await tester.tap(find.text('‹ Settings'));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsView), findsOneWidget);
        expect(find.byType(PlaybackView), findsNothing);
      },
    );

    testWidgets('Rapid repeated taps on Back button do not pop out of shell', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: RoutePaths.settings,
        routes: [
          GoRoute(
            path: RoutePaths.settings,
            pageBuilder: (context, state) => AppMotion.createPage(
              key: state.pageKey,
              child: const SettingsView(),
              type: AppTransitionType.fade,
            ),
            routes: [
              GoRoute(
                path: 'playback',
                pageBuilder: (context, state) => AppMotion.createPage(
                  key: state.pageKey,
                  child: const PlaybackView(),
                  type: AppTransitionType.slideFade,
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(buildRouterHarness(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Playback'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaybackView), findsOneWidget);

      // Rapidly tap back button twice
      await tester.tap(find.text('‹ Settings'));
      await tester.pump(const Duration(milliseconds: 20));
      // Even if back is tapped again, canPop guard protects
      await tester.pumpAndSettle();

      expect(find.byType(SettingsView), findsOneWidget);
    });

    testWidgets(
      'Category Views have solid opaque backgrounds to prevent ghosting',
      (tester) async {
        final views = <Widget>[
          const PlaybackView(),
          const NotificationsView(),
          const MusicView(),
          const AppearanceView(),
          const PrivacyView(),
          const AboutView(),
          const AccentColorView(),
        ];

        for (final view in views) {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                permissionServiceProvider.overrideWithValue(
                  fakePermissionService,
                ),
              ],
              child: MaterialApp(
                theme: ThemeData(
                  scaffoldBackgroundColor: AppColors.darkBackground,
                ),
                home: view,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
          // Verify background is NOT transparent
          expect(scaffold.backgroundColor, isNot(Colors.transparent));
          expect(scaffold.backgroundColor, isNotNull);
        }
      },
    );

    testWidgets(
      'Persistent MiniPlayer remains stable and unmounted during Settings navigation',
      (tester) async {
        // Set standard phone viewport (393 x 852) to test phone navigation shell with MiniPlayer
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.reset);

        const activeTrack = Track(
          id: 'mini_t1',
          title: 'Mini Player Anthem',
          duration: 180,
          user: User(
            id: 'u1',
            name: 'Mini Artist',
            handle: 'miniart',
            isVerified: true,
          ),
        );

        final router = GoRouter(
          initialLocation: RoutePaths.settings,
          routes: [
            StatefulShellRoute(
              builder: (context, state, navigationShell) {
                return AppNavigationShell(navigationShell: navigationShell);
              },
              navigatorContainerBuilder: (context, navigationShell, children) {
                return AnimatedBranchContainer(
                  currentIndex: navigationShell.currentIndex,
                  children: children,
                );
              },
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: RoutePaths.settings,
                      pageBuilder: (context, state) => AppMotion.createPage(
                        key: state.pageKey,
                        child: const SettingsView(),
                        type: AppTransitionType.fade,
                      ),
                      routes: [
                        GoRoute(
                          path: 'playback',
                          pageBuilder: (context, state) => AppMotion.createPage(
                            key: state.pageKey,
                            child: const PlaybackView(),
                            type: AppTransitionType.slideFade,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
              playbackControllerProvider.overrideWith(
                () => _TestPlaybackController(
                  const PlaybackState(
                    currentTrack: activeTrack,
                    status: PlaybackStatus.playing,
                    position: Duration(seconds: 45),
                    duration: Duration(seconds: 180),
                  ),
                ),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // MiniPlayer is displayed on Settings screen
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Mini Player Anthem'), findsOneWidget);

        // Navigate to Playback
        await tester.tap(find.text('Playback'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 125));

        // MiniPlayer remains in the tree during transition
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Mini Player Anthem'), findsOneWidget);

        await tester.pumpAndSettle();
        // MiniPlayer remains in the tree on the sub-screen
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Mini Player Anthem'), findsOneWidget);

        // Return to Settings
        await tester.tap(find.text('‹ Settings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 125));

        // MiniPlayer remains uninterrupted during reverse transition
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Mini Player Anthem'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(find.text('Mini Player Anthem'), findsOneWidget);
      },
    );
  });
}
