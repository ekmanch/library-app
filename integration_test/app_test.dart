import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:library_app/data/github/github_api.dart';
import 'package:library_app/data/github/token_store.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/data/operations/operations.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/dev/fake_github_api.dart';
import 'package:library_app/features/first_run/first_run_flow.dart';
import 'package:library_app/features/settings/display_preferences.dart';
import 'package:library_app/main.dart';

// Run on the Linux dev target: flutter test integration_test -d linux
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late FakeGitHubApi github;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('libri-app-');
    github = FakeGitHubApi(
      files: {
        'library.json': await File(FixtureLibraryRepository.assetPath)
            .readAsString(),
      },
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// A phone that was connected on an earlier run.
  void storeConnection() {
    File('${dir.path}/connection.json').writeAsStringSync(
      '{"repository": "ekmanch/library", "file": "library.json", '
      '"branch": "main"}\n',
    );
  }

  /// Starts the app on [dir] and waits until the library is loaded, which
  /// is real file I/O and takes more than one frame.
  Future<void> launch(WidgetTester tester, {String? token = 'x'}) async {
    await tester.pumpWidget(
      await bootstrap(
        dir,
        tokenStore: MemoryTokenStore(token),
        api: ({required token, required repository}) => github,
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('ACTIVE PLAN').evaluate().isNotEmpty) break;
      if (find.byType(FirstRunFlow).evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(LibraryApp)));

  testWidgets('a new install starts with the first run', (tester) async {
    await launch(tester, token: null);
    expect(find.byType(FirstRunFlow), findsOneWidget);
    expect(File('${dir.path}/library.json').existsSync(), isFalse);
  });

  testWidgets('a connected phone loads the library from GitHub', (
    tester,
  ) async {
    storeConnection();
    await launch(tester);

    // Title and the navigation item.
    expect(find.text('Library'), findsNWidgets(2));
    expect(find.text('Plans'), findsOneWidget);
    expect(find.text('ACTIVE PLAN'), findsOneWidget);
    expect(File('${dir.path}/library.json').existsSync(), isTrue);
    expect(File('${dir.path}/sync.json').existsSync(), isTrue);
    expect(github.requests.first, 'GET library.json');
  });

  testWidgets('an unreadable token means the first run', (tester) async {
    storeConnection();
    await tester.pumpWidget(
      await bootstrap(
        dir,
        tokenStore: _BrokenTokenStore(),
        api: ({required token, required repository}) => github,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FirstRunFlow), findsOneWidget);
  });

  testWidgets('offline changes and display choices survive a restart', (
    tester,
  ) async {
    storeConnection();
    await launch(tester);
    final first = container(tester);
    final entry = first.read(libraryProvider).value!.entries.first;
    final status = entry.status == EntryStatus.want
        ? EntryStatus.done
        : EntryStatus.want;
    github.failure = GitHubFailure.offline;
    await first
        .read(libraryRepositoryProvider)
        .apply(SetStatus(entry.id, status));
    first
        .read(displayPreferencesProvider.notifier)
        .setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(github.putCount, 0);

    // A fresh app on the same folder, as after a restart, back online.
    await tester.pumpWidget(const SizedBox());
    github.failure = null;
    await launch(tester);
    final second = container(tester);
    expect(
      second.read(libraryProvider).value!.entryById(entry.id)!.status,
      status,
    );
    expect(second.read(displayPreferencesProvider).themeMode, ThemeMode.light);
    expect(
      Theme.of(tester.element(find.text('Plans'))).brightness,
      Brightness.light,
    );
    // The queued change went out on load.
    for (var i = 0; i < 50 && github.putCount == 0; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(github.putCount, 1);
    expect(
      decodeLibrary(github.text('library.json')!).entryById(entry.id)!.status,
      status,
    );
    final text = File('${dir.path}/library.json').readAsStringSync();
    expect(encodeLibrary(decodeLibrary(text)), text);
  });
}

class _BrokenTokenStore implements TokenStore {
  @override
  Future<String?> read() => throw StateError('keystore unavailable');

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}
