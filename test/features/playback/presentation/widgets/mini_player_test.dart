import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/playback/presentation/widgets/mini_player/mini_player.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../test_helpers/stub_repositories.dart';

class TestPlaybackController extends PlaybackController {
  TestPlaybackController(this.initialState);

  final PlaybackState initialState;

  @override
  PlaybackState build() {
    return initialState;
  }

  @override
  Future<void> togglePlayPause() async {
    state = state.copyWith(
      status: state.isPlaying ? PlaybackStatus.paused : PlaybackStatus.playing,
    );
  }
}

void main() {
  group('MiniPlayer Widget', () {
    testWidgets('renders nothing when there is no current track', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: createStubRepositoryOverrides(),
          child: const MaterialApp(
            home: Scaffold(bottomNavigationBar: MiniPlayer()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.text('Play'), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets(
      'renders track title, artist, and controls when track is loaded',
      (tester) async {
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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...createStubRepositoryOverrides(),
              playbackControllerProvider.overrideWith(
                () => TestPlaybackController(
                  const PlaybackState(
                    currentTrack: activeTrack,
                    status: PlaybackStatus.playing,
                    position: Duration(seconds: 45),
                    duration: Duration(seconds: 180),
                  ),
                ),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(bottomNavigationBar: MiniPlayer()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mini Player Anthem'), findsOneWidget);
        expect(find.text('Mini Artist'), findsOneWidget);
        expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
        expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
        expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      },
    );

    testWidgets('play/pause button toggles when tapped', (tester) async {
      const activeTrack = Track(
        id: 'mini_t2',
        title: 'Toggle Track',
        duration: 200,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...createStubRepositoryOverrides(),
            playbackControllerProvider.overrideWith(
              () => TestPlaybackController(
                const PlaybackState(
                  currentTrack: activeTrack,
                  status: PlaybackStatus.paused,
                  duration: Duration(seconds: 200),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(bottomNavigationBar: MiniPlayer()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });
  });
}
