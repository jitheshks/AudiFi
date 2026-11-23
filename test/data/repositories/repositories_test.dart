import 'package:audifi/features/albums/data/models/album_model.dart';
import 'package:audifi/features/artists/data/datasources/artist_remote_data_source.dart';
import 'package:audifi/features/artists/data/models/user_model.dart';
import 'package:audifi/features/artists/data/repositories/user_repository_impl.dart';
import 'package:audifi/features/artists/domain/repositories/user_repository.dart';
import 'package:audifi/features/playlists/data/datasources/playlist_remote_data_source.dart';
import 'package:audifi/features/playlists/data/models/playlist_model.dart';
import 'package:audifi/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:audifi/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:audifi/features/search/data/datasources/search_remote_data_source.dart';
import 'package:audifi/features/search/data/models/search_result_model.dart';
import 'package:audifi/features/search/data/repositories/search_repository_impl.dart';
import 'package:audifi/features/search/domain/repositories/search_repository.dart';
import 'package:audifi/features/tracks/data/datasources/track_remote_data_source.dart';
import 'package:audifi/features/tracks/data/models/track_model.dart';
import 'package:audifi/features/tracks/data/repositories/track_repository_impl.dart';
import 'package:audifi/features/tracks/domain/repositories/track_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRemoteDataSource
    implements
        TrackRemoteDataSource,
        PlaylistRemoteDataSource,
        ArtistRemoteDataSource,
        SearchRemoteDataSource {
  bool searchCalled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<TrackModel>> getTrendingTracks({
    int limit = 20,
    int offset = 0,
    String? genre,
    String time = 'week',
  }) async {
    return [const TrackModel(id: 't_repo_1', title: 'Repo Trending Track')];
  }

  @override
  Future<List<TrackModel>> getLatestTracks({
    int limit = 20,
    int offset = 0,
  }) async {
    return [const TrackModel(id: 't_latest_1', title: 'Repo Latest Track')];
  }

  @override
  Future<List<TrackModel>> getUserTracks(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return [const TrackModel(id: 't_usr_1', title: 'Repo User Track')];
  }

  @override
  Future<List<PlaylistModel>> getTrendingPlaylists({
    int limit = 20,
    int offset = 0,
    String time = 'week',
  }) async {
    return [
      const PlaylistModel(
        id: 'p_trend_1',
        playlistName: 'Repo Trending Playlist',
      ),
    ];
  }

  @override
  Future<List<PlaylistModel>> getNewReleasesPlaylists({
    int limit = 20,
    int offset = 0,
    String type = 'playlist',
  }) async {
    return [
      const PlaylistModel(id: 'p_new_1', playlistName: 'Repo New Playlist'),
    ];
  }

  @override
  Future<List<AlbumModel>> getNewReleaseAlbums({
    int limit = 20,
    int offset = 0,
  }) async {
    return [const AlbumModel(id: 'a_new_1', title: 'Repo New Album')];
  }

  @override
  Future<PlaylistModel?> getPlaylist(String playlistId) async {
    if (playlistId == 'missing') return null;
    return PlaylistModel(id: playlistId, playlistName: 'Playlist $playlistId');
  }

  @override
  Future<List<TrackModel>> getPlaylistTracks(String playlistId) async {
    return [const TrackModel(id: 'pl_track_1', title: 'Playlist Track')];
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    if (userId == 'missing') return null;
    return UserModel(
      id: userId,
      name: 'User $userId',
      handle: 'handle_$userId',
    );
  }

  @override
  Future<SearchResultModel> searchFull(
    String query, {
    String? kind,
    int limit = 20,
    int offset = 0,
    bool? includePurchaseable,
  }) async {
    searchCalled = true;
    return SearchResultModel(
      tracks: [TrackModel(id: 'res_1', title: 'Result for $query')],
    );
  }
}

void main() {
  late FakeRemoteDataSource fakeDataSource;
  late TrackRepository trackRepo;
  late PlaylistRepository playlistRepo;
  late UserRepository userRepo;
  late SearchRepository searchRepo;

  setUp(() {
    fakeDataSource = FakeRemoteDataSource();
    trackRepo = TrackRepositoryImpl(remoteDataSource: fakeDataSource);
    playlistRepo = PlaylistRepositoryImpl(remoteDataSource: fakeDataSource);
    userRepo = UserRepositoryImpl(remoteDataSource: fakeDataSource);
    searchRepo = SearchRepositoryImpl(remoteDataSource: fakeDataSource);
  });

  group('TrackRepository', () {
    test('retrieves trending, latest, and user tracks', () async {
      final trending = await trackRepo.getTrendingTracks();
      expect(trending.length, 1);
      expect(trending.first.title, 'Repo Trending Track');

      final latest = await trackRepo.getLatestTracks();
      expect(latest.length, 1);
      expect(latest.first.title, 'Repo Latest Track');

      final userTracks = await trackRepo.getUserTracks('user_1');
      expect(userTracks.length, 1);
      expect(userTracks.first.title, 'Repo User Track');
    });
  });

  group('PlaylistRepository', () {
    test('retrieves playlists, albums, and playlist details', () async {
      final trending = await playlistRepo.getTrendingPlaylists();
      expect(trending.first.playlistName, 'Repo Trending Playlist');

      final newPlaylists = await playlistRepo.getNewReleasesPlaylists();
      expect(newPlaylists.first.playlistName, 'Repo New Playlist');

      final newAlbums = await playlistRepo.getNewReleaseAlbums();
      expect(newAlbums.first.title, 'Repo New Album');

      final playlist = await playlistRepo.getPlaylist('pl_test');
      expect(playlist?.playlistName, 'Playlist pl_test');

      final tracks = await playlistRepo.getPlaylistTracks('pl_test');
      expect(tracks.first.title, 'Playlist Track');
    });
  });

  group('UserRepository', () {
    test('retrieves user and returns null for missing user', () async {
      final user = await userRepo.getUser('user_abc');
      expect(user?.name, 'User user_abc');

      final missing = await userRepo.getUser('missing');
      expect(missing, isNull);
    });
  });

  group('SearchRepository', () {
    test('returns empty SearchResult for empty query without calling remote data source', () async {
      final result = await searchRepo.search('   ');
      expect(result.isEmpty, isTrue);
      expect(fakeDataSource.searchCalled, isFalse);
    });

    test('calls remote data source when query is non-empty', () async {
      final result = await searchRepo.search('Electronic Beats');
      expect(fakeDataSource.searchCalled, isTrue);
      expect(result.tracks.first.title, 'Result for Electronic Beats');
    });
  });
}
