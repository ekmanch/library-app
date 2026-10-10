import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/features/settings/display_preferences.dart';
import 'package:library_app/main.dart';
import 'package:library_app/theme/app_theme.dart';

void main() {
  testWidgets('theme and accent changes apply to the whole app at once', (
    tester,
  ) async {
    final text = File(FixtureLibraryRepository.assetPath).readAsStringSync();
    final container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(
          FixtureLibraryRepository(loadJson: () async => text),
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

    ThemeData theme() => Theme.of(tester.element(find.text('Library').first));
    expect(theme().brightness, Brightness.dark);
    expect(theme().colorScheme.primary, Accents.hotPink.fill);

    final violet = Accents.vivid.first;
    container.read(displayPreferencesProvider.notifier).setAccent(violet);
    await tester.pumpAndSettle();
    expect(theme().colorScheme.primary, violet.fill);
    expect(theme().colorScheme.primaryContainer, violet.fill);

    container
        .read(displayPreferencesProvider.notifier)
        .setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(theme().brightness, Brightness.light);
    expect(theme().colorScheme.primary, violet.ink);
    expect(theme().colorScheme.primaryContainer, violet.fill);
  });

  test('preferences default to dark and hot pink', () {
    const prefs = DisplayPreferences();
    expect(prefs.themeMode, ThemeMode.dark);
    expect(prefs.accent, Accents.hotPink);
    expect(prefs.copyWith(themeMode: ThemeMode.light).accent, Accents.hotPink);
  });
}
