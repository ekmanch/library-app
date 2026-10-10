// Captures the app for a visual check against the design canvas. Writes
// screenshots/<name>.png (git-ignored) from the app process. Run on the
// Linux dev target:
//
//   flutter test integration_test/screenshots_test.dart -d linux
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/dev/long_lists.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/features/library/filter_sheet.dart';
import 'package:library_app/features/settings/display_preferences.dart';
import 'package:library_app/main.dart';
import 'package:library_app/widgets/chips.dart';

/// Wraps the whole app, including sheets, dialogs and menus in the root
/// overlay, so a capture shows what the user sees.
final _root = GlobalKey();

Future<void> capture(WidgetTester tester, String name) async {
  final boundary =
      _root.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('screenshots/$name.png');
  await file.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint('Wrote ${file.absolute.path}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('library screens in dark and light', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(
            FixtureLibraryRepository(),
          ),
        ],
        child: RepaintBoundary(key: _root, child: const LibraryApp()),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, 'a1-home-dark');

    // A4 and A21: Movies picked, text and grid.
    await tester.tap(find.widgetWithText(PillChip, 'Movies'));
    await tester.pumpAndSettle();
    await capture(tester, 'a4-movies-text');
    await tester.tap(find.byTooltip('Change view'));
    await tester.pumpAndSettle();
    await capture(tester, 'a16-view-menu');
    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    await capture(tester, 'a21-movies-grid');
    await tester.tap(find.text('Newest added'));
    await tester.pumpAndSettle();
    await capture(tester, 'd1-sort');
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PillChip, 'All'));
    await tester.pumpAndSettle();

    // A2 and A3: filter to shows tagged horror.
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(FilterSheet),
        matching: find.widgetWithText(PillChip, 'Shows'),
      ),
    );
    await tester.tap(find.widgetWithText(PillChip, '#horror'));
    await tester.pumpAndSettle();
    await capture(tester, 'a2-filter-sheet');
    await tester.tap(find.textContaining('Show '));
    await tester.pumpAndSettle();
    await capture(tester, 'a3-filtered');
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    // A5: search.
    await tester.tap(find.text('Search titles and tags'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'hal');
    await tester.pumpAndSettle();
    await capture(tester, 'a5-search');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // D8: home in light.
    final container = ProviderScope.containerOf(
      tester.element(find.text('Library').first),
    );
    container
        .read(displayPreferencesProvider.notifier)
        .setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    await capture(tester, 'd8-home-light');
  });

  testWidgets('long lists with the rail and the grid thumb', (tester) async {
    // Enough entries for three screens, spread over the decades.
    final long = padForLongLists(
      decodeLibrary(
        await File(FixtureLibraryRepository.assetPath).readAsString(),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(
            FixtureLibraryRepository(loadJson: () async => encodeLibrary(long)),
          ),
        ],
        child: RepaintBoundary(key: _root, child: const LibraryApp()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PillChip, 'Movies'));
    await tester.pumpAndSettle();
    await capture(tester, 'a24-rail-newest-added');

    await tester.tap(find.text('Newest added'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year, newest first'));
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90s'));
    await tester.pumpAndSettle();
    await capture(tester, 'a23-rail-year');

    await tester.tap(find.byTooltip('Change view'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(372, 330));
    await tester.pump();
    await gesture.moveTo(const Offset(372, 520));
    await tester.pump(const Duration(milliseconds: 250));
    await capture(tester, 'a26-grid-thumb');
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
