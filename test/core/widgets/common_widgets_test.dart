import 'package:audifi/core/theme/app_colors.dart';
import 'package:audifi/core/theme/app_radius.dart';
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
      addTearDown(controller.dispose);
      var cleared = false;

      await tester.pumpWidget(
        testWrapper(
          AudifiSearchField(
            controller: controller,
            hintText: 'Search songs...',
            onClear: () => cleared = true,
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
      expect(cleared, isTrue);
    });

    testWidgets(
      'suppresses nested InputDecoration borders and applies outer container focus state in dark theme',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: AudifiSearchField(
                  controller: controller,
                  hintText: 'Search songs, artists, or playlists',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        final decoration = textField.decoration!;
        expect(decoration.border, InputBorder.none);
        expect(decoration.enabledBorder, InputBorder.none);
        expect(decoration.focusedBorder, InputBorder.none);
        expect(decoration.disabledBorder, InputBorder.none);
        expect(decoration.errorBorder, InputBorder.none);
        expect(decoration.focusedErrorBorder, InputBorder.none);
        expect(decoration.filled, isFalse);

        // Verify resolved InputDecorator has no inner border when unfocused or focused
        InputDecorator inputDecorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator),
        );
        expect(inputDecorator.decoration.focusedBorder, InputBorder.none);
        expect(inputDecorator.decoration.enabledBorder, InputBorder.none);

        // Unfocused outer container styling
        final containerFinder = find.descendant(
          of: find.byType(AudifiSearchField),
          matching: find.byType(AnimatedContainer),
        );
        var container = tester.widget<AnimatedContainer>(containerFinder);
        var boxDecoration = container.decoration! as BoxDecoration;
        expect(boxDecoration.color, AppColors.darkSurface1);
        expect(boxDecoration.borderRadius, AppRadius.inputBorder);
        expect(
          boxDecoration.border,
          Border.all(color: Colors.transparent, width: 1.5),
        );

        var searchIcon = tester.widget<Icon>(find.byIcon(Icons.search_rounded));
        expect(searchIcon.color, AppColors.darkTextMuted);

        // Tap search field to focus
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        expect(textField.focusNode!.hasFocus, isTrue);
        inputDecorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator),
        );
        expect(inputDecorator.isFocused, isTrue);
        expect(inputDecorator.decoration.focusedBorder, InputBorder.none);

        container = tester.widget<AnimatedContainer>(containerFinder);
        boxDecoration = container.decoration! as BoxDecoration;
        expect(boxDecoration.color, AppColors.darkSurface1);
        expect(boxDecoration.borderRadius, AppRadius.inputBorder);
        expect(
          boxDecoration.border,
          Border.all(
            color: AppColors.accent.withValues(alpha: 0.55),
            width: 1.5,
          ),
        );

        searchIcon = tester.widget<Icon>(find.byIcon(Icons.search_rounded));
        expect(searchIcon.color, AppColors.accent);

        // Unfocus restores unfocused appearance
        textField.focusNode!.unfocus();
        await tester.pumpAndSettle();

        container = tester.widget<AnimatedContainer>(containerFinder);
        boxDecoration = container.decoration! as BoxDecoration;
        expect(
          boxDecoration.border,
          Border.all(color: Colors.transparent, width: 1.5),
        );
        searchIcon = tester.widget<Icon>(find.byIcon(Icons.search_rounded));
        expect(searchIcon.color, AppColors.darkTextMuted);
      },
    );

    testWidgets(
      'renders safely without LateInitializationError across reassemble, outer-container tap, focus, and unfocus',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: AudifiSearchField(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Trigger reassemble on the mounted State (as happens on hot reload)
        // ignore: invalid_use_of_protected_member
        tester.state(find.byType(AudifiSearchField)).reassemble();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final containerFinder = find.descendant(
          of: find.byType(AudifiSearchField),
          matching: find.byType(AnimatedContainer),
        );
        final textField = tester.widget<TextField>(find.byType(TextField));
        final focusNode = textField.focusNode!;

        // Initial unfocused state
        expect(focusNode.hasFocus, isFalse);
        var boxDecoration =
            tester.widget<AnimatedContainer>(containerFinder).decoration!
                as BoxDecoration;
        expect(
          boxDecoration.border,
          Border.all(color: Colors.transparent, width: 1.5),
        );

        // Tap outer container (search icon area outside TextField text box)
        await tester.tap(find.byIcon(Icons.search_rounded));
        await tester.pumpAndSettle();

        expect(focusNode.hasFocus, isTrue);
        boxDecoration =
            tester.widget<AnimatedContainer>(containerFinder).decoration!
                as BoxDecoration;
        expect(
          boxDecoration.border,
          Border.all(
            color: AppColors.accent.withValues(alpha: 0.55),
            width: 1.5,
          ),
        );

        // Unfocus restores transparent outer border
        focusNode.unfocus();
        await tester.pumpAndSettle();

        expect(focusNode.hasFocus, isFalse);
        boxDecoration =
            tester.widget<AnimatedContainer>(containerFinder).decoration!
                as BoxDecoration;
        expect(
          boxDecoration.border,
          Border.all(color: Colors.transparent, width: 1.5),
        );
      },
    );

    testWidgets(
      'supports externally owned FocusNode without disposing it on unmount',
      (tester) async {
        final controller = TextEditingController();
        final externalFocusNode = FocusNode();
        final replacementFocusNode = FocusNode();
        addTearDown(() {
          controller.dispose();
          externalFocusNode.dispose();
          replacementFocusNode.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: AudifiSearchField(
                controller: controller,
                focusNode: externalFocusNode,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        externalFocusNode.requestFocus();
        await tester.pumpAndSettle();
        expect(externalFocusNode.hasFocus, isTrue);

        final containerFinder = find.descendant(
          of: find.byType(AudifiSearchField),
          matching: find.byType(AnimatedContainer),
        );
        var boxDecoration =
            tester.widget<AnimatedContainer>(containerFinder).decoration!
                as BoxDecoration;
        expect(
          boxDecoration.border,
          Border.all(
            color: AppColors.accent.withValues(alpha: 0.55),
            width: 1.5,
          ),
        );

        // Swap to another external FocusNode
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: AudifiSearchField(
                controller: controller,
                focusNode: replacementFocusNode,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Unmount widget and verify externally owned FocusNodes remain usable
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await tester.pumpAndSettle();

        expect(() => externalFocusNode.addListener(() {}), returnsNormally);
        expect(() => replacementFocusNode.addListener(() {}), returnsNormally);
      },
    );
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
