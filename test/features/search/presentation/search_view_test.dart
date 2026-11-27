import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/core/theme/app_theme.dart';
import 'package:audifi/features/search/domain/entities/search_result.dart';
import 'package:audifi/features/search/presentation/controllers/search_controller.dart';
import 'package:audifi/features/search/presentation/views/search_view.dart';
import 'package:audifi/shared/widgets/audifi_error_view.dart';

import '../../../test_helpers/stub_repositories.dart';

void main() {
  group('SearchView — Search & Browse Functional Verification', () {
    Widget createTestWidget({
      StubSearchRepository? searchRepo,
      ThemeData? theme,
    }) {
      final repo = searchRepo ?? StubSearchRepository();
      return ProviderScope(
        overrides: [...createStubRepositoryOverrides(searchRepo: repo)],
        child: MaterialApp(theme: theme, home: const SearchView()),
      );
    }

    testWidgets('initial search screen renders search field and clean prompt', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Search field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);

      // Clean prompt when no queries
      expect(find.text('Find What You Love'), findsOneWidget);
      expect(
        find.text('Search for tracks, artists, or playlists across Audius.'),
        findsOneWidget,
      );

      // Verifies duplicate catalog feeds have been eliminated from Search
      expect(find.text('Browse Categories'), findsNothing);
      expect(find.text('Explore Moods'), findsNothing);
    });

    testWidgets('entering query displays kind tabs and searches catalog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'Synthwave');
      // Settle debouncer (350ms)
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Tabs appear when query is active
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Tracks'), findsWidgets);
      expect(find.text('Artists'), findsWidgets);
      expect(find.text('Playlists'), findsWidgets);

      // Search results rendered
      expect(find.text('Result for Synthwave'), findsOneWidget);
    });

    testWidgets('renders empty state when query returns zero results', (
      tester,
    ) async {
      final stubRepo = _EmptySearchRepository();

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(searchRepo: stubRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'NonExistentArtistXYZ');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search_empty')), findsOneWidget);
      expect(find.text('No Results Found'), findsOneWidget);
    });

    testWidgets('renders error view with retry action on API failure', (
      tester,
    ) async {
      final failingRepo = _FailingSearchRepository();

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(searchRepo: failingRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'CrashQuery');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search_error')), findsOneWidget);
      expect(find.byType(AudifiErrorView), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('clearing search query returns to initial browse screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Ambient');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Result for Ambient'), findsOneWidget);

      // Clear search
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchView)),
      );
      container.read(searchControllerProvider.notifier).clear();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search_recent_list')), findsOneWidget);
    });

    testWidgets(
      'search field in dark theme shows outer focus border without inner outline and preserves clear & submit',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget(theme: AppTheme.darkTheme));
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);
        final inputDecorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator),
        );
        expect(inputDecorator.decoration.focusedBorder, InputBorder.none);
        expect(inputDecorator.decoration.filled, isFalse);

        // Tap outer search container icon area to focus
        await tester.tap(find.byIcon(Icons.search_rounded).first);
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.focusNode!.hasFocus, isTrue);
        expect(textField.textInputAction, TextInputAction.search);

        final outerContainer = tester.widget<AnimatedContainer>(
          find.descendant(
            of: find.byType(SearchView),
            matching: find.byType(AnimatedContainer),
          ).first,
        );
        final decoration = outerContainer.decoration! as BoxDecoration;
        expect(
          decoration.border,
          Border.all(
            color: AppColors.accent.withValues(alpha: 0.55),
            width: 1.5,
          ),
        );

        // Submit query via keyboard action
        await tester.enterText(textFieldFinder, 'Vaporwave');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        expect(find.text('Result for Vaporwave'), findsOneWidget);

        // Tap clear button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('search_recent_list')), findsOneWidget);
      },
    );
  });
}

class _EmptySearchRepository extends StubSearchRepository {
  @override
  Future<SearchResult> search(
    String query, {
    String? kind,
    bool? includePurchaseable,
    int limit = 10,
    int offset = 0,
  }) async {
    return const SearchResult(tracks: [], users: [], playlists: [], albums: []);
  }
}

class _FailingSearchRepository extends StubSearchRepository {
  @override
  Future<SearchResult> search(
    String query, {
    String? kind,
    bool? includePurchaseable,
    int limit = 10,
    int offset = 0,
  }) async {
    throw Exception('Audius search node unreachable');
  }
}
