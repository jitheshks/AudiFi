import '../../../../core/constants/api_constants.dart';
import '../entities/search_result.dart';

/// Pure domain repository contract abstracting full-catalog search operations.
abstract interface class SearchRepository {
  /// Executes catalog search matching tracks, artists, playlists, and albums.
  Future<SearchResult> search(
    String query, {
    String? kind,
    int limit = ApiConstants.defaultLimit,
    int offset = ApiConstants.defaultOffset,
    bool? includePurchaseable,
  });
}
