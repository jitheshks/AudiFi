import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:dio/dio.dart';
import 'package:audifi/features/albums/domain/entities/album.dart';
import 'package:audifi/features/artists/data/repositories/user_repository_impl.dart';
import 'package:audifi/core/permissions/permission_providers.dart';
import 'package:audifi/core/permissions/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/artists/domain/repositories/user_repository.dart';
import 'package:audifi/features/library/data/repositories/library_repository_impl.dart';
import 'package:audifi/features/library/domain/entities/user_library.dart';
import 'package:audifi/features/library/domain/repositories/library_repository.dart';
import 'package:audifi/features/playback/data/repositories/playback_repository_impl.dart';
import 'package:audifi/features/playback/data/services/audifi_audio_handler.dart';
import 'package:audifi/features/playback/data/services/audio_player_service.dart';
import 'package:audifi/features/playback/domain/repositories/playback_repository.dart';
import 'package:audifi/features/playback/presentation/controllers/audio_player_providers.dart';
import 'package:audifi/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:audifi/features/playlists/domain/entities/playlist.dart';
import 'package:audifi/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:audifi/features/search/data/repositories/search_repository_impl.dart';
import 'package:audifi/features/search/domain/entities/search_result.dart';
import 'package:audifi/features/search/domain/repositories/search_repository.dart';
import 'package:audifi/features/tracks/data/repositories/track_repository_impl.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/features/tracks/domain/repositories/track_repository.dart';
import 'package:audifi/shared/models/artwork.dart';

class StubTrackRepository implements TrackRepository {
  String? lastGenre;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Track>> getTrendingTracks({
    int limit = 20,
    int offset = 0,
    String? genre,
    String time = 'week',
  }) async {
    lastGenre = genre;
    return [
      Track(
        id: 't1',
        title: 'Trending ${genre ?? "All"}',
        duration: 180,
        playCount: 15400,
        user: const User(id: 'u1', name: 'Audius Star', handle: 'audistar'),
        artwork: const Artwork(),
      ),
    ];
  }

  @override
  Future<List<Track>> getLatestTracks({int limit = 20, int offset = 0}) async {
    return [
      const Track(
        id: 'latest_t1',
        title: 'Latest Track',
        duration: 210,
        playCount: 3200,
        user: User(id: 'u2', name: 'Fresh Producer', handle: 'freshprod'),
        artwork: Artwork(),
      ),
    ];
  }

  @override
  Future<List<Track>> getTrendingUndergroundTracks({
    int limit = 20,
    int offset = 0,
  }) async {
    return [
      const Track(
        id: 'underground_t1',
        title: 'Underground Gem',
        duration: 190,
        user: User(id: 'u3', name: 'Indie Creator', handle: 'indie'),
      ),
    ];
  }

  @override
  Future<List<Track>> getUserTracks(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return [
      Track(
        id: 'art_track_1',
        title: 'Track by $userId',
        duration: 195,
        user: User(id: userId, name: 'Artist $userId', handle: 'art_$userId'),
      ),
    ];
  }
}

class StubPlaylistRepository implements PlaylistRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Playlist>> getTrendingPlaylists({
    int limit = 20,
    int offset = 0,
    String time = 'week',
  }) async {
    return [
      const Playlist(
        id: 'pl1',
        playlistName: 'Trending Playlist',
        totalPlayCount: 50000,
        user: User(id: 'u_curator', name: 'Curator X', handle: 'curatorx'),
      ),
    ];
  }

  @override
  Future<Playlist?> getPlaylist(String playlistId) async {
    if (playlistId == '404') return null;
    return Playlist(
      id: playlistId,
      playlistName: 'Playlist $playlistId',
      user: const User(id: 'u_owner', name: 'Playlist Owner', handle: 'owner'),
    );
  }

  @override
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    return [
      Track(
        id: 'pl_tr_1',
        title: 'Track of $playlistId',
        duration: 200,
        user: const User(id: 'u_tr', name: 'Track Artist', handle: 'trackart'),
      ),
    ];
  }
}

class StubUserRepository implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<User?> getUser(String userId) async {
    if (userId == '404') return null;
    return User(
      id: userId,
      name: 'Artist $userId',
      handle: 'art_$userId',
      bio: 'Electronic & Synthwave creator on Audius.',
      followerCount: 12500,
      trackCount: 24,
    );
  }

  @override
  Future<List<User>> getTopUsers({int limit = 12, int offset = 0}) async {
    return List.generate(
      limit.clamp(1, 5),
      (i) => User(
        id: 'top_user_$i',
        name: 'Top Artist $i',
        handle: 'top_artist_$i',
        trackCount: 5 + i,
      ),
    );
  }

  @override
  Future<List<User>> getRelatedUsers(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    return [
      const User(
        id: 'related_u1',
        name: 'Similar Artist 1',
        handle: 'similar1',
      ),
      const User(
        id: 'related_u2',
        name: 'Similar Artist 2',
        handle: 'similar2',
      ),
    ];
  }
}

class StubSearchRepository implements SearchRepository {
  Completer<SearchResult>? delayedCompleter;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<SearchResult> search(
    String query, {
    String? kind,
    int limit = 20,
    int offset = 0,
    bool? includePurchaseable,
  }) async {
    if (delayedCompleter != null) {
      return delayedCompleter!.future;
    }
    return SearchResult(
      tracks: [
        Track(
          id: 'res_t1',
          title: 'Result for $query',
          user: const User(
            id: 'u_res',
            name: 'Result Artist',
            handle: 'resart',
          ),
        ),
      ],
      users: [
        User(id: 'u_res_1', name: 'Artist $query', handle: 'handle_$query'),
      ],
      playlists: [
        Playlist(
          id: 'pl_res_1',
          playlistName: 'Playlist of $query',
          user: const User(id: 'u_pl', name: 'Curator', handle: 'curator'),
        ),
      ],
    );
  }
}

