import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/features/first_run/first_run_flow.dart';
import 'package:library_app/features/settings/connection_screen.dart';
import 'package:library_app/features/sync/sync_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the connection details', (tester) async {
    await pumpApp(tester, const ConnectionScreen());
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Last synced a few minutes ago'), findsOneWidget);
    expect(find.text('ekmanch/library'), findsOneWidget);
    expect(find.text('library.json'), findsOneWidget);
    expect(find.text('Saved on this phone'), findsOneWidget);
    expect(find.text('On open, then every 5 min'), findsOneWidget);
  });

  testWidgets('Sync now updates the last synced line', (tester) async {
    await pumpApp(tester, const ConnectionScreen());
    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();
    expect(find.text('Last synced just now'), findsOneWidget);
  });

  testWidgets('Replace token opens the connect step on its own', (
    tester,
  ) async {
    await pumpApp(tester, const ConnectionScreen());
    await tester.tap(find.text('Replace token'));
    await tester.pumpAndSettle();
    expect(find.byType(FirstRunFlow), findsOneWidget);
    expect(find.text('Connect GitHub'), findsOneWidget);
    expect(find.text('STEP 1 OF 3'), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'github_pat_x');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save token'));
    await tester.pumpAndSettle();
    expect(find.byType(FirstRunFlow), findsNothing);
    expect(find.byType(ConnectionScreen), findsOneWidget);
  });

  testWidgets('Disconnect leaves the screen and forgets the connection', (
    tester,
  ) async {
    final container = await pumpApp(tester, const ConnectionScreen());
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(container.read(libraryConnectionProvider).connected, isFalse);
  });
}
