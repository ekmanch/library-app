import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/features/first_run/first_run_flow.dart';
import 'package:library_app/features/shell/app_shell.dart';
import 'package:library_app/features/sync/sync_state.dart';
import 'package:library_app/main.dart';
import 'package:library_app/widgets/libri_logo.dart';

import '../../helpers/pump.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('the splash gives way to the welcome screen', (tester) async {
    await pumpApp(tester, const FirstRunFlow());
    expect(find.byType(LibriLogo), findsOneWidget);
    expect(find.text('Libri'), findsOneWidget);
    expect(find.text('Welcome to Libri'), findsNothing);
    await tester.pump(FirstRunFlow.splashDuration);
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Libri'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('creating a new library walks F2 to F7 and connects', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      const FirstRunFlow(initialStep: FirstRunStep.welcome),
    );
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // F3: Connect needs a repo and a token.
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(find.text('Connect GitHub'), findsOneWidget);
    final connect = find.widgetWithText(FilledButton, 'Connect');
    expect(tester.widget<FilledButton>(connect).enabled, isFalse);
    await tester.enterText(find.byType(TextField).first, 'ekmanch/library');
    await tester.enterText(find.byType(TextField).last, 'github_pat_x');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(connect).enabled, isTrue);
    await tester.tap(connect);
    await tester.pumpAndSettle();

    // F4: new is the default choice.
    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    expect(find.text('Your library file'), findsOneWidget);
    expect(find.textContaining('ekmanch/library'), findsOneWidget);
    expect(isSelected(tester, find.text('Create a new library')), isTrue);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // F5: the create step with its preview, then the fake delay.
    expect(find.text('STEP 3 OF 3'), findsOneWidget);
    expect(find.textContaining('"version": 2'), findsOneWidget);
    expect(find.text('Commit message: “Create Libri library”'), findsOneWidget);
    await tester.tap(find.text('Create library'));
    await tester.pump();
    expect(find.text('Creating…'), findsOneWidget);
    expect(
      find.text('Creating library.json and pushing to GitHub…'),
      findsOneWidget,
    );
    await tester.pump(FirstRunFlow.createDuration);
    await tester.pumpAndSettle();

    // F7.
    expect(find.text('You\'re all set'), findsOneWidget);
    expect(
      find.text(
        'library.json is now in ekmanch/library. '
        'Add your first entry with the + button.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Open Libri'));
    await tester.pumpAndSettle();
    final connection = container.read(libraryConnectionProvider);
    expect(connection.connected, isTrue);
    expect(connection.repository, 'ekmanch/library');
    expect(connection.file, 'library.json');
  });

  testWidgets('picking an existing file skips files that are not libraries', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      const FirstRunFlow(initialStep: FirstRunStep.file),
    );
    await tester.tap(find.text('Use a file I already have'));
    await tester.pumpAndSettle();
    expect(isSelected(tester, find.text('Use a file I already have')), isTrue);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Pick your file'), findsOneWidget);
    expect(isSelected(tester, find.text('library.json')), isTrue);
    await tester.tap(find.text('data/old-lists.json'));
    await tester.pumpAndSettle();
    expect(isSelected(tester, find.text('library.json')), isTrue);
    await tester.tap(find.text('backup/library-2025.json'));
    await tester.pumpAndSettle();
    expect(isSelected(tester, find.text('backup/library-2025.json')), isTrue);
    await tester.tap(find.text('Use this file'));
    await tester.pumpAndSettle();
    expect(
      find.text('Loaded 168 entries from backup/library-2025.json.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Open Libri'));
    await tester.pumpAndSettle();
    expect(
      container.read(libraryConnectionProvider).file,
      'backup/library-2025.json',
    );
  });

  testWidgets('back goes one step at a time, also with the system back', (
    tester,
  ) async {
    await pumpApp(tester, const FirstRunFlow(initialStep: FirstRunStep.file));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Connect GitHub'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Libri'), findsOneWidget);
  });

  testWidgets('the app shows the first run until connected, then the shell', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(
          FixtureLibraryRepository(
            loadJson: () async => encodeLibrary(loadFixture()),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(libraryConnectionProvider.notifier).disconnect();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LibraryApp(),
      ),
    );
    await tester.pump(FirstRunFlow.splashDuration);
    await tester.pumpAndSettle();
    expect(find.byType(FirstRunFlow), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    container
        .read(libraryConnectionProvider.notifier)
        .connect(repository: 'ekmanch/library', file: 'library.json');
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(FirstRunFlow), findsNothing);
  });
}
