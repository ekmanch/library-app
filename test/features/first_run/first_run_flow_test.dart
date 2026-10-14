import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/github/github_api.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/models/library.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/dev/fake_github_api.dart';
import 'package:library_app/features/first_run/first_run_flow.dart';
import 'package:library_app/features/shell/app_shell.dart';
import 'package:library_app/features/sync/sync_state.dart';
import 'package:library_app/main.dart';
import 'package:library_app/widgets/libri_logo.dart';

import '../../helpers/pump.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeGitHubApi github;
  final fixtureText = encodeLibrary(loadFixture());

  setUp(() => github = FakeGitHubApi.demo(fixtureText));

  /// The flow with the fake repo behind every token.
  Future<ProviderContainer> pumpFlow(
    WidgetTester tester, {
    FirstRunStep step = FirstRunStep.welcome,
  }) => pumpApp(
    tester,
    FirstRunFlow(initialStep: step),
    overrides: [
      gitHubApiFactoryProvider.overrideWithValue(
        ({required token, required repository}) => github,
      ),
    ],
  );

  /// F3 with the fields filled in and Connect pressed.
  Future<void> connect(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'ekmanch/library');
    await tester.enterText(find.byType(TextField).last, 'github_pat_x');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();
  }

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
    github = FakeGitHubApi(); // An empty repo.
    final container = await pumpFlow(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // F3: Connect needs a repo and a token, then asks GitHub.
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(find.text('Connect GitHub'), findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'Connect');
    expect(tester.widget<FilledButton>(button).enabled, isFalse);
    await connect(tester);
    expect(github.requests, ['GET repo']);

    // F4: new is the default choice.
    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    expect(find.text('Your library file'), findsOneWidget);
    expect(find.textContaining('ekmanch/library'), findsOneWidget);
    expect(isSelected(tester, find.text('Create a new library')), isTrue);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // F5: the create step with its preview, then the commit.
    expect(find.text('STEP 3 OF 3'), findsOneWidget);
    expect(find.textContaining('"version": 2'), findsOneWidget);
    expect(find.text('Commit message: “Create Libri library”'), findsOneWidget);
    await tester.tap(find.text('Create library'));
    await tester.pumpAndSettle();
    expect(github.text('library.json'), encodeLibrary(const Library()));
    final commits = await github.commits('library.json', branch: 'main');
    expect(commits.single.message, 'Create Libri library');

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
    expect(connection.branch, 'main');
    expect(container.read(tokenProvider), 'github_pat_x');
  });

  testWidgets('the create step shows its progress and refuses an existing '
      'file', (tester) async {
    github.latency = const Duration(milliseconds: 300);
    await pumpFlow(tester, step: FirstRunStep.connect);
    await tester.enterText(find.byType(TextField).first, 'ekmanch/library');
    await tester.enterText(find.byType(TextField).last, 'github_pat_x');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pump();
    expect(find.text('Connecting…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create library'));
    await tester.pump();
    expect(find.text('Creating…'), findsOneWidget);
    expect(
      find.text('Creating library.json and pushing to GitHub…'),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('A file named library.json already exists'),
      findsOneWidget,
    );
    expect(find.text('Create library'), findsOneWidget);
    expect(find.text('You\'re all set'), findsNothing);
    expect(github.text('library.json'), isNot(encodeLibrary(const Library())));
  });

  testWidgets('F3 says what went wrong with the token or the repo', (
    tester,
  ) async {
    await pumpFlow(tester, step: FirstRunStep.connect);
    for (final (failure, message) in [
      (GitHubFailure.unauthorized, 'GitHub refused the token'),
      (GitHubFailure.notFound, 'Repository not found, or the token cannot'),
      (GitHubFailure.offline, 'No connection'),
      (GitHubFailure.rateLimited, 'rate limiting'),
    ]) {
      github.failure = failure;
      await connect(tester);
      expect(find.textContaining(message), findsOneWidget, reason: '$failure');
      expect(find.text('Your library file'), findsNothing);
    }
    github.failure = null;
    github.canPush = false;
    await connect(tester);
    expect(find.textContaining('not write to it'), findsOneWidget);
    github.canPush = true;
    await connect(tester);
    expect(find.text('Your library file'), findsOneWidget);
  });

  testWidgets('picking an existing file skips files that are not libraries', (
    tester,
  ) async {
    github.latency = const Duration(milliseconds: 50);
    final container = await pumpFlow(tester, step: FirstRunStep.connect);
    await connect(tester);
    await tester.tap(find.text('Use a file I already have'));
    await tester.pumpAndSettle();
    expect(isSelected(tester, find.text('Use a file I already have')), isTrue);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Looking for JSON files in the repo…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Pick your file'), findsOneWidget);
    expect(
      find.text('Libri library · 63 entries · updated 2 days ago'),
      findsOneWidget,
    );
    expect(find.textContaining('31 entries · updated Mar 14'), findsOneWidget);
    expect(find.text('Not a Libri library file'), findsOneWidget);
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
      find.text('Loaded 31 entries from backup/library-2025.json.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Open Libri'));
    await tester.pumpAndSettle();
    expect(
      container.read(libraryConnectionProvider).file,
      'backup/library-2025.json',
    );
  });

  testWidgets('F6 reports a failed listing and can try again', (tester) async {
    await pumpFlow(tester, step: FirstRunStep.connect);
    await connect(tester);
    github.failure = GitHubFailure.offline;
    await tester.tap(find.text('Use a file I already have'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No connection'), findsOneWidget);
    expect(find.text('Use this file'), findsNothing);
    github.failure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('library.json'), findsOneWidget);
    expect(find.text('Use this file'), findsOneWidget);
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
    container
        .read(libraryConnectionProvider.notifier)
        .disconnect(keepLibrary: false);
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
    await container
        .read(libraryConnectionProvider.notifier)
        .connect(
          repository: 'ekmanch/library',
          file: 'library.json',
          branch: 'main',
          token: 'github_pat_x',
        );
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(FirstRunFlow), findsNothing);
  });

  testWidgets('deleting the library from the phone starts over at F2; '
      'keeping it stays on the shell', (tester) async {
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
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LibraryApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);

    await container
        .read(libraryConnectionProvider.notifier)
        .disconnect(keepLibrary: true);
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(container.read(libraryConnectionProvider).keptLocally, isTrue);

    await container
        .read(libraryConnectionProvider.notifier)
        .disconnect(keepLibrary: false);
    await tester.pumpAndSettle();
    expect(find.byType(FirstRunFlow), findsOneWidget);
    // Straight to the welcome screen, not the splash.
    expect(find.text('Get started'), findsOneWidget);
  });
}
