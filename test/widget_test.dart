import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/main.dart';

void main() {
  testWidgets('the app starts on the fixture with the app theme', (
    tester,
  ) async {
    // Read synchronously: real file I/O never completes in the test zone.
    final text = File(FixtureLibraryRepository.assetPath).readAsStringSync();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(
            FixtureLibraryRepository(loadJson: () async => text),
          ),
        ],
        child: const LibraryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsNWidgets(2)); // Title and nav item.
    expect(find.textContaining('entries'), findsOneWidget);
    expect(find.textContaining('Could not load'), findsNothing);

    final title = tester.widget<Text>(find.text('Library').first);
    expect(title.style?.fontFamily, 'Bricolage Grotesque');
    expect(
      Theme.of(tester.element(find.text('Library').first)).brightness,
      Brightness.dark,
    );
  });
}
