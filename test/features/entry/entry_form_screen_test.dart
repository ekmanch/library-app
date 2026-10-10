import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/models/book_format.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/data/models/music_kind.dart';
import 'package:library_app/data/models/released.dart';
import 'package:library_app/data/models/tag_category.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/features/entry/entry_form_screen.dart';
import 'package:library_app/features/entry/lookup_matches.dart';
import 'package:library_app/widgets/chips.dart';
import 'package:library_app/widgets/segmented_control.dart';

import '../../helpers/pump_app.dart';

void main() {
  FixtureLibraryRepository repo(ProviderContainer c) =>
      c.read(libraryRepositoryProvider) as FixtureLibraryRepository;

  Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == label,
  );

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Add needs a title and a valid release date', (tester) async {
    final container = await pumpApp(
      tester,
      const EntryFormScreen.create(type: MediaType.movies),
    );
    expect(find.text('New entry'), findsOneWidget);
    expect(find.text('Director'), findsOneWidget);
    final add = find.widgetWithText(FilledButton, 'Add');
    expect(tester.widget<FilledButton>(add).onPressed, isNull);

    await tester.enterText(field('Title'), 'Carrie');
    await tester.pump();
    expect(tester.widget<FilledButton>(add).onPressed, isNotNull);

    await tester.enterText(field('Year or date'), '19x6');
    await tester.pump();
    expect(find.text(EntryFormScreen.releasedHelp), findsOneWidget);
    expect(tester.widget<FilledButton>(add).onPressed, isNull);

    await tester.enterText(field('Year or date'), '1976');
    await tester.enterText(field('Optional').first, 'Brian De Palma');
    await tester.pump();
    await tester.tap(add);
    await tester.pumpAndSettle();

    final entry = repo(container).current!.entries.last;
    expect(entry.id, 'movies/carrie-1976');
    expect(entry.title, 'Carrie');
    expect(entry.creator, 'Brian De Palma');
    expect(entry.released, const Released(1976));
    expect(entry.status, EntryStatus.want);
    expect(entry.rating, isNull);
    final today = DateTime.now();
    expect(entry.added, DateTime(today.year, today.month, today.day));
  });

  testWidgets('the type changes the creator label and the extra fields', (
    tester,
  ) async {
    await pumpApp(tester, const EntryFormScreen.create());
    await tester.tap(find.widgetWithText(PillChip, 'Books'));
    await tester.pumpAndSettle();
    expect(find.text('Author'), findsOneWidget);
    expect(find.text('Formats'), findsOneWidget);
    expect(find.text('Audiobook'), findsOneWidget);

    await tester.tap(find.widgetWithText(PillChip, 'Games'));
    await tester.pumpAndSettle();
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('Platform'), findsOneWidget);
    expect(find.text('Formats'), findsNothing);

    await tester.tap(find.widgetWithText(PillChip, 'Music'));
    await tester.pumpAndSettle();
    expect(find.text('Artist'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StatusSegmentedControl),
        matching: find.text('DNF'),
      ),
      findsNothing,
    );
  });

  testWidgets('a lookup match prefills the form and keeps its description', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      EntryFormScreen.create(match: fakeLookup('hounds').single),
    );
    expect(find.widgetWithText(TextField, 'Hounds of Love'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Kate Bush'), findsOneWidget);
    expect(find.widgetWithText(TextField, '1985'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    final entry = repo(container).current!.entries.last;
    expect(entry.id, 'music/hounds-of-love-kate-bush');
    expect(entry.kind, MusicKind.album);
    expect(entry.description, "Kate Bush's fifth studio album.");
  });

  testWidgets('a song match gets the album field', (tester) async {
    final container = await pumpApp(
      tester,
      EntryFormScreen.create(match: fakeLookup('running up').single),
    );
    expect(find.text('Album'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Hounds of Love'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    final entry = repo(container).current!.entries.last;
    expect(entry.kind, MusicKind.song);
    expect(entry.album, 'Hounds of Love');
  });

  testWidgets('editing keeps the id and the fields the form does not show', (
    tester,
  ) async {
    final fixture = loadFixture();
    final dracula = fixture.entryById('books/dracula-1897')!;
    final container = await pumpApp(tester, EntryFormScreen.edit(dracula));
    expect(find.text('Edit entry'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Dracula'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Bram Stoker'), findsOneWidget);
    expect(find.text('8 / 10'), findsOneWidget);
    expect(find.text('#horror'), findsOneWidget);

    await tester.tap(find.widgetWithText(PillChip, 'Audiobook'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    final saved = repo(container).current!.entryById('books/dracula-1897')!;
    expect(saved.formats, [BookFormat.physical]);
    expect(saved.description, dracula.description);
    expect(saved.added, dracula.added);
    expect(
      repo(container).current!.entries.indexOf(saved),
      fixture.entries.indexOf(dracula),
    );
  });

  testWidgets('the rating field opens the picker', (tester) async {
    await pumpApp(tester, const EntryFormScreen.create());
    await scrollTo(tester, find.text('Not rated'));
    await tester.tap(find.text('Not rated'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('7 out of 10'));
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('7 / 10'), findsOneWidget);
  });

  group('tag picker', () {
    Future<ProviderContainer> openPicker(WidgetTester tester) async {
      final container = await pumpApp(
        tester,
        const EntryFormScreen.create(type: MediaType.movies),
      );
      await tester.enterText(field('Title'), 'Nosferatu');
      await scrollTo(tester, find.text('Choose from your tags'));
      await tester.tap(find.text('Choose from your tags'));
      await tester.pumpAndSettle();
      expect(find.text('Tags'), findsWidgets);
      return container;
    }

    Future<void> done(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();
    }

    Future<void> add(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
    }

    testWidgets('picks existing tags from their groups', (tester) async {
      final container = await openPicker(tester);
      // Genre is open by default; Mood is collapsed until tapped.
      await tester.tap(find.widgetWithText(PillChip, '#horror'));
      expect(find.widgetWithText(PillChip, '#dark'), findsNothing);
      await tester.tap(find.text('Mood'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PillChip, '#dark'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsNWidgets(2));
      await done(tester);
      expect(find.text('#horror'), findsOneWidget);
      expect(find.text('#dark'), findsOneWidget);
      await add(tester);
      expect(repo(container).current!.entries.last.tags, ['horror', 'dark']);
    });

    testWidgets('a similar tag is offered instead (D9)', (tester) async {
      final container = await openPicker(tester);
      await tester.enterText(find.byType(TextField).last, 'sci-fi');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Create #sci-fi'));
      await tester.pumpAndSettle();
      expect(find.text('A similar tag exists'), findsOneWidget);
      expect(find.textContaining('used on'), findsOneWidget);
      await tester.tap(find.text('Use #scifi'));
      await tester.pumpAndSettle();
      await done(tester);
      await add(tester);
      final library = repo(container).current!;
      expect(library.entries.last.tags, ['scifi']);
      expect(library.allTags.contains('sci-fi'), isFalse);
    });

    testWidgets('a new tag is confirmed with a category (D10)', (tester) async {
      final container = await openPicker(tester);
      await tester.enterText(find.byType(TextField).last, 'Gothic');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Create #gothic'));
      await tester.pumpAndSettle();
      expect(find.text('Create a new tag?'), findsOneWidget);
      expect(
        find.text('It will be added to your tag list under Genre.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(PillChip, 'Mood'));
      await tester.pumpAndSettle();
      expect(
        find.text('It will be added to your tag list under Mood.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Create tag'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PillChip, '#gothic'), findsOneWidget);
      // Not in the library until the entry is saved.
      expect(repo(container).current!.allTags.contains('gothic'), isFalse);
      await done(tester);
      expect(find.text('#gothic'), findsOneWidget);
      await add(tester);
      final library = repo(container).current!;
      expect(library.tags[TagCategory.mood]!.last, 'gothic');
      expect(library.entries.last.tags, ['gothic']);
    });

    testWidgets('creating anyway after D9 goes through D10', (tester) async {
      final container = await openPicker(tester);
      await tester.enterText(find.byType(TextField).last, 'horrors');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Create #horrors'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create #horrors anyway'));
      await tester.pumpAndSettle();
      expect(find.text('Create a new tag?'), findsOneWidget);
      await tester.tap(find.text('Create tag'));
      await tester.pumpAndSettle();
      // Unpick it again: it must not be created.
      await tester.tap(find.widgetWithText(PillChip, '#horrors'));
      await tester.pumpAndSettle();
      await done(tester);
      await add(tester);
      final library = repo(container).current!;
      expect(library.allTags.contains('horrors'), isFalse);
      expect(library.entries.last.tags, isEmpty);
    });

    testWidgets('cancelling D9 and D10 changes nothing', (tester) async {
      await openPicker(tester);
      await tester.enterText(find.byType(TextField).last, 'cosy');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Create #cosy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('A similar tag exists'), findsNothing);
      expect(find.bySemanticsLabel('Create #cosy'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'moody');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Create #moody'));
      await tester.pumpAndSettle();
      expect(find.text('Create a new tag?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PillChip, '#moody'), findsNothing);
    });
  });
}
