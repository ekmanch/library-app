import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/dev/fake_github_api.dart';
import 'package:library_app/data/sync/sync_status.dart';
import 'package:library_app/features/first_run/first_run_flow.dart';
import 'package:library_app/features/settings/connection_screen.dart';
import 'package:library_app/features/sync/sync_state.dart';

import '../../helpers/fake_library_sync.dart';
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
    final github = FakeGitHubApi.demo(encodeLibrary(loadFixture()));
    final container = await pumpApp(
      tester,
      const ConnectionScreen(),
      overrides: [
        gitHubApiFactoryProvider.overrideWithValue(
          ({required token, required repository}) => github,
        ),
      ],
    );
    await tester.tap(find.text('Replace token'));
    await tester.pumpAndSettle();
    expect(find.byType(FirstRunFlow), findsOneWidget);
    expect(find.text('Connect GitHub'), findsOneWidget);
    expect(find.text('STEP 1 OF 3'), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'github_pat_x');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save token'));
    await tester.pumpAndSettle();
    expect(github.requests, ['GET repo']);
    expect(container.read(tokenProvider), 'github_pat_x');
    expect(find.byType(FirstRunFlow), findsNothing);
    expect(find.byType(ConnectionScreen), findsOneWidget);
  });

  testWidgets('Disconnect asks first, then forgets the connection', (
    tester,
  ) async {
    final container = await pumpApp(tester, const ConnectionScreen());
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect from GitHub?'), findsOneWidget);
    expect(find.textContaining('will be lost'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(libraryConnectionProvider).connected, isTrue);
    expect(find.byType(ConnectionScreen), findsOneWidget);

    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Disconnect'),
      ),
    );
    await tester.pumpAndSettle();
    expect(container.read(libraryConnectionProvider).connected, isFalse);
  });

  testWidgets('with unsaved changes the dialog says so', (tester) async {
    final sync = FakeLibrarySync(
      const SyncStatus(phase: SyncPhase.offline, pendingCount: 2),
    );
    await pumpApp(
      tester,
      const ConnectionScreen(),
      overrides: [librarySyncProvider.overrideWithValue(sync)],
    );
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('2 changes waiting to be saved'), findsOneWidget);
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '2 changes have not been saved to GitHub yet and will be lost.',
      ),
      findsOneWidget,
    );
    expect(find.text('Disconnect anyway'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(sync.discards, 0);
  });

  testWidgets('Sync now and the status card follow the sync', (tester) async {
    final sync = FakeLibrarySync();
    await pumpApp(
      tester,
      const ConnectionScreen(),
      overrides: [librarySyncProvider.overrideWithValue(sync)],
    );
    expect(find.text('Connected'), findsOneWidget);
    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();
    expect(sync.syncNows, 1);
    sync.emit(const SyncStatus(phase: SyncPhase.saving, pendingCount: 1));
    await tester.pumpAndSettle();
    expect(find.text('Saving…'), findsOneWidget);
    expect(find.text('1 change waiting to be saved'), findsOneWidget);
    sync.emit(SyncStatus(lastSynced: DateTime.now()));
    await tester.pumpAndSettle();
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Last synced just now'), findsOneWidget);
  });
}
