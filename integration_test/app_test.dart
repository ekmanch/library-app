import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/data/operations/operations.dart';
import 'package:library_app/features/settings/display_preferences.dart';
import 'package:library_app/main.dart';

// Run on the Linux dev target: flutter test integration_test -d linux
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('libri-app-'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// Starts the app on [dir] and waits until the library file is loaded,
  /// which is real file I/O and takes more than one frame.
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(await bootstrap(dir));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('ACTIVE PLAN').evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(LibraryApp)));

  testWidgets('launches and loads the bundled fixture', (tester) async {
    await launch(tester);

    // Title and the navigation item.
    expect(find.text('Library'), findsNWidgets(2));
    expect(find.text('Plans'), findsOneWidget);
    expect(find.text('ACTIVE PLAN'), findsOneWidget);
    expect(File('${dir.path}/library.json').existsSync(), isTrue);
  });

  testWidgets('changes and display choices survive a restart', (tester) async {
    await launch(tester);
    final first = container(tester);
    final entry = first.read(libraryProvider).value!.entries.first;
    final status = entry.status == EntryStatus.want
        ? EntryStatus.done
        : EntryStatus.want;
    await first
        .read(libraryRepositoryProvider)
        .apply(SetStatus(entry.id, status));
    first
        .read(displayPreferencesProvider.notifier)
        .setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();

    // A fresh app on the same folder, as after a restart.
    await tester.pumpWidget(const SizedBox());
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
    final text = File('${dir.path}/library.json').readAsStringSync();
    expect(encodeLibrary(decodeLibrary(text)), text);
  });
}
