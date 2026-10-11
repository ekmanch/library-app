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
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/features/library/filter_sheet.dart';
import 'package:library_app/features/library/library_filter.dart';
import 'package:library_app/features/library/library_filter_provider.dart';
import 'package:library_app/features/library/library_sort.dart';
import 'package:library_app/features/plans/plan_entry_sheet.dart';
import 'package:library_app/features/settings/display_preferences.dart';
import 'package:library_app/features/shell/floating_nav_bar.dart';
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

/// Scrolls the chip row (lazy, so a far chip is not built yet) and taps.
Future<void> pickChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(PillChip, label);
  final row = find.byWidgetPredicate(
    (w) => w is ListView && w.scrollDirection == Axis.horizontal,
  );
  await tester.dragUntilVisible(
    chip,
    row,
    Offset(label == 'All' ? 80 : -80, 0),
  );
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

/// Taps the scrim just below the top of the frame, outside the sheet.
Future<void> closeSheet(WidgetTester tester) async {
  final barrier = find.byType(ModalBarrier).last;
  await tester.tapAt(tester.getTopLeft(barrier) + const Offset(195, 30));
  await tester.pumpAndSettle();
}

Future<void> pickView(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Change view'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
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

    // A6, D11, A7, A9: the details sheet and what opens from it.
    await tester.tap(find.widgetWithText(PillChip, 'Movies'));
    await tester.pumpAndSettle();
    // Movies is still in the grid view, so the sheet shows the cover spot.
    // A tile carries the title twice: on the placeholder and as the caption.
    await tester.ensureVisible(find.text('The Mummy').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Mummy').last);
    await tester.pumpAndSettle();
    await capture(tester, 'a6-entry-details');
    await tester.tap(find.text('9 / 10'));
    await tester.pumpAndSettle();
    await capture(tester, 'd11-rating');
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to plan'));
    await tester.pumpAndSettle();
    await capture(tester, 'a7-add-to-plan');
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await capture(tester, 'a9-delete');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // A8 edit, the tag picker, D9 and D10.
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await capture(tester, 'a8-edit-entry');
    await tester.ensureVisible(find.text('#adventure'));
    await tester.tap(find.text('#adventure'));
    await tester.pumpAndSettle();
    await capture(tester, 'a8-tag-picker');
    await tester.enterText(find.byType(TextField).last, 'sci-fi');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Create #sci-fi'));
    await tester.pumpAndSettle();
    await capture(tester, 'd9-similar-tag');
    await tester.tap(find.text('Create #sci-fi anyway'));
    await tester.pumpAndSettle();
    await capture(tester, 'd10-new-tag');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 30)); // Close the sheet.
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PillChip, 'All'));
    await tester.pumpAndSettle();

    // A13: a new entry, picking a match.
    await tester.tap(find.byType(AddButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'The Last of Us');
    await tester.pumpAndSettle();
    await capture(tester, 'a13-new-entry');
    await tester.tap(find.text('GAME · 2013'));
    await tester.pumpAndSettle();
    await capture(tester, 'a8-new-entry');
    await tester.scrollUntilVisible(
      find.text('Suggested · tap to add'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await capture(tester, 'a8-new-entry-tags');
    await tester.tap(find.widgetWithText(TagChip, '#horror'));
    await tester.pumpAndSettle();
    await capture(tester, 'd14-tag-picker');
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // A14, A17, A18: the music tabs in the three views.
    await pickChip(tester, 'Music');
    await capture(tester, 'a14-music-artists');
    await pickView(tester, 'List with photos');
    await capture(tester, 'a17-music-list-photos');
    await pickView(tester, 'Grid');
    await capture(tester, 'a18-music-grid');
    await pickView(tester, 'Text');

    // A15: one artist; A22: an album with its tracks.
    await tester.tap(find.text('Alice in Chains'));
    await tester.pumpAndSettle();
    await capture(tester, 'a15-artist');
    await tester.tap(find.text('Dirt'));
    await tester.pumpAndSettle();
    await capture(tester, 'a22-album-details');
    await tester.tapAt(const Offset(195, 30)); // Close the sheet.
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Albums'));
    await tester.pumpAndSettle();
    await capture(tester, 'a14-music-albums');
    await tester.tap(find.text('Songs'));
    await tester.pumpAndSettle();
    await capture(tester, 'a14-music-songs');

    // D12: saving an album whose song is already saved.
    await tester.tap(find.byType(AddButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill in the details myself'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Title',
      ),
      'Green River',
    );
    await tester.enterText(
      find
          .byWidgetPredicate(
            (w) => w is TextField && w.decoration?.hintText == 'Optional',
          )
          .first,
      'Creedence Clearwater Revival',
    );
    await tester.pumpAndSettle();
    await capture(tester, 'a8-new-album');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    await capture(tester, 'd12-replace-songs');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await pickChip(tester, 'All');

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

  testWidgets('the screens the first pass skips', (tester) async {
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
    final container = ProviderScope.containerOf(
      tester.element(find.text('Library').first),
    );

    // A10: a filter nothing matches.
    container
        .read(libraryFilterProvider.notifier)
        .set(const LibraryFilter(tags: {'horror', 'cozy', 'jazz'}));
    await tester.pumpAndSettle();
    await capture(tester, 'a10-empty-filter');
    container.read(libraryFilterProvider.notifier).clear();
    await tester.pumpAndSettle();

    // A20: Movies as a list with covers.
    await pickChip(tester, 'Movies');
    await pickView(tester, 'List with photos');
    await capture(tester, 'a20-movies-list-covers');
    await pickView(tester, 'Text');

    // A19: an artist with photos.
    await pickChip(tester, 'Music');
    await pickView(tester, 'List with photos');
    await tester.tap(find.text('Alice in Chains'));
    await tester.pumpAndSettle();
    await capture(tester, 'a19-artist-photos');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await pickView(tester, 'Text');

    // D13: a song whose album is saved.
    await tester.tap(find.byType(AddButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill in the details myself'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Song'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Title',
      ),
      'Rooster',
    );
    final optional = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Optional',
    );
    await tester.enterText(optional.at(0), 'Alice in Chains');
    await tester.enterText(optional.at(1), 'Dirt');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    await capture(tester, 'd13-replace-album');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await pickChip(tester, 'All');

    // S8 and the plan note; the linked tags and copy-from sheets.
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Christmas 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Die Hard'));
    await tester.pumpAndSettle();
    await capture(tester, 's8-plan-entry-no-timeline');
    await tester.tap(find.text('Add a note'));
    await tester.pumpAndSettle();
    await capture(tester, 'plan-note-sheet');
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 30));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Plan options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#christmas'));
    await tester.pumpAndSettle();
    await capture(tester, 's9-linked-tags-sheet');
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.text('Plans'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AddButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy a plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Copy from'));
    await tester.pumpAndSettle();
    await capture(tester, 's10-copy-from-sheet');
  });

  testWidgets('a narrow phone at a larger text size', (tester) async {
    // The Galaxy S25 is 360 logical pixels wide; 1.3 is a common font
    // setting. The app is framed to that size inside the Linux window.
    const size = Size(360, 780);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(
            FixtureLibraryRepository(),
          ),
        ],
        child: Center(
          child: RepaintBoundary(
            key: _root,
            child: SizedBox.fromSize(
              size: size,
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: const LibraryApp(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, 'narrow-a1-home');
    await pickChip(tester, 'Movies');
    await capture(tester, 'narrow-a4-movies');
    await tester.scrollUntilVisible(
      find.text('The Mummy'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Mummy').last);
    await tester.pumpAndSettle();
    await capture(tester, 'narrow-a6-details');
    await closeSheet(tester);
    await pickChip(tester, 'All');
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Halloween 2026'));
    await tester.pumpAndSettle();
    await capture(tester, 'narrow-s2-halloween');
    await tester.tap(find.text('All Halloween'));
    await tester.pumpAndSettle();
    await capture(tester, 'narrow-s4-pool');
    await tester.tap(find.text('This plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Mummy'));
    await tester.pumpAndSettle();
    await capture(tester, 'narrow-s7-plan-entry');
    await closeSheet(tester);
    // Back on the Library tab the "+" starts a new entry.
    await tester.tap(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.text('Library'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AddButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'The Last of Us');
    await tester.pumpAndSettle();
    await capture(tester, 'narrow-a13-new-entry');
    await tester.tap(find.text('GAME · 2013'));
    await tester.pumpAndSettle();
    await capture(tester, 'narrow-a8-form');
  });

  testWidgets('plans: overview, checklist, timeline, pool, dialogs', (
    tester,
  ) async {
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
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    await capture(tester, 's5-plans');

    // S11 and S2: the Halloween plan has the timeline on.
    await tester.tap(find.text('Halloween 2026'));
    await tester.pumpAndSettle();
    await capture(tester, 's2-s11-halloween-timeline');
    await tester.tap(find.bySemanticsLabel('Choose year'));
    await tester.pumpAndSettle();
    await capture(tester, 's1-year-menu');
    await tester.tap(find.text('2025'));
    await tester.pumpAndSettle();
    await capture(tester, 's1-s11-halloween-checklist');
    await tester.tap(find.byTooltip('Plan options'));
    await tester.pumpAndSettle();
    await capture(tester, 'd3-plan-menu');
    await tester.tap(find.text('Delete plan'));
    await tester.pumpAndSettle();
    await capture(tester, 'd5-delete-plan');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Halloween'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions: Hereditary'));
    await tester.pumpAndSettle();
    await capture(tester, 's4-pool');
    await tester.tap(find.text('This plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Choose year'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026'));
    await tester.pumpAndSettle();

    // S7, D2, D4 from an item on the timeline.
    await tester.tap(find.text('The Mummy'));
    await tester.pumpAndSettle();
    await capture(tester, 's7-plan-entry');
    await tester.tap(
      find.descendant(
        of: find.byType(PlanEntrySheet),
        matching: find.text('Oct 19–31'),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, 'd2-when');
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Remove'));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await capture(tester, 'd4-remove');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 30));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.text('Plans'),
      ),
    );
    await tester.pumpAndSettle();

    // S12 and S1: the Christmas checklist; S9 and S10.
    await tester.tap(find.text('Christmas 2026'));
    await tester.pumpAndSettle();
    await capture(tester, 's1-s12-christmas-checklist');
    await tester.tap(find.byTooltip('Plan options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit plan'));
    await tester.pumpAndSettle();
    await capture(tester, 's9-edit-plan');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.text('Plans'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AddButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy a plan'));
    await tester.pumpAndSettle();
    await capture(tester, 's10-new-plan');
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
    await capture(tester, 'l2-rail-newest-added');

    await tester.tap(find.text('Newest added'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year, newest first'));
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90s'));
    await tester.pumpAndSettle();
    await capture(tester, 'l1-rail-year');

    await tester.tap(find.byTooltip('Change view'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(372, 330));
    await tester.pump();
    await gesture.moveTo(const Offset(372, 520));
    await tester.pump(const Duration(milliseconds: 250));
    await capture(tester, 'l4-grid-thumb');
    await gesture.up();
    await tester.pumpAndSettle();

    // L5 and L6: filtered results, one type and several types.
    final container = ProviderScope.containerOf(
      tester.element(find.text('Library').first),
    );
    container
        .read(libraryFilterProvider.notifier)
        .set(const LibraryFilter(types: {MediaType.movies}));
    container
        .read(displayPreferencesProvider.notifier)
        .setFilteredSort(LibrarySort.yearNewest);
    await tester.pumpAndSettle();
    await tester.tap(find.text('00s'));
    await tester.pumpAndSettle();
    await capture(tester, 'l5-filtered-one-type');
    container
        .read(libraryFilterProvider.notifier)
        .set(const LibraryFilter(tags: {'halloween'}, types: {}));
    await tester.pumpAndSettle();
    container
        .read(libraryFilterProvider.notifier)
        .set(const LibraryFilter(types: {MediaType.movies, MediaType.shows}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rail-dot-Shows')));
    await tester.pumpAndSettle();
    await capture(tester, 'l6-filtered-several-types');

    // L3: the alphabet rail on a long artist list.
    container.read(libraryFilterProvider.notifier).clear();
    await tester.pumpAndSettle();
    await pickChip(tester, 'Music');
    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    await capture(tester, 'l3-rail-artists');
  });
}
