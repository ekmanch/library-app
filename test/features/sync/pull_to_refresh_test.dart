import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/features/library/library_home_screen.dart';
import 'package:library_app/features/plans/plans_screen.dart';

import '../../helpers/fake_library_sync.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeLibrarySync sync;
  setUp(() => sync = FakeLibrarySync());

  Future<void> pull(WidgetTester tester, Finder scrollable) async {
    await tester.fling(scrollable, const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('pulling the library home checks GitHub', (tester) async {
    await pumpApp(
      tester,
      const LibraryHomeScreen(),
      overrides: [librarySyncProvider.overrideWithValue(sync)],
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
    await pull(tester, find.text('ACTIVE PLAN'));
    expect(sync.checks, 1);
  });

  testWidgets('pulling a type view checks GitHub too', (tester) async {
    await pumpApp(
      tester,
      const LibraryHomeScreen(),
      overrides: [librarySyncProvider.overrideWithValue(sync)],
    );
    await tester.tap(find.text('Movies').first);
    await tester.pumpAndSettle();
    await pull(tester, find.byType(Scrollable).last);
    expect(sync.checks, 1);
  });

  testWidgets('pulling the plans overview checks GitHub', (tester) async {
    await pumpApp(
      tester,
      const PlansScreen(),
      overrides: [librarySyncProvider.overrideWithValue(sync)],
    );
    await pull(tester, find.text('Plans'));
    expect(sync.checks, 1);
  });
}
