import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audifi/features/downloads/domain/entities/downloaded_track.dart';
import 'package:audifi/features/downloads/presentation/controllers/download_controller.dart';
import 'package:audifi/features/downloads/presentation/widgets/download_button.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';

class _TestDownloadedTracksNotifier extends DownloadedTracksNotifier {
  _TestDownloadedTracksNotifier(this._tracks);
  final List<DownloadedTrack> _tracks;

  @override
  List<DownloadedTrack> build() => _tracks;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadButton Widget Tests', () {
    const authTrack = Track(
      id: 'btn_auth',
      title: 'Authorized Beat',
      isDownloadable: true,
      isDownloadGated: false,
    );

    const disabledTrack = Track(
      id: 'btn_disabled',
      title: 'Disabled Beat',
      isDownloadable: false,
      isDownloadGated: false,
    );

    const gatedTrack = Track(
      id: 'btn_gated',
      title: 'Gated Beat',
      isDownloadable: true,
      isDownloadGated: true,
    );

    testWidgets('renders enabled download button for authorized track', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trackDownloadPermissionProvider(authTrack).overrideWith(
              (ref) => Future.value(TrackDownloadPermission.authorized),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DownloadButton(track: authTrack)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNotNull);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byTooltip('Download for offline playback'), findsOneWidget);
    });

    testWidgets(
      'renders inactive disabled icon button for creator-disabled track',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              trackDownloadPermissionProvider(disabledTrack).overrideWith(
                (ref) => Future.value(TrackDownloadPermission.disabled),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: DownloadButton(track: disabledTrack)),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        final button = tester.widget<IconButton>(find.byType(IconButton));
        expect(button.onPressed, isNull);
        expect(find.byIcon(Icons.file_download_off_rounded), findsOneWidget);
        expect(
          find.byTooltip("Downloads aren't available for this track."),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders inactive lock icon button for gated track', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trackDownloadPermissionProvider(gatedTrack).overrideWith(
              (ref) => Future.value(TrackDownloadPermission.gated),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DownloadButton(track: gatedTrack)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(
        find.byTooltip('This download requires creator access.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders downloaded checkmark state when track is already saved',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              downloadedTracksProvider.overrideWith(
                () => _TestDownloadedTracksNotifier([
                  DownloadedTrack(
                    track: authTrack,
                    localFilePath: '/tmp/test.mp3',
                    fileSizeBytes: 1024,
                    downloadedAt: DateTime.now(),
                  ),
                ]),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: DownloadButton(track: authTrack)),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
        expect(find.byTooltip('Downloaded. Tap to remove'), findsOneWidget);
      },
    );

    testWidgets('renders retry button when permission check encounters error', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trackDownloadPermissionProvider(authTrack).overrideWith(
              (ref) => Future.value(TrackDownloadPermission.error),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DownloadButton(track: authTrack)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(
        find.byTooltip('Retry checking download permissions'),
        findsOneWidget,
      );
    });
  });
}
