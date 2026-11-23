import 'dart:async';

import 'package:audifi/core/network/connectivity_service.dart';
import 'package:audifi/core/network/dio_client.dart';
import 'package:audifi/core/network/internet_connection_service.dart';
import 'package:audifi/core/network/network_providers.dart';
import 'package:audifi/core/permissions/permission_providers.dart';
import 'package:audifi/core/permissions/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audifi/features/downloads/data/datasources/download_local_data_source.dart';
import 'package:audifi/features/downloads/data/datasources/download_remote_data_source.dart';
import 'package:audifi/features/downloads/presentation/controllers/download_controller.dart';
import 'package:audifi/features/local_files/data/datasources/local_files_local_data_source.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/domain/entities/playback_state.dart';
import 'package:audifi/features/playback/domain/repositories/playback_repository.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playback/presentation/controllers/playback_controller.dart';
import 'package:audifi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeConnectivityService implements ConnectivityService {
  final StreamController<Set<NetworkConnectionType>> _controller =
      StreamController<Set<NetworkConnectionType>>.broadcast();

  Set<NetworkConnectionType> currentTypes;

  FakeConnectivityService({
    this.currentTypes = const {NetworkConnectionType.wifi},
  });

  @override
  Future<Set<NetworkConnectionType>> checkConnectivity() async => currentTypes;

  @override
  Stream<Set<NetworkConnectionType>> get onConnectivityChanged =>
      _controller.stream;

  void emit(Set<NetworkConnectionType> types) {
    currentTypes = types;
    _controller.add(types);
  }

  void dispose() {
    _controller.close();
  }
}

