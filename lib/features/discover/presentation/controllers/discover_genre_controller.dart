import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tracks/data/repositories/track_repository_impl.dart';
import '../../../tracks/domain/entities/track.dart';

/// Provider managing the active genre filter specifically scoped to Discover.
/// This prevents genre selection in Discover from unintentionally leaking into Home.
final discoverGenreProvider = NotifierProvider<DiscoverGenreNotifier, String?>(
  DiscoverGenreNotifier.new,
);

class DiscoverGenreNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Toggles [genre]: deselects if currently active, selects if different.
  void selectGenre(String? genre) {
    if (state == genre) {
      state = null;
    } else {
      state = genre;
    }
  }

  void clear() => state = null;
}

/// Provider managing trending tracks specifically for Discover catalog exploration,
/// re-evaluating when [discoverGenreProvider] changes.
final discoverTrendingTracksProvider = FutureProvider<List<Track>>((ref) async {
  final genre = ref.watch(discoverGenreProvider);
  final repo = ref.watch(trackRepositoryProvider);
  return repo.getTrendingTracks(genre: genre, limit: 20);
});
