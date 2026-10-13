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
    expect(find.text('Not synced yet'), findsOneWidget);
    expect(find.text('ekmanch/library'), findsOneWidget);
    expect(find.text('library.json'), findsOneWidget);
    expect(find.text('Saved on this phone'), findsOneWidget);
    expect(
      find.text('When you open Libri, then every 5 minutes'),
      findsOneWidget,
    );
  });

  test('the last synced line reads from the sync state', () {
    final now = DateTime(2026, 10, 13, 20, 30);
    expect(ConnectionScreen.lastSyncedLabel(null, now: now), 'Not synced yet');
    expect(
      ConnectionScreen.lastSyncedLabel(
        now.subtract(const Duration(minutes: 3)),
        now: now,
      ),
      'Last synced 3 minutes ago',
    );
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
