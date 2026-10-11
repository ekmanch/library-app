import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/features/library/cover_grid_tile.dart';
import 'package:library_app/features/library/cover_placeholder.dart';
import 'package:library_app/features/library/entry_list_body.dart';
import 'package:library_app/features/library/home_type_provider.dart';
import 'package:library_app/features/library/library_filter.dart';
import 'package:library_app/features/library/library_filter_provider.dart';
import 'package:library_app/features/library/library_home_screen.dart';
import 'package:library_app/features/library/library_sort.dart';
import 'package:library_app/features/settings/display_preferences.dart';
import 'package:library_app/features/settings/entry_view.dart';
import 'package:library_app/widgets/chips.dart';
import 'package:library_app/widgets/entry_row.dart';
import 'package:library_app/widgets/section_heading.dart';
import 'package:library_app/widgets/segmented_control.dart';

import 'package:library_app/dev/long_lists.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/sample_library.dart';

void main() {
  final fixture = loadFixture();
  List<String> visibleOf(MediaType type) => fixture
      .entriesOfType(type)
      .where((e) => !e.seasonalOnly)
      .map((e) => e.title)
      .toList();
  final movies = visibleOf(MediaType.movies);

  /// Scrolls the chip row (lazy, so a far chip is not built yet) and taps.
  Future<void> pickChip(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(PillChip, label);
    final row = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    );
    // "All" is the first chip, so scroll back toward it.
    final dx = label == 'All' ? 80.0 : -80.0;
    await tester.dragUntilVisible(chip, row, Offset(dx, 0));
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  Finder inSegments(String label) => find.descendant(
    of: find.byType(StatusSegmentedControl),
    matching: find.text(label),
  );

  testWidgets('All: two rows per type under a heading with the count', (
    tester,
  ) async {
    await pumpApp(tester, const LibraryHomeScreen());
    expect(find.text('ACTIVE PLAN'), findsOneWidget);
    expect(find.text('Halloween 2026'), findsOneWidget);
    expect(find.text('See all'), findsNothing);
    expect(find.text('Search titles and tags'), findsOneWidget);

    final heading = find.widgetWithText(SectionHeading, 'MOVIES');
    expect(heading, findsOneWidget);
    expect(
      find.descendant(of: heading, matching: find.text('${movies.length}')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Show all movies'), findsOneWidget);

    // Movies: first two rows in home order start with the in-progress one.
    final rows = tester.widgetList<EntryRow>(find.byType(EntryRow)).toList();
    expect(rows.first.title, 'Paddington 2');
    expect(find.byType(StatusSegmentedControl), findsNothing);
  });

  testWidgets('a type chip shows that type in place with segments and count', (
    tester,
  ) async {
    final container = await pumpApp(tester, const LibraryHomeScreen());
    await pickChip(tester, 'Books');
    final books = visibleOf(MediaType.books);
    expect(container.read(homeTypeProvider), MediaType.books);
    expect(find.text('MOVIES'), findsNothing);
    expect(find.text('BOOKS'), findsNothing);
    expect(find.text('ACTIVE PLAN'), findsNothing);
    expect(find.byType(StatusSegmentedControl), findsOneWidget);
    expect(find.text('${books.length} books'), findsOneWidget);
    expect(find.byType(EntryRow), findsNWidgets(books.length));
    expect(find.text('Search books'), findsOneWidget);
    expect(find.text('Newest added'), findsOneWidget);
    expect(find.byTooltip('Change view'), findsOneWidget);

    await pickChip(tester, 'All');
    expect(container.read(homeTypeProvider), isNull);
    expect(find.text('MOVIES'), findsOneWidget);
    expect(find.text('ACTIVE PLAN'), findsOneWidget);
  });

  testWidgets(
    'the active plan card opens the plan (in place without a shell)',
    (tester) async {
      await pumpApp(tester, const LibraryHomeScreen());
      await tester.tap(find.text('Halloween 2026'));
      await tester.pumpAndSettle();
      expect(find.text('This plan'), findsOneWidget);
      expect(find.text('2 of 8 done'), findsOneWidget);
    },
  );

  testWidgets('a type heading opens that type, like its chip', (tester) async {
    final container = await pumpApp(tester, const LibraryHomeScreen());
    await tester.tap(find.bySemanticsLabel('Show all movies'));
    await tester.pumpAndSettle();
    expect(container.read(homeTypeProvider), MediaType.movies);
    expect(find.text('${movies.length} movies'), findsOneWidget);
    expect(find.byType(EntryRow), findsNWidgets(movies.length));
  });

  testWidgets('segments filter by status and reset when the type changes', (
    tester,
  ) async {
    await pumpApp(tester, const LibraryHomeScreen());
    await pickChip(tester, 'Movies');
    await tester.tap(inSegments('Want'));
    await tester.pumpAndSettle();
    final wanted = fixture
        .entriesOfType(MediaType.movies)
        .where((e) => !e.seasonalOnly && e.status == EntryStatus.want)
        .length;
    expect(find.text('$wanted movies'), findsOneWidget);
    expect(find.byType(EntryRow), findsNWidgets(wanted));

    await pickChip(tester, 'Shows');
    final shows = visibleOf(MediaType.shows);
    expect(find.text('${shows.length} shows'), findsOneWidget);
  });

  testWidgets('a status nothing has shows a line, not the empty state', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const LibraryHomeScreen(),
      library: fixture.copyWith(
        entries: [
          ...fixture.entries.where((e) => e.type != MediaType.movies),
          mummy,
        ],
      ),
    );
    await pickChip(tester, 'Movies');
    await tester.tap(inSegments('In progress'));
    await tester.pumpAndSettle();
    expect(find.text('0 movies'), findsOneWidget);
    expect(find.text('Nothing marked in progress yet.'), findsOneWidget);
    expect(find.byType(EntryRow), findsNothing);
  });

  testWidgets('the sort sheet changes the order and is remembered per type', (
    tester,
  ) async {
    final container = await pumpApp(tester, const LibraryHomeScreen());
    await pickChip(tester, 'Movies');
    await tester.tap(find.text('Newest added'));
    await tester.pumpAndSettle();
    expect(find.text('Sort by'), findsOneWidget);
    await tester.tap(find.text('Title, A to Z'));
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();

    final rows = tester
        .widgetList<EntryRow>(find.byType(EntryRow))
        .map((r) => r.title)
        .toList();
    expect(rows.first, 'Amélie');
    expect(
      container.read(displayPreferencesProvider).sortFor(MediaType.movies),
      LibrarySort.titleAz,
    );
    expect(
      container.read(displayPreferencesProvider).sortFor(MediaType.books),
      LibrarySort.newestAdded,
    );
  });

  testWidgets(
    'the view menu switches to covers and the grid, remembered per type',
    (tester) async {
      final container = await pumpApp(tester, const LibraryHomeScreen());
      await pickChip(tester, 'Movies');
      expect(find.byType(CoverPlaceholder), findsNothing);

      await tester.tap(find.byTooltip('Change view'));
      await tester.pumpAndSettle();
      expect(find.text('VIEW'), findsOneWidget);
      await tester.tap(find.text('List with photos'));
      await tester.pumpAndSettle();
      expect(find.byType(CoverPlaceholder), findsWidgets);
      expect(find.byType(EntryRow), findsWidgets);

      await tester.tap(find.byTooltip('Change view'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grid'));
      await tester.pumpAndSettle();
      expect(find.byType(CoverGridTile), findsWidgets);
      expect(find.bySemanticsLabel('Done'), findsWidgets);
      expect(
        container.read(displayPreferencesProvider).viewFor(MediaType.movies),
        EntryView.grid,
      );
      expect(
        container.read(displayPreferencesProvider).viewFor(MediaType.shows),
        EntryView.text,
      );
    },
  );

  testWidgets('music has artist tabs instead of status segments', (
    tester,
  ) async {
    await pumpApp(tester, const LibraryHomeScreen());
    await pickChip(tester, 'Music');
    expect(find.byType(StatusSegmentedControl), findsNothing);
    expect(find.text('Artists'), findsOneWidget);
    expect(find.text('Search music'), findsOneWidget);
  });

  testWidgets('an empty type shows its empty state', (tester) async {
    await pumpApp(
      tester,
      const LibraryHomeScreen(),
      library: fixture.copyWith(
        entries: fixture.entries
            .where((e) => e.type != MediaType.music)
            .toList(),
      ),
    );
    await pickChip(tester, 'Music');
    expect(find.text('No music yet'), findsOneWidget);
    expect(
      find.text('Albums and songs you add will show up here.'),
      findsOneWidget,
    );
    expect(find.text('Add music'), findsOneWidget);
    expect(find.byType(StatusSegmentedControl), findsNothing);
  });

  testWidgets('an active filter shows removable chips, a count and results', (
    tester,
  ) async {
    final container = await pumpApp(tester, const LibraryHomeScreen());
    container
        .read(libraryFilterProvider.notifier)
        .set(const LibraryFilter(types: {MediaType.shows}, tags: {'horror'}));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Remove Shows'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove #horror'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
    expect(find.text('ACTIVE PLAN'), findsNothing);
    expect(find.byType(PillChip), findsNothing);
    expect(find.textContaining(RegExp(r'^\d+ entr')), findsOneWidget);
    expect(find.text('SHOWS'), findsOneWidget);
    expect(find.text('MOVIES'), findsNothing);
    expect(find.text('2'), findsOneWidget); // The badge on the filter button.

    await tester.tap(find.bySemanticsLabel('Remove Shows'));
    await tester.pumpAndSettle();
    expect(container.read(libraryFilterProvider).types, isEmpty);
    expect(find.text('MOVIES'), findsOneWidget);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(container.read(libraryFilterProvider), LibraryFilter.none);
    expect(find.text('ACTIVE PLAN'), findsOneWidget);
  });

  testWidgets('a filter nothing matches shows the empty state', (tester) async {
    final container = await pumpApp(tester, const LibraryHomeScreen());
    container
        .read(libraryFilterProvider.notifier)
        .set(const LibraryFilter(tags: {'horror', 'cozy', 'jazz'}));
    await tester.pumpAndSettle();
    expect(find.text('Nothing matches these filters'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(container.read(libraryFilterProvider).isEmpty, isTrue);
  });

  testWidgets('the filter sheet applies a filter', (tester) async {
    final container = await pumpApp(tester, const LibraryHomeScreen());
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
    await tester.tap(find.widgetWithText(PillChip, 'Games'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Show '), findsOneWidget);
    await tester.tap(find.textContaining('Show '));
    await tester.pumpAndSettle();
    expect(container.read(libraryFilterProvider).types, {MediaType.games});
    expect(find.text('GAMES'), findsOneWidget);
  });

  testWidgets('search can pick a tag, which filters the home', (tester) async {
    final container = await pumpApp(tester, const LibraryHomeScreen());
    await tester.tap(find.text('Search titles and tags'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ghib');
    await tester.pumpAndSettle();
    expect(find.text('#ghibli'), findsOneWidget);
    expect(find.text('Tagged #ghibli'.toUpperCase()), findsOneWidget);
    await tester.tap(find.text('#ghibli'));
    await tester.pumpAndSettle();
    expect(container.read(libraryFilterProvider).tags, {'ghibli'});
    expect(find.text('ANIME'), findsOneWidget);
  });

  testWidgets('with a type picked, search covers only that type', (
    tester,
  ) async {
    final container = await pumpApp(tester, const LibraryHomeScreen());
    await pickChip(tester, 'Movies');
    await tester.tap(find.text('Search movies'));
    await tester.pumpAndSettle();
    expect(find.text('Search movies'), findsOneWidget); // The field's hint.
    await tester.enterText(find.byType(TextField), 'ghib');
    await tester.pumpAndSettle();
    expect(find.text('#ghibli'), findsNothing); // Only anime has it.
    expect(find.text('No results for "ghib"'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hallow');
    await tester.pumpAndSettle();
    expect(find.text('#halloween'), findsOneWidget);
    await tester.tap(find.text('#halloween'));
    await tester.pumpAndSettle();
    expect(
      container.read(libraryFilterProvider),
      const LibraryFilter(types: {MediaType.movies}, tags: {'halloween'}),
    );
    expect(find.text('MOVIES'), findsOneWidget);
    expect(find.text('SHOWS'), findsNothing);
  });

  testWidgets('search shows an empty state for no results', (tester) async {
    await pumpApp(tester, const LibraryHomeScreen());
    await tester.tap(find.text('Search titles and tags'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zelda');
    await tester.pumpAndSettle();
    expect(find.text('No results for "zelda"'), findsOneWidget);
    expect(find.text('Add "zelda"'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryHomeScreen), findsOneWidget);
  });

  testWidgets('an empty library shows an empty state', (tester) async {
    await pumpApp(
      tester,
      const LibraryHomeScreen(),
      library: fixture.copyWith(entries: [], plans: []),
    );
    expect(find.text('Your library is empty'), findsOneWidget);
  });

  testWidgets('seasonal-only entries appear only when included', (
    tester,
  ) async {
    final container = await pumpApp(tester, const LibraryHomeScreen());
    await pickChip(tester, 'Shows');
    expect(find.text('Over the Garden Wall'), findsNothing);
    container
        .read(libraryFilterProvider.notifier)
        .set(
          const LibraryFilter(
            types: {MediaType.shows},
            includeSeasonalOnly: true,
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Over the Garden Wall'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Remove Seasonal-only included'),
      findsOneWidget,
    );
  });

  group('long filtered results', () {
    final long = padForLongLists(fixture);

    testWidgets('several types: type sections and a rail of dots', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        const LibraryHomeScreen(),
        library: long,
      );
      container
          .read(libraryFilterProvider.notifier)
          .set(const LibraryFilter(types: {MediaType.movies, MediaType.shows}));
      await tester.pumpAndSettle();
      expect(find.text('MOVIES'), findsOneWidget);
      expect(find.byKey(EntryListBody.railKey), findsOneWidget);
      expect(find.byKey(const ValueKey('rail-dot-Movies')), findsOneWidget);
      expect(find.byKey(const ValueKey('rail-dot-Shows')), findsOneWidget);
      expect(find.text('20s'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('rail-dot-Shows')));
      await tester.pumpAndSettle();
      expect(find.text('SHOWS'), findsOneWidget);
      expect(tester.getTopLeft(find.text('SHOWS')).dy, lessThan(400));
    });

    testWidgets('one type: sections follow the sort, rail of labels', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        const LibraryHomeScreen(),
        library: long,
      );
      container
          .read(libraryFilterProvider.notifier)
          .set(const LibraryFilter(types: {MediaType.movies}));
      container
          .read(displayPreferencesProvider.notifier)
          .setFilteredSort(LibrarySort.yearNewest);
      await tester.pumpAndSettle();
      expect(find.text('MOVIES'), findsNothing);
      expect(find.text('2020s'), findsOneWidget);
      expect(find.text('20s'), findsOneWidget);
      expect(find.byKey(const ValueKey('rail-dot-Movies')), findsNothing);
      // With the chip row hidden, search is not scoped to a chip.
      container.read(homeTypeProvider.notifier).set(MediaType.books);
      await tester.pumpAndSettle();
      expect(find.text('Search titles and tags'), findsOneWidget);
    });

    testWidgets('a short filtered list keeps type headings and no rail', (
      tester,
    ) async {
      final container = await pumpApp(tester, const LibraryHomeScreen());
      container
          .read(libraryFilterProvider.notifier)
          .set(const LibraryFilter(types: {MediaType.movies}));
      await tester.pumpAndSettle();
      expect(find.text('MOVIES'), findsOneWidget);
      expect(find.byKey(EntryListBody.railKey), findsNothing);
    });
  });
}
