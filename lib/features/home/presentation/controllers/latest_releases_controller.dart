import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../tracks/data/repositories/track_repository_impl.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../../tracks/domain/repositories/track_repository.dart';

/// Riverpod controller managing newly published tracks from Audius.
class LatestReleasesController extends AsyncNotifier<List<Track>> {
  @override
  FutureOr<List<Track>> build() {
    return _fetchLatest();
  }

  Future<List<Track>> _fetchLatest() async {
    try {
      final TrackRepository repository = ref.watch(trackRepositoryProvider);
      return await repository.getLatestTracks(limit: 15);
    } catch (error) {
      throw ErrorMapper.mapToFailure(error);
    }
  }

  /// Forces a fresh reload of latest releases.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLatest());
  }
}

/// Provider for [LatestReleasesController].
final latestReleasesControllerProvider =
    AsyncNotifierProvider<LatestReleasesController, List<Track>>(
      LatestReleasesController.new,
    );
