import 'package:audifi/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers/stub_repositories.dart';

void main() {
  testWidgets('AudifiApp root smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: createStubRepositoryOverrides(),
        child: const AudifiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Audifi launches and renders personalized Home View and 5 navigation destinations
    expect(find.text('Explore Discover'), findsWidgets);
    expect(find.text('Liked'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
