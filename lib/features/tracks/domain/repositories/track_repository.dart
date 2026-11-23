import '../../../../core/constants/api_constants.dart';
import '../entities/track.dart';

/// Pure domain repository contract abstracting track discovery and retrieval operations.
abstract interface class TrackRepository {
  /// Retrieves trending tracks across Audius.
  Future<List<Track>> getTrendingTracks({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    String? genre,
    String time = ApiConstants.defaultTimeRange,
  });

  /// Retrieves newly published tracks from `/tracks/latest`.
  Future<List<Track>> getLatestTracks({
    int limit = 15,
    int offset = ApiConstants.defaultOffset,
  });

  /// Retrieves tracks uploaded by a specific artist.
  Future<List<Track>> getUserTracks(
    String userId, {
    int limit = 50,
    int offset = ApiConstants.defaultOffset,
  });

  /// Retrieves trending underground tracks from `/tracks/trending/underground`.
  Future<List<Track>> getTrendingUndergroundTracks({
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
  });
}
