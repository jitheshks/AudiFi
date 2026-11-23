import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audifi/features/search/data/repositories/search_repository_impl.dart';
import 'package:audifi/features/search/presentation/controllers/search_controller.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchRecentHistory', () {
    late ProviderContainer container;
    late StubSearchRepository stubRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'audifi_recent_searches_v1': ['synthwave', 'lo-fi beats'],
      });
      stubRepo = StubSearchRepository();
      container = ProviderContainer(
        overrides: [searchRepositoryProvider.overrideWithValue(stubRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'initial state loads recent searches from persistent storage',
      () async {
        container.read(searchControllerProvider);
        await Future<void>.delayed(Duration.zero);
        final state = container.read(searchControllerProvider);
        expect(state.recentSearches, containsAll(['synthwave', 'lo-fi beats']));
      },
    );

    test(
      'searching prepends query to history and prevents duplicate entries',
      () async {
        final controller = container.read(searchControllerProvider.notifier);

        await controller.search('electronic');
        var state = container.read(searchControllerProvider);
        expect(state.recentSearches.first, equals('electronic'));

        // Repeating query moves it to top without duplicates
        await controller.search('Electronic');
        state = container.read(searchControllerProvider);
        expect(
          state.recentSearches
              .where((s) => s.toLowerCase() == 'electronic')
              .length,
          equals(1),
        );
      },
    );

    test('limits history to 10 entries', () async {
      final controller = container.read(searchControllerProvider.notifier);

      for (int i = 1; i <= 15; i++) {
        await controller.search('query_$i');
      }

      final state = container.read(searchControllerProvider);
      expect(state.recentSearches.length, equals(10));
      expect(state.recentSearches.first, equals('query_15'));
    });

    test('removeRecentSearch removes single entry', () async {
      final controller = container.read(searchControllerProvider.notifier);

      await controller.search('jazz');
      await controller.search('rock');
      var state = container.read(searchControllerProvider);
      expect(state.recentSearches, contains('jazz'));

      controller.removeRecentSearch('jazz');
      state = container.read(searchControllerProvider);
      expect(state.recentSearches, isNot(contains('jazz')));
      expect(state.recentSearches, contains('rock'));
    });

    test('clearRecentSearches wipes entire history', () async {
      final controller = container.read(searchControllerProvider.notifier);

      await controller.search('chill');
      controller.clearRecentSearches();

      final state = container.read(searchControllerProvider);
      expect(state.recentSearches, isEmpty);
    });
  });
}
