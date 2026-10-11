import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/models/library.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/data/repository/library_repository.dart';
import 'package:library_app/features/settings/display_preferences.dart';
import 'package:library_app/theme/app_theme.dart';

/// The bundled fixture, read once per test file.
Library loadFixture() =>
    decodeLibrary(File(FixtureLibraryRepository.assetPath).readAsStringSync());

/// Pumps [home] inside a MaterialApp with the app theme and a provider
/// container whose repository serves [library]. Returns the container.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  Widget home, {
  Library? library,
  Size size = const Size(390, 844),
  DisplayPreferences? prefs,
  LibraryRepository? repository,
}) async {
  final lib = library ?? loadFixture();
  final container = ProviderContainer(
    overrides: [
      libraryRepositoryProvider.overrideWithValue(
        repository ??
            FixtureLibraryRepository(loadJson: () async => encodeLibrary(lib)),
      ),
    ],
  );
  if (prefs != null) {
    container.read(displayPreferencesProvider.notifier).replace(prefs);
  }
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.dark),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
