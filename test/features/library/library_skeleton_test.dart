import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/features/library/library_home_screen.dart';
import 'package:library_app/features/library/library_skeleton.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('the home shows the loading skeleton until the library arrives', (
    tester,
  ) async {
    // A repository whose file never arrives.
    final never = Completer<String>();
    await pumpApp(
      tester,
      const LibraryHomeScreen(),
      repository: FixtureLibraryRepository(loadJson: () => never.future),
    );
    expect(find.byType(LibrarySkeleton), findsOneWidget);
    expect(find.text('Loading your library from GitHub'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.text('Search titles and tags'), findsNothing);
  });
}
