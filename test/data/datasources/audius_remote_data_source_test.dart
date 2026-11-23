import 'dart:convert';
import 'dart:typed_data';

import 'package:audifi/core/api/api_client.dart';
import 'package:audifi/core/api/api_constants.dart';
import 'package:audifi/data/datasources/audius_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test HTTP adapter returning synthetic JSON responses for requested paths.
class MockDioAdapter implements HttpClientAdapter {
  MockDioAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}

  static ResponseBody jsonResponse(dynamic body, {int statusCode = 200}) {
    final raw = jsonEncode(body);
    return ResponseBody.fromString(
      raw,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  late Dio dio;
  late ApiClient apiClient;
  late AudiusRemoteDataSource dataSource;

  void setupMock(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    dio.httpClientAdapter = MockDioAdapter(handler);
    apiClient = ApiClient(rawDio: dio);
    dataSource = AudiusRemoteDataSource(apiClient: apiClient);
  }

  group('AudiusRemoteDataSource - Trending & Latest Tracks', () {
    test(
      'getTrendingTracks requests /tracks/trending with proper query params',
      () async {
        late RequestOptions capturedOptions;

        setupMock((options) async {
          capturedOptions = options;
          return MockDioAdapter.jsonResponse({
            'data': [
              {'id': 't1', 'title': 'Trending Track 1', 'duration': 180},
              {'id': 't2', 'title': 'Trending Track 2', 'duration': 210},
            ],
          });
        });

        final tracks = await dataSource.getTrendingTracks(
          genre: 'Electronic',
          time: 'week',
          limit: 10,
          offset: 0,
        );

        expect(capturedOptions.path, '/tracks/trending');
        expect(capturedOptions.queryParameters['genre'], 'Electronic');
        expect(capturedOptions.queryParameters['time'], 'week');
        expect(capturedOptions.queryParameters['limit'], 10);
        expect(tracks.length, 2);
        expect(tracks.first.title, 'Trending Track 1');
      },
    );

    test('getLatestTracks requests /tracks/latest', () async {
      late RequestOptions capturedOptions;

      setupMock((options) async {
        capturedOptions = options;
        return MockDioAdapter.jsonResponse({
          'data': [
            {'id': 'latest_1', 'title': 'Latest Release'},
          ],
        });
      });

      final tracks = await dataSource.getLatestTracks(limit: 5);
      expect(capturedOptions.path, '/tracks/latest');
      expect(capturedOptions.queryParameters['limit'], 5);
      expect(tracks.length, 1);
      expect(tracks.first.id, 'latest_1');
    });
  });

  group('AudiusRemoteDataSource - Playlists & Albums', () {
    test('getTrendingPlaylists requests /playlists/trending', () async {
      late RequestOptions capturedOptions;

      setupMock((options) async {
        capturedOptions = options;
        return MockDioAdapter.jsonResponse({
          'data': [
            {'id': 'pl1', 'playlist_name': 'Trending Summer Hits'},
          ],
        });
      });

      final playlists = await dataSource.getTrendingPlaylists();
      expect(capturedOptions.path, '/playlists/trending');
      expect(playlists.length, 1);
      expect(playlists.first.playlistName, 'Trending Summer Hits');
    });

    test(
      'getNewReleaseAlbums requests /playlists/new-releases with type=album',
      () async {
        late RequestOptions capturedOptions;

        setupMock((options) async {
          capturedOptions = options;
          return MockDioAdapter.jsonResponse({
            'data': [
              {
                'id': 'alb1',
                'playlist_name': 'Electronic LP',
                'is_album': true,
              },
            ],
          });
        });

        final albums = await dataSource.getNewReleaseAlbums();
        expect(capturedOptions.path, '/playlists/new-releases');
        expect(capturedOptions.queryParameters['type'], 'album');
        expect(albums.length, 1);
        expect(albums.first.title, 'Electronic LP');
      },
    );

    test('getPlaylist and getPlaylistTracks request valid endpoints', () async {
      setupMock((options) async {
        if (options.path == '/playlists/pl_123') {
          return MockDioAdapter.jsonResponse({
            'data': [
              {'id': 'pl_123', 'playlist_name': 'Target Playlist'},
            ],
          });
        } else if (options.path == '/playlists/pl_123/tracks') {
          return MockDioAdapter.jsonResponse({
            'data': [
              {'id': 't_item_1', 'title': 'Playlist Track 1'},
            ],
          });
        }
        return MockDioAdapter.jsonResponse({}, statusCode: 404);
      });

      final playlist = await dataSource.getPlaylist('pl_123');
      expect(playlist, isNotNull);
      expect(playlist!.playlistName, 'Target Playlist');

      final tracks = await dataSource.getPlaylistTracks('pl_123');
      expect(tracks.length, 1);
      expect(tracks.first.title, 'Playlist Track 1');
    });
  });

  group('AudiusRemoteDataSource - Search', () {
    test(
      'searchFull requests /search/full with includePurchaseable naming',
      () async {
        late RequestOptions capturedOptions;

        setupMock((options) async {
          capturedOptions = options;
          return MockDioAdapter.jsonResponse({
            'data': {
              'tracks': [
                {'id': 'st1', 'title': 'Searched Track'},
              ],
              'users': [
                {'id': 'su1', 'name': 'Searched Artist', 'handle': 'sartist'},
              ],
              'playlists': [],
              'albums': [],
            },
          });
        });

        final result = await dataSource.searchFull(
          'Chillhop',
          includePurchaseable: true,
        );

        expect(capturedOptions.path, '/search/full');
        expect(capturedOptions.queryParameters['query'], 'Chillhop');
        expect(
          capturedOptions.queryParameters[ApiConstants
              .paramIncludePurchaseable],
          true,
        );
        expect(result.tracks.length, 1);
        expect(result.users.length, 1);
        expect(result.tracks.first.title, 'Searched Track');
      },
    );
  });

  group('AudiusRemoteDataSource - User Details', () {
    test(
      'getUser and getUserTracks request /users/{id} and /users/{id}/tracks',
      () async {
        setupMock((options) async {
          if (options.path == '/users/u_42') {
            return MockDioAdapter.jsonResponse({
              'data': {
                'id': 'u_42',
                'name': 'Featured Artist',
                'handle': 'featured',
              },
            });
          } else if (options.path == '/users/u_42/tracks') {
            return MockDioAdapter.jsonResponse({
              'data': [
                {'id': 't_art_1', 'title': 'Artist Masterpiece'},
              ],
            });
          }
          return MockDioAdapter.jsonResponse({}, statusCode: 404);
        });

        final user = await dataSource.getUser('u_42');
        expect(user, isNotNull);
        expect(user!.name, 'Featured Artist');

        final tracks = await dataSource.getUserTracks('u_42');
        expect(tracks.length, 1);
        expect(tracks.first.title, 'Artist Masterpiece');
      },
    );
  });
}
