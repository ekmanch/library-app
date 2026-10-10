import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/features/entry/entry_details_sheet.dart';
import 'package:library_app/features/library/cover_placeholder.dart';
import 'package:library_app/features/settings/display_preferences.dart';
import 'package:library_app/features/settings/entry_view.dart';
import 'package:library_app/widgets/segmented_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/pump_app.dart';

const _mummy = 'movies/the-mummy-1999';

class _Opener extends StatelessWidget {
  const _Opener(this.entryId);
  final String entryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showEntryDetailsSheet(context, entryId),
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  Future<ProviderContainer> open(
    WidgetTester tester, {
    String entryId = _mummy,
  }) async {
    final container = await pumpApp(tester, _Opener(entryId));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return container;
  }

  FixtureLibraryRepository repo(ProviderContainer c) =>
      c.read(libraryRepositoryProvider) as FixtureLibraryRepository;

  Finder inSegments(String label) => find.descendant(
    of: find.byType(StatusSegmentedControl),
    matching: find.text(label),
  );

  testWidgets('shows kind, title, creator, rating, note, about, tags, plans', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('MOVIE · 1999'), findsOneWidget);
    expect(find.text('The Mummy'), findsOneWidget);
    expect(find.text('Stephen Sommers'), findsOneWidget);
    expect(find.text('9 / 10'), findsOneWidget);
    expect(find.text('NOTE'), findsOneWidget);
    expect(find.text('Perfect October comfort film.'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('#adventure'), findsOneWidget);
    expect(find.text('In plans'), findsOneWidget);
    expect(find.text('Halloween 2026'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.byType(CoverPlaceholder), findsNothing);
  });

  testWidgets('empty note and about are left out; no plans says so', (
    tester,
  ) async {
    await open(tester, entryId: 'movies/dune-part-two-2024');
    expect(find.text('NOTE'), findsNothing);
    expect(find.text('ABOUT'), findsNothing);
    expect(find.text('Not in any plan'), findsOneWidget);
  });

  testWidgets('a photo view shows the cover spot', (tester) async {
    final container = await pumpApp(tester, const _Opener(_mummy));
    container
        .read(displayPreferencesProvider.notifier)
        .setView(MediaType.movies, EntryView.grid);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(CoverPlaceholder), findsOneWidget);
  });

  testWidgets('a song offers only Want and Done', (tester) async {
    await open(tester, entryId: 'music/human-fly-the-cramps');
    expect(find.text('SONG · 1981'), findsOneWidget);
    expect(find.text('The Cramps · Bad Music for Bad People'), findsOneWidget);
    expect(inSegments('Want'), findsOneWidget);
    expect(inSegments('Done'), findsOneWidget);
    expect(inSegments('In progress'), findsNothing);
    expect(inSegments('DNF'), findsNothing);
  });

  testWidgets('changing the status applies at once', (tester) async {
    final container = await open(tester);
    await tester.tap(inSegments('Want'));
    await tester.pumpAndSettle();
    expect(
      repo(container).current!.entryById(_mummy)!.status,
      EntryStatus.want,
    );
  });

  testWidgets('the rating picker sets and clears the rating', (tester) async {
    final container = await open(tester);
    await tester.tap(find.text('9 / 10'));
    await tester.pumpAndSettle();
    expect(find.text('Rating'), findsWidgets);
    expect(find.text('1 is the lowest'), findsOneWidget);
    expect(find.bySemanticsLabel('9 out of 10'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('5 out of 10'));
    await tester.pump();
    expect(find.text('5 / 10'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(repo(container).current!.entryById(_mummy)!.rating, 5);
    expect(find.text('5 / 10'), findsOneWidget);

    await tester.tap(find.text('5 / 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear rating'));
    await tester.pump();
    expect(find.text('Not rated'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(repo(container).current!.entryById(_mummy)!.rating, isNull);
    expect(find.text('Not rated'), findsOneWidget);
  });

  testWidgets('dismissing the rating picker changes nothing', (tester) async {
    final container = await open(tester);
    await tester.tap(find.text('9 / 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('2 out of 10'));
    await tester.tapAt(const Offset(195, 40)); // The scrim above the sheet.
    await tester.pumpAndSettle();
    expect(repo(container).current!.entryById(_mummy)!.rating, 9);
  });

  testWidgets('add to plan toggles plan items and marks repeats', (
    tester,
  ) async {
    final container = await open(tester);
    await tester.tap(find.text('Add to plan'));
    await tester.pumpAndSettle();
    expect(find.text('Add to plan'), findsWidgets);
    expect(find.bySemanticsLabel('Christmas 2026'), findsOneWidget);
    expect(find.text('Active'), findsNWidgets(2)); // Both have open items.

    await tester.tap(find.bySemanticsLabel('Christmas 2026'));
    await tester.pumpAndSettle();
    final christmas = repo(container).current!.planById('christmas-2026')!;
    final item = christmas.itemFor(_mummy)!;
    expect(item.repeat, isTrue); // The Mummy is already done.
    expect(item.done, isFalse);

    await tester.tap(find.bySemanticsLabel('Halloween 2026'));
    await tester.pumpAndSettle();
    expect(
      repo(container).current!.planById('halloween-2026')!.itemFor(_mummy),
      isNull,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('Christmas 2026'), findsOneWidget); // Now in the sheet.
  });

  testWidgets('delete asks first, names the plans, then closes the sheet', (
    tester,
  ) async {
    final container = await open(tester);
    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete The Mummy?'), findsOneWidget);
    expect(
      find.text(
        'It will be removed from your library and from the plan '
        'Halloween 2026.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo(container).current!.entryById(_mummy), isNotNull);
    expect(find.text('The Mummy'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Delete')),
    );
    await tester.pumpAndSettle();
    expect(repo(container).current!.entryById(_mummy), isNull);
    expect(find.text('The Mummy'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('edit opens the form and the sheet shows the saved change', (
    tester,
  ) async {
    final container = await open(tester);
    await tester.ensureVisible(find.text('Edit'));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit entry'), findsOneWidget);
    final title = find.widgetWithText(TextField, 'The Mummy');
    expect(title, findsOneWidget);
    await tester.enterText(title, 'The Mummy (1999)');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final entry = repo(container).current!.entryById(_mummy)!;
    expect(entry.title, 'The Mummy (1999)');
    expect(entry.rating, 9);
    expect(entry.tags, ['adventure', 'lighthearted', 'halloween', 'favorite']);
    expect(find.text('The Mummy (1999)'), findsOneWidget);
    expect(find.text('Edit entry'), findsNothing);
  });
}
