import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audifi/features/artists/data/repositories/user_repository_impl.dart';
import 'package:audifi/features/artists/domain/entities/user.dart';
import 'package:audifi/features/artists/presentation/controllers/top_artists_controller.dart';

import '../../../test_helpers/stub_repositories.dart';

class FailingUserRepository extends StubUserRepository {
  @override
  Future<List<User>> getTopUsers({int limit = 12, int offset = 0}) async {
    throw Exception('Network error');
  }
}

void main() {
  group('TopArtistsController', () {
    test('loads top artists on initialization', () async {
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(StubUserRepository()),
        ],
      );
      addTearDown(container.dispose);

      final artists = await container.read(topArtistsControllerProvider.future);
      expect(artists, isNotEmpty);
      expect(artists.first.name, contains('Top Artist'));
    });

    test('refresh reloads top artists', () async {
      final stubRepo = StubUserRepository();
      final container = ProviderContainer(
        overrides: [userRepositoryProvider.overrideWithValue(stubRepo)],
      );
      addTearDown(container.dispose);

      await container.read(topArtistsControllerProvider.future);
      final controller = container.read(topArtistsControllerProvider.notifier);
      await controller.refresh();

      final state = container.read(topArtistsControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isNotEmpty);
    });

    test('sets error state when repository fails', () async {
      final container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(FailingUserRepository()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(topArtistsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(topArtistsControllerProvider);
      expect(state.hasError, isTrue);
    });
  });
}
