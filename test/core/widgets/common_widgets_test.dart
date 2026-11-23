import 'package:audifi/core/theme/app_theme.dart';
import 'package:audifi/shared/widgets/audifi_app_bar.dart';
import 'package:audifi/shared/widgets/audifi_button.dart';
import 'package:audifi/shared/widgets/audifi_card.dart';
import 'package:audifi/shared/widgets/audifi_empty_state.dart';
import 'package:audifi/shared/widgets/audifi_error_view.dart';
import 'package:audifi/shared/widgets/audifi_icon_button.dart';
import 'package:audifi/shared/widgets/audifi_loading_indicator.dart';
import 'package:audifi/shared/widgets/audifi_page_container.dart';
import 'package:audifi/shared/widgets/audifi_search_field.dart';
import 'package:audifi/shared/widgets/audifi_section_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget testWrapper(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('AudifiButton', () {
    testWidgets('renders button text and triggers callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        testWrapper(
          AudifiButton(text: 'Play Track', onPressed: () => pressed = true),
        ),
      );

      expect(find.text('Play Track'), findsOneWidget);
      await tester.tap(find.text('Play Track'));
      expect(pressed, isTrue);
    });

    testWidgets('meets minimum 48x48 tap target constraint', (tester) async {
      await tester.pumpWidget(
        testWrapper(AudifiButton(text: 'OK', onPressed: () {})),
      );

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(ConstrainedBox).first,
      );
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrapper(
          AudifiButton(text: 'Loading...', isLoading: true, onPressed: () {}),
        ),
      );

      expect(find.byType(AudifiLoadingIndicator), findsOneWidget);
    });
  });

  group('AudifiIconButton', () {
    testWidgets('renders icon and triggers onPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        testWrapper(
          AudifiIconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorite',
            semanticLabel: 'Favorite',
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      await tester.tap(find.byIcon(Icons.favorite));
      expect(pressed, isTrue);

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(ConstrainedBox).first,
      );
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
    });
  });

  group('AudifiAppBar', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          const Scaffold(
            appBar: AudifiAppBar(title: 'Discover', subtitle: 'Top charts'),
          ),
        ),
      );

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Top charts'), findsOneWidget);
    });
  });

  group('AudifiCard', () {
    testWidgets('renders child and handles optional tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        testWrapper(
          AudifiCard(
            onTap: () => tapped = true,
            child: const Text('Card Item'),
          ),
        ),
      );

      expect(find.text('Card Item'), findsOneWidget);
      await tester.tap(find.text('Card Item'));
      expect(tapped, isTrue);
    });
  });

  group('AudifiSectionHeader', () {
    testWidgets('renders title and action label', (tester) async {
      var actionTriggered = false;
      await tester.pumpWidget(
        testWrapper(
          AudifiSectionHeader(
            title: 'Trending Tracks',
            actionLabel: 'See All',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('Trending Tracks'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      await tester.tap(find.text('See All'));
      expect(actionTriggered, isTrue);
    });
  });

  group('AudifiSearchField', () {
    testWidgets('accepts text input and clears with button', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        testWrapper(
          AudifiSearchField(
            controller: controller,
            hintText: 'Search songs...',
          ),
        ),
      );

      expect(find.text('Search songs...'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Audius Chill');
      await tester.pump();
      expect(controller.text, 'Audius Chill');

      // Clear button appears
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(controller.text, '');
    });
  });

  group('AudifiEmptyState', () {
    testWidgets('renders title, description, and action button', (
      tester,
    ) async {
      var actionFired = false;
      await tester.pumpWidget(
        testWrapper(
          AudifiEmptyState(
            title: 'No Tracks Found',
            description: 'Try searching for something else.',
            actionLabel: 'Browse Trending',
            onAction: () => actionFired = true,
          ),
        ),
      );

      expect(find.text('No Tracks Found'), findsOneWidget);
      expect(find.text('Try searching for something else.'), findsOneWidget);
      expect(find.text('Browse Trending'), findsOneWidget);

      await tester.tap(find.text('Browse Trending'));
      expect(actionFired, isTrue);
    });
  });

  group('AudifiErrorView', () {
    testWidgets('renders error message and triggers retry', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(
        testWrapper(
          AudifiErrorView(
            message: 'Network connection lost',
            onRetry: () => retryCalled = true,
          ),
        ),
      );

      expect(find.text('Unable to Load Content'), findsOneWidget);
      expect(find.text('Network connection lost'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryCalled, isTrue);
    });
  });

  group('AudifiLoadingIndicator', () {
    testWidgets('renders with semantic description', (tester) async {
      await tester.pumpWidget(testWrapper(const AudifiLoadingIndicator()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });
  });

  group('AudifiPageContainer', () {
    testWidgets('renders child in scrollable container', (tester) async {
      await tester.pumpWidget(
        testWrapper(const AudifiPageContainer(child: Text('Page Content'))),
      );

      expect(find.text('Page Content'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
