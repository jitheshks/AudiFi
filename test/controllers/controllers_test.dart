import 'dart:async';

import 'package:audifi/core/api/api_exceptions.dart';
import 'package:audifi/features/artists/data/repositories/user_repository_impl.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/artists/domain/repositories/user_repository.dart';
import 'package:audifi/features/artists/presentation/controllers/artist_detail_controller.dart';
import 'package:audifi/features/discover/presentation/controllers/trending_playlists_controller.dart';
import 'package:audifi/features/home/presentation/controllers/latest_releases_controller.dart';
import 'package:audifi/features/home/presentation/controllers/trending_tracks_controller.dart';
import 'package:audifi/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:audifi/features/playlists/domain/entities/playlist.dart';
import 'package:audifi/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:audifi/features/playlists/presentation/controllers/playlist_detail_controller.dart';
import 'package:audifi/features/search/data/repositories/search_repository_impl.dart';
import 'package:audifi/features/search/domain/entities/search_result.dart';
import 'package:audifi/features/search/domain/repositories/search_repository.dart';
import 'package:audifi/features/search/presentation/controllers/search_controller.dart';
import 'package:audifi/features/tracks/data/repositories/track_repository_impl.dart';
import 'package:audifi/features/tracks/domain/entities/track.dart';
import 'package:audifi/features/tracks/domain/repositories/track_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    return [Track(id: 't1', title: 'Trending ${genre ?? "All"}')];
  }

  @override
  Future<List<Track>> getLatestTracks({int limit = 20, int offset = 0}) async {
    return [const Track(id: 'latest_t1', title: 'Latest Track')];
  }

  @override
  Future<List<Track>> getUserTracks(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return [Track(id: 'art_track_1', title: 'Track by $userId')];
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
    return [const Playlist(id: 'pl1', playlistName: 'Trending Playlist')];
  }

  @override
  Future<Playlist?> getPlaylist(String playlistId) async {
    if (playlistId == '404') return null;
    return Playlist(id: playlistId, playlistName: 'Playlist $playlistId');
  }

  @override
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    return [Track(id: 'pl_tr_1', title: 'Track of $playlistId')];
  }
}

class StubUserRepository implements UserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<User?> getUser(String userId) async {
    if (userId == '404') return null;
    return User(id: userId, name: 'Artist $userId', handle: 'art_$userId');
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
      tracks: [Track(id: 'res_t1', title: 'Result for $query')],
    );
  }
}

void main() {
  late ProviderContainer container;
  late StubTrackRepository stubTrackRepo;
  late StubPlaylistRepository stubPlaylistRepo;
  late StubUserRepository stubUserRepo;
  late StubSearchRepository stubSearchRepo;

  setUp(() {
    stubTrackRepo = StubTrackRepository();
    stubPlaylistRepo = StubPlaylistRepository();
    stubUserRepo = StubUserRepository();
    stubSearchRepo = StubSearchRepository();

    container = ProviderContainer(
      overrides: [
        trackRepositoryProvider.overrideWithValue(stubTrackRepo),
        playlistRepositoryProvider.overrideWithValue(stubPlaylistRepo),
        userRepositoryProvider.overrideWithValue(stubUserRepo),
        searchRepositoryProvider.overrideWithValue(stubSearchRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TrendingTracksController', () {
    test('fetches trending tracks and updates when genre changes', () async {
      final initial = await container.read(
        trendingTracksControllerProvider.future,
      );
      expect(initial.first.title, 'Trending All');

      await container
          .read(trendingTracksControllerProvider.notifier)
          .setGenre('Electronic');
      final updated = await container.read(
        trendingTracksControllerProvider.future,
      );
      expect(updated.first.title, 'Trending Electronic');
      expect(stubTrackRepo.lastGenre, 'Electronic');

      await container.read(trendingTracksControllerProvider.notifier).refresh();
      final refreshed = await container.read(
        trendingTracksControllerProvider.future,
      );
      expect(refreshed.first.title, 'Trending Electronic');
    });
  });

  group('LatestReleasesController & TrendingPlaylistsController', () {
    test('retrieves latest releases and refreshes', () async {
      final latest = await container.read(
        latestReleasesControllerProvider.future,
      );
      expect(latest.first.title, 'Latest Track');

      final playlists = await container.read(
        trendingPlaylistsControllerProvider.future,
      );
      expect(playlists.first.playlistName, 'Trending Playlist');
    });
  });

  group('SearchController', () {
    test('manages search query, results, and clear', () async {
      final controller = container.read(searchControllerProvider.notifier);
      expect(container.read(searchControllerProvider).query, '');

      await controller.search('Synthwave');
      expect(container.read(searchControllerProvider).query, 'Synthwave');
      expect(
        container
            .read(searchControllerProvider)
            .results
            .value
            ?.tracks
            .first
            .title,
        'Result for Synthwave',
      );

      controller.clear();
      expect(container.read(searchControllerProvider).query, '');
      expect(
        container.read(searchControllerProvider).results.value?.isEmpty,
        isTrue,
      );
    });

    test('ignores outdated search responses', () async {
      final slowCompleter = Completer<SearchResult>();
      stubSearchRepo.delayedCompleter = slowCompleter;

      final controller = container.read(searchControllerProvider.notifier);

      // 1. Issue first slow search
      final future1 = controller.search('SlowQuery');

      // 2. Clear completer and issue fast second search
      stubSearchRepo.delayedCompleter = null;
      await controller.search('FastQuery');
      expect(container.read(searchControllerProvider).query, 'FastQuery');
      expect(
        container
            .read(searchControllerProvider)
            .results
            .value
            ?.tracks
            .first
            .title,
        'Result for FastQuery',
      );

      // 3. Complete the first slow query late
      slowCompleter.complete(
        const SearchResult(
          tracks: [Track(id: 'stale', title: 'Stale')],
        ),
      );
      await future1;

      // 4. State must STILL be FastQuery, not overwritten by Stale
      expect(container.read(searchControllerProvider).query, 'FastQuery');
      expect(
        container
            .read(searchControllerProvider)
            .results
            .value
            ?.tracks
            .first
            .title,
        'Result for FastQuery',
      );
    });
  });

  group('Artist & Playlist Detail Providers', () {
    test('artistDetailProvider resolves user profile and tracks', () async {
      final state = await container.read(
        artistDetailProvider('u_valid').future,
      );
      expect(state.user.name, 'Artist u_valid');
      expect(state.tracks.first.title, 'Track by u_valid');
    });

    test(
      'artistDetailProvider throws 404 ApiException when user is missing',
      () async {
        final sub = container.listen(
          artistDetailProvider('404'),
          (_, _) {},
          onError: (_, _) {},
        );
        addTearDown(sub.close);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final state = container.read(artistDetailProvider('404'));
        expect(state.hasError, isTrue);
        expect(
          state.error,
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        );
      },
    );

    test('playlistDetailProvider resolves playlist and tracks', () async {
      final state = await container.read(
        playlistDetailProvider('pl_valid').future,
      );
      expect(state.playlist.playlistName, 'Playlist pl_valid');
      expect(state.tracks.first.title, 'Track of pl_valid');
    });

    test(
      'playlistDetailProvider throws 404 ApiException when playlist is missing',
      () async {
        final sub = container.listen(
          playlistDetailProvider('404'),
          (_, _) {},
          onError: (_, _) {},
        );
        addTearDown(sub.close);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final state = container.read(playlistDetailProvider('404'));
        expect(state.hasError, isTrue);
        expect(
          state.error,
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        );
      },
    );
  });
}
