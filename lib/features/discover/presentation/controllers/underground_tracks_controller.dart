import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tracks/data/repositories/track_repository_impl.dart';
import '../../../tracks/domain/entities/track.dart';

/// Riverpod FutureProvider delivering top trending underground tracks on Audius.
final undergroundTracksProvider = FutureProvider.autoDispose<List<Track>>((
  ref,
) async {
  final repository = ref.watch(trackRepositoryProvider);
  return repository.getTrendingUndergroundTracks(limit: 20);
});