class StubPlaybackRepository implements PlaybackRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String> resolveStreamUrl(
    String trackId, {
    CancelToken? cancelToken,
  }) async => 'https://mock.audius.co/stream/$trackId.mp3';

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

class StubAudioPlayerService implements AudioPlayerService {
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _processingController =
      StreamController<EngineProcessingState>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(seconds: 180);

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
  Duration get currentPosition => _position;
  @override
  Duration? get currentDuration => _duration;
  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> setAudioUrl(String url) async {
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> setAudioSource(AudioSource source) async {
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    _playingController.add(true);
    _processingController.add(EngineProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _playingController.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    _positionController.add(position);
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _position = Duration.zero;
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

class StubLibraryRepository implements LibraryRepository {
  UserLibrary libraryState = UserLibrary.empty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<UserLibrary> getLibrary() async => libraryState;

  @override
  Future<void> toggleLikeTrack(Track track) async {
    final exists = libraryState.isTrackLiked(track.id);
    final updated = exists
        ? libraryState.likedTracks.where((t) => t.id != track.id).toList()
        : [track, ...libraryState.likedTracks];
    libraryState = libraryState.copyWith(likedTracks: updated);
  }

  @override
  Future<void> toggleSaveAlbum(Album album) async {
    final exists = libraryState.isAlbumSaved(album.id);
    final updated = exists
        ? libraryState.savedAlbums.where((a) => a.id != album.id).toList()
        : [album, ...libraryState.savedAlbums];
    libraryState = libraryState.copyWith(savedAlbums: updated);
  }

  @override
  Future<void> toggleSavePlaylist(Playlist playlist) async {
    final exists = libraryState.isPlaylistSaved(playlist.id);
    final updated = exists
        ? libraryState.savedPlaylists.where((p) => p.id != playlist.id).toList()
        : [playlist, ...libraryState.savedPlaylists];
    libraryState = libraryState.copyWith(savedPlaylists: updated);
  }

  @override
  Future<void> toggleFollowArtist(User artist) async {
    final exists = libraryState.isArtistFollowed(artist.id);
    final updated = exists
        ? libraryState.followedArtists.where((u) => u.id != artist.id).toList()
        : [artist, ...libraryState.followedArtists];
    libraryState = libraryState.copyWith(followedArtists: updated);
  }

  @override
  Future<void> clearLibrary() async {
    libraryState = UserLibrary.empty;
  }
}

class StubAudioHandler extends AudifiAudioHandler {
  StubAudioHandler({AudioPlayerService? playerService})
    : super(playerService: playerService ?? StubAudioPlayerService());
}

class StubPermissionService implements PermissionService {
  final PermissionStatus defaultStatus;
  const StubPermissionService({this.defaultStatus = PermissionStatus.granted});

  @override
  Future<PermissionStatus> checkStatus(Permission permission) async =>
      defaultStatus;

  @override
  Future<bool> isGranted(Permission permission) async =>
      defaultStatus.isGranted;

  @override
  Future<bool> isDenied(Permission permission) async => defaultStatus.isDenied;

  @override
  Future<bool> isPermanentlyDenied(Permission permission) async =>
      defaultStatus.isPermanentlyDenied;

  @override
  Future<bool> isRestricted(Permission permission) async =>
      defaultStatus.isRestricted;

  @override
  Future<bool> shouldShowRationale(Permission permission) async => false;

  @override
  Future<PermissionResult> request(Permission permission) async =>
      PermissionResult(permission: permission, status: defaultStatus);

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<bool> openNotificationSettings() async => true;

  @override
  Future<PermissionStatus> checkNotificationPermission() async => defaultStatus;

  @override
  Future<bool> isNotificationGranted() async => defaultStatus.isGranted;

  @override
  Future<PermissionResult> requestNotificationPermission() async =>
      PermissionResult(
        permission: Permission.notification,
        status: defaultStatus,
      );
}

List<Override> createStubRepositoryOverrides({
  Map<String, Object>? initialPreferences,
  TrackRepository? trackRepo,
  PlaylistRepository? playlistRepo,
  UserRepository? userRepo,
  SearchRepository? searchRepo,
  PlaybackRepository? playbackRepo,
  AudioPlayerService? audioPlayerService,
  AudioHandler? audioHandler,
  LibraryRepository? libraryRepo,
  PermissionService? permissionService,
}) {
  if (initialPreferences != null) {
    SharedPreferences.setMockInitialValues(initialPreferences);
  } else {
    SharedPreferences.setMockInitialValues({});
  }
  final player = audioPlayerService ?? StubAudioPlayerService();
  return [
    trackRepositoryProvider.overrideWithValue(
      trackRepo ?? StubTrackRepository(),
    ),
    playlistRepositoryProvider.overrideWithValue(
      playlistRepo ?? StubPlaylistRepository(),
    ),
    userRepositoryProvider.overrideWithValue(userRepo ?? StubUserRepository()),
    searchRepositoryProvider.overrideWithValue(
      searchRepo ?? StubSearchRepository(),
    ),
    playbackRepositoryProvider.overrideWithValue(
      playbackRepo ?? StubPlaybackRepository(),
    ),
    audioPlayerServiceProvider.overrideWithValue(player),
    audioHandlerProvider.overrideWithValue(
      audioHandler ?? StubAudioHandler(playerService: player),
    ),
    libraryRepositoryProvider.overrideWithValue(
      libraryRepo ?? StubLibraryRepository(),
    ),
    permissionServiceProvider.overrideWithValue(
      permissionService ?? const StubPermissionService(),
    ),
  ];
}
