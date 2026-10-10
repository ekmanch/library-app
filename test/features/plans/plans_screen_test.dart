import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/features/plans/plan_screen.dart';
import 'package:library_app/features/plans/plans_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('groups plans by state with progress and what is next', (
    tester,
  ) async {
    await pumpApp(tester, const PlansScreen());
    expect(find.text('Plans'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('FINISHED'), findsOneWidget);
    expect(find.text('NOT STARTED'), findsNothing);
    expect(find.text('Halloween 2026'), findsOneWidget);
    expect(find.text('2 of 8 done'), findsOneWidget);
    expect(find.textContaining('Next up: Mononoke, The Mummy'), findsOneWidget);
    expect(find.text('Christmas 2026'), findsOneWidget);
    expect(find.text('0 of 6 done'), findsOneWidget);
    expect(find.text('Halloween 2025'), findsOneWidget);
    expect(find.text('Linked to #halloween'), findsOneWidget);
  });

  testWidgets('a plan opens its screen', (tester) async {
    await pumpApp(tester, const PlansScreen());
    await tester.tap(find.text('Halloween 2025'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanScreen), findsOneWidget);
    expect(find.text('3 of 3 done'), findsOneWidget);
  });

  testWidgets('no plans shows an empty state', (tester) async {
    await pumpApp(
      tester,
      const PlansScreen(),
      library: loadFixture().copyWith(plans: []),
    );
    expect(find.text('No plans yet'), findsOneWidget);
    await tester.tap(find.text('New plan'));
    await tester.pumpAndSettle();
    expect(find.text('Create'), findsOneWidget);
  });
}