class FakeInternetConnectionService implements InternetConnectionService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool currentAccess;

  FakeInternetConnectionService({this.currentAccess = true});

  @override
  Future<bool> hasInternetAccess() async => currentAccess;

  @override
  Stream<bool> get onInternetAccessChanged => _controller.stream;

  void emit(bool hasAccess) {
    currentAccess = hasAccess;
    _controller.add(hasAccess);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class MockAudioPlayerService implements AudioPlayerService {
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _processingController =
      StreamController<EngineProcessingState>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  String? loadedUrl;
  bool isPlayingState = false;
  Duration currentPositionValue = Duration.zero;
  Duration? currentDurationValue = const Duration(seconds: 180);
  int playCallCount = 0;
  int pauseCallCount = 0;

  @override
  Stream<EngineProcessingState> get processingStateStream =>
      _processingController.stream;
  @override
  Stream<bool> get playingStream => _playingController.stream;
  @override
  Stream<Duration> get positionStream => _positionController.stream;
  @override
  Stream<Duration> get bufferedPositionStream => _bufferedController.stream;
  @override
  Stream<Duration?> get durationStream => _durationController.stream;
  @override
  Stream<void> get completedStream => _completedController.stream;

  @override
  Duration get currentPosition => currentPositionValue;
  @override
  Duration? get currentDuration => currentDurationValue;
  @override
  bool get isPlaying => isPlayingState;

  @override
  Future<void> setAudioUrl(String url) async {
    loadedUrl = url;
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> play() async {
    playCallCount++;
    isPlayingState = true;
    _playingController.add(true);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    pauseCallCount++;
    isPlayingState = false;
    _playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    currentPositionValue = position;
    _positionController.add(position);
  }

  @override
  Future<void> stop() async {
    isPlayingState = false;
    currentPositionValue = Duration.zero;
    _playingController.add(false);
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {
    await _positionController.close();
    await _bufferedController.close();
    await _durationController.close();
    await _playingController.close();
    await _processingController.close();
    await _completedController.close();
  }
}

class MockPlaybackRepo implements PlaybackRepository {
  int resolveStreamUrlCallCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    resolveStreamUrlCallCount++;
    return 'https://audius.co/stream/$trackId.mp3';
  }

  @override
  Future<void> prefetchStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {}

  @override
  String? get currentPredictedTrackId => null;

  @override
  bool hasPrediction(String trackId) => false;

  @override
  void invalidatePrediction({String? reason}) {}

  @override
  Future<void> saveQueue({
    required List<Track> tracks,
    required int currentIndex,
  }) async {}

  @override
  Future<({List<Track> tracks, int currentIndex})?> restoreQueue() async =>
      null;

  @override
  Future<void> clearSavedQueue() async {}
}

class FakeDownloadLocalDataSource implements DownloadLocalDataSource {
  final Set<String> downloadedIds;
  FakeDownloadLocalDataSource([this.downloadedIds = const {}]);

  @override
  bool isTrackDownloaded(String trackId) => downloadedIds.contains(trackId);

  @override
  Future<String> getTempFilePath(String trackId) async => '/tmp/$trackId.tmp';

  @override
  Future<String> getTargetFilePath(String trackId) async => '/tmp/$trackId.mp3';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalFilesLocalDataSource implements LocalFilesLocalDataSource {
  final Set<String> localIds;
  FakeLocalFilesLocalDataSource([this.localIds = const {}]);

  @override
  bool isLocalFile(String trackId) => localIds.contains(trackId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDownloadRemoteDataSource implements DownloadRemoteDataSource {
  @override
  DioClient get client => DioClient(rawDio: Dio());

  @override
  Future<String> getDownloadUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async {
    return 'https://download.audius.co/file/$trackId.mp3';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePermissionService implements PermissionService {
  @override
  Future<bool> isNotificationGranted() async => true;

  @override
  Future<PermissionStatus> checkNotificationPermission() async =>
      PermissionStatus.granted;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const remoteTrack = Track(
    id: 'remote_track_1',
    title: 'Remote Audius Track',
    duration: 180,
  );

  const downloadedTrack = Track(
    id: 'downloaded_track_1',
    title: 'Downloaded Track',
    duration: 200,
  );

  const localFileTrack = Track(
    id: 'local_file_track_1',
    title: 'Imported Local File',
    duration: 240,
  );

  late ProviderContainer container;
  late MockAudioPlayerService mockPlayer;
  late MockPlaybackRepo mockRepo;
  late FakeConnectivityService fakeConnectivity;
  late FakeInternetConnectionService fakeInternet;
  late FakeDownloadLocalDataSource fakeDownloads;
  late FakeLocalFilesLocalDataSource fakeLocalFiles;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'stream_on_mobile_data': true});

    mockPlayer = MockAudioPlayerService();
    mockRepo = MockPlaybackRepo();
    fakeConnectivity = FakeConnectivityService(
      currentTypes: {NetworkConnectionType.wifi},
    );
    fakeInternet = FakeInternetConnectionService(currentAccess: true);
    fakeDownloads = FakeDownloadLocalDataSource({'downloaded_track_1'});
    fakeLocalFiles = FakeLocalFilesLocalDataSource({'local_file_track_1'});

    container = ProviderContainer(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(mockPlayer),
        playbackRepositoryProvider.overrideWithValue(mockRepo),
        connectivityServiceProvider.overrideWithValue(fakeConnectivity),
        internetConnectionServiceProvider.overrideWithValue(fakeInternet),
        downloadLocalDataSourceProvider.overrideWithValue(fakeDownloads),
        localFilesLocalDataSourceProvider.overrideWithValue(fakeLocalFiles),
        downloadRemoteDataSourceProvider.overrideWithValue(
          FakeDownloadRemoteDataSource(),
        ),
        permissionServiceProvider.overrideWithValue(FakePermissionService()),
      ],
    );

    // Eagerly initialize networkStateProvider
    container.read(networkStateProvider);
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() {
    fakeConnectivity.dispose();
    fakeInternet.dispose();
    mockPlayer.dispose();
    container.dispose();
  });

  group('Mobile Data Preference & Streaming Policy Tests', () {
    test('1. Streaming on Wi-Fi proceeds normally when mobile data preference is disabled', () async {
      // Configure preference: disabled
      container
          .read(settingsControllerProvider.notifier)
          .setStreamOnMobileData(false);
      expect(
        container.read(settingsControllerProvider).streamOnMobileData,
        isFalse,
      );

      // Verify network is Wi-Fi
      expect(container.read(networkStateProvider).isWifi, isTrue);
      expect(container.read(networkStateProvider).isMobile, isFalse);

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(remoteTrack);

      final state = container.read(playbackControllerProvider);
      expect(state.error, isNull);
      expect(state.currentTrack?.id, equals(remoteTrack.id));
      expect(mockRepo.resolveStreamUrlCallCount, equals(1));
      expect(mockPlayer.playCallCount, equals(1));
    });

    test('2. Streaming on mobile data proceeds normally when mobile data preference is enabled', () async {
      // Configure preference: enabled
      container
          .read(settingsControllerProvider.notifier)
          .setStreamOnMobileData(true);
      expect(
        container.read(settingsControllerProvider).streamOnMobileData,
        isTrue,
      );

      // Switch network to Mobile Data
      fakeConnectivity.emit({NetworkConnectionType.mobile});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(networkStateProvider).isMobile, isTrue);

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(remoteTrack);

      final state = container.read(playbackControllerProvider);
      expect(state.error, isNull);
      expect(state.currentTrack?.id, equals(remoteTrack.id));
      expect(mockRepo.resolveStreamUrlCallCount, equals(1));
      expect(mockPlayer.playCallCount, equals(1));
    });

    test('3. Streaming on mobile data is prevented with clear error when preference is disabled', () async {
      // Configure preference: disabled
      container
          .read(settingsControllerProvider.notifier)
          .setStreamOnMobileData(false);
      expect(
        container.read(settingsControllerProvider).streamOnMobileData,
        isFalse,
      );

      // Switch network to Mobile Data
      fakeConnectivity.emit({NetworkConnectionType.mobile});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(networkStateProvider).isMobile, isTrue);

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(remoteTrack);

      final state = container.read(playbackControllerProvider);
      expect(state.status, equals(PlaybackStatus.error));
      expect(state.error, isNotNull);
      expect(state.error?.code, equals('mobile_data_restricted'));
      expect(
        state.error?.message,
        equals('Streaming over mobile data is disabled in Settings.'),
      );

      // Verify no network stream was requested and player did not play
      expect(mockRepo.resolveStreamUrlCallCount, equals(0));
      expect(mockPlayer.playCallCount, equals(0));

      // Verify queue still holds the track context
      expect(state.currentTrack?.id, equals(remoteTrack.id));
    });

    test('4. Local-file playback on mobile data is permitted when preference is disabled', () async {
      // Configure preference: disabled
      container
          .read(settingsControllerProvider.notifier)
          .setStreamOnMobileData(false);

      // Switch network to Mobile Data
      fakeConnectivity.emit({NetworkConnectionType.mobile});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(networkStateProvider).isMobile, isTrue);

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(localFileTrack);

      final state = container.read(playbackControllerProvider);
      expect(state.error, isNull);
      expect(state.currentTrack?.id, equals(localFileTrack.id));
      expect(mockPlayer.playCallCount, equals(1));
    });

    test('5. Offline downloaded-track playback on mobile data is permitted when preference is disabled', () async {
      // Configure preference: disabled
      container
          .read(settingsControllerProvider.notifier)
          .setStreamOnMobileData(false);

      // Switch network to Mobile Data
      fakeConnectivity.emit({NetworkConnectionType.mobile});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(networkStateProvider).isMobile, isTrue);

      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(downloadedTrack);

      final state = container.read(playbackControllerProvider);
      expect(state.error, isNull);
      expect(state.currentTrack?.id, equals(downloadedTrack.id));
      expect(mockPlayer.playCallCount, equals(1));
    });

    test('6. Wi-Fi to mobile transition pauses active remote playback and sets error when preference is disabled', () async {
      // Configure preference: disabled
      container
          .read(settingsControllerProvider.notifier)
          .setStreamOnMobileData(false);

      // Start playback on Wi-Fi
      final controller = container.read(playbackControllerProvider.notifier);
      await controller.playTrack(remoteTrack);

      var state = container.read(playbackControllerProvider);
      expect(state.isPlaying, isTrue);
      expect(state.error, isNull);

      // Wi-Fi lost, network transitions to Mobile Data
      fakeConnectivity.emit({NetworkConnectionType.mobile});
      await Future<void>.delayed(Duration.zero);

      state = container.read(playbackControllerProvider);
      expect(state.status, equals(PlaybackStatus.paused));
      expect(state.error?.code, equals('mobile_data_restricted'));
      expect(
        state.error?.message,
        contains('Mobile data streaming is disabled in Settings.'),
      );
      expect(mockPlayer.pauseCallCount, equals(1));

      // Transition back to Wi-Fi clears the mobile data restricted error
      fakeConnectivity.emit({NetworkConnectionType.wifi});
      await Future<void>.delayed(Duration.zero);

      state = container.read(playbackControllerProvider);
      expect(state.error, isNull);
    });

    test(
      '7. Downloads execute independently of streamOnMobileData preference',
      () async {
        // Disable streaming on mobile data
        container
            .read(settingsControllerProvider.notifier)
            .setStreamOnMobileData(false);
        expect(
          container.read(settingsControllerProvider).streamOnMobileData,
          isFalse,
        );

        // Set network to Mobile Data with active internet
        fakeConnectivity.emit({NetworkConnectionType.mobile});
        await Future<void>.delayed(Duration.zero);
        expect(container.read(networkStateProvider).isMobile, isTrue);

        // Download controller should NOT reject the download based on streamOnMobileData
        final downloadController = container.read(
          downloadControllerProvider.notifier,
        );
        final downloadTrack = const Track(
          id: 'new_download_track',
          title: 'New Track to Download',
          duration: 150,
          isDownloadable: true,
        );

        // We call downloadTrack - verify it does NOT reject with mobile data message
        await downloadController.downloadTrack(downloadTrack);

        final progress = container.read(
          downloadProgressProvider(downloadTrack.id),
        );
        if (progress != null) {
          expect(
            progress.errorMessage,
            isNot(contains('Mobile data downloads are disabled in Settings')),
          );
        }
      },
    );
  });
}
