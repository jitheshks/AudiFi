import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// Riverpod controller managing popular/top artists discovery feed.
class TopArtistsController extends AsyncNotifier<List<User>> {
  UserRepository get _repository => ref.read(userRepositoryProvider);

  @override
  Future<List<User>> build() async {
    return _fetchTopArtists();
  }

  Future<List<User>> _fetchTopArtists() async {
    return _repository.getTopUsers(limit: 12);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchTopArtists);
  }
}

/// Riverpod provider for [TopArtistsController].
final topArtistsControllerProvider =
    AsyncNotifierProvider<TopArtistsController, List<User>>(
      TopArtistsController.new,
    );
