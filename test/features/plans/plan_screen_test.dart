import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/features/plans/plan_entry_sheet.dart';
import 'package:library_app/features/plans/plan_screen.dart';
import 'package:library_app/features/plans/seasonal_art.dart';
import 'package:library_app/features/plans/when_sheet.dart';
import 'package:library_app/features/shell/fab_action.dart';
import 'package:library_app/features/shell/floating_nav_bar.dart';
import 'package:library_app/theme/app_theme.dart';
import 'package:library_app/widgets/app_buttons.dart';
import 'package:library_app/widgets/chips.dart';

import '../../helpers/pump_app.dart';

void main() {
  FixtureLibraryRepository repo(ProviderContainer c) =>
      c.read(libraryRepositoryProvider) as FixtureLibraryRepository;

  Future<ProviderContainer> open(WidgetTester tester, String planId) =>
      pumpApp(tester, PlanScreen(planId: planId, tab: ShellTab.plans));

  Finder check(String title) =>
      find.byWidgetPredicate((w) => w is PlanCheck && w.title == title);

  group('checklist (S1)', () {
    testWidgets('groups by type, with progress, tabs and the year chip', (
      tester,
    ) async {
      final container = await open(tester, 'christmas-2026');
      expect(find.text('Christmas'), findsOneWidget);
      expect(find.bySemanticsLabel('Choose year'), findsOneWidget);
      expect(find.text('0 of 6 done'), findsOneWidget);
      expect(find.text('This plan'), findsOneWidget);
      expect(find.text('All Christmas'), findsOneWidget);
      expect(find.text('MOVIES'), findsOneWidget);
      expect(find.text('BOOKS'), findsOneWidget);
      expect(find.text('Die Hard'), findsOneWidget);
      expect(find.textContaining('Rewatch'), findsWidgets);
      expect(find.byKey(const Key('timeline-today')), findsNothing);
      // The "+" button is claimed for the pool.
      expect(
        container.read(fabActionProvider)?.label,
        'Add from All Christmas',
      );
    });

    testWidgets('the check marks the item and the entry done', (tester) async {
      final container = await open(tester, 'christmas-2026');
      await tester.tap(check('Klaus'));
      await tester.pumpAndSettle();
      final library = repo(container).current!;
      final plan = library.planById('christmas-2026')!;
      expect(plan.itemFor('movies/klaus-2019')!.done, isTrue);
      expect(library.entryById('movies/klaus-2019')!.status, EntryStatus.done);
      expect(find.text('1 of 6 done'), findsOneWidget);
      await tester.tap(check('Klaus'));
      await tester.pumpAndSettle();
      expect(
        repo(container).current!
            .planById('christmas-2026')!
            .itemFor('movies/klaus-2019')!
            .done,
        isFalse,
      );
    });

    testWidgets('a row opens the entry in the plan (S8)', (tester) async {
      await open(tester, 'christmas-2026');
      await tester.tap(find.text('Die Hard'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanEntrySheet), findsOneWidget);
      expect(find.text('Mark as done'), findsOneWidget);
      expect(find.text('When'), findsNothing); // No timeline on this plan.
    });
  });

  group('timeline (S2)', () {
    testWidgets('dated groups with the rail and today, then Whenever', (
      tester,
    ) async {
      await open(tester, 'halloween-2026');
      expect(find.text('Halloween'), findsOneWidget);
      expect(find.text('One day'), findsWidgets);
      expect(find.text('MOVIE'), findsWidgets);
      expect(find.text('Sat Oct 3'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Whenever'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No date'), findsOneWidget);
      expect(find.text('Hereditary'), findsOneWidget);
      // The fixture's October 2026 periods against today's date.
      final today = DateTime.now();
      final inRange =
          DateTime(2026, 10, 10).isBefore(today) &&
          today.isBefore(DateTime(2026, 10, 18));
      expect(
        find.byKey(const Key('timeline-today')),
        inRange ? findsOneWidget : findsNothing,
      );
    });

    testWidgets('the entry sheet has a When row that opens the picker', (
      tester,
    ) async {
      final container = await open(tester, 'halloween-2026');
      await tester.scrollUntilVisible(
        find.text('Hereditary'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Hereditary'));
      await tester.pumpAndSettle();
      expect(find.text('When'), findsOneWidget);
      await tester.tap(find.text('When'));
      await tester.pumpAndSettle();
      expect(find.text('Selected'), findsOneWidget);
      await tester.tap(find.widgetWithText(PillChip, 'No date'));
      await tester.pump();
      expect(find.text('No date (Whenever)'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Sat Oct 17'));
      await tester.tap(find.bySemanticsLabel('Sat Oct 31'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(WhenSheet),
          matching: find.text('Oct 17–31'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();
      final item = repo(container).current!
          .planById('halloween-2026')!
          .itemFor('movies/hereditary-2018')!;
      expect(item.when!.from, DateTime(2026, 10, 17));
      expect(item.when!.to, DateTime(2026, 10, 31));
      expect(
        find.descendant(
          of: find.byType(PlanEntrySheet),
          matching: find.text('Oct 17–31'),
        ),
        findsOneWidget,
      );
    });
  });

  group('seasonal theme (S11, S12)', () {
    testWidgets('Halloween: orange accent, strip, web, icon and marker', (
      tester,
    ) async {
      await open(tester, 'halloween-2026');
      final context = tester.element(find.text('Halloween'));
      expect(
        Theme.of(context).colorScheme.primaryContainer,
        SeasonalAccents.halloween,
      );
      expect(find.byType(SeasonalArtView), findsNWidgets(4));
    });

    testWidgets('Christmas: green accent, strip, icon and marker', (
      tester,
    ) async {
      await open(tester, 'christmas-2026');
      final xmas = tester.element(find.text('Christmas'));
      expect(
        Theme.of(xmas).colorScheme.primaryContainer,
        SeasonalAccents.christmas,
      );
      expect(find.byType(SeasonalArtView), findsNWidgets(3));
    });

    testWidgets('with the theme off the plan looks like any other', (
      tester,
    ) async {
      final fixture = loadFixture();
      await pumpApp(
        tester,
        const PlanScreen(planId: 'halloween-2026', tab: ShellTab.plans),
        library: fixture.copyWith(
          plans: [
            for (final p in fixture.plans)
              p.id == 'halloween-2026' ? p.copyWith(seasonalTheme: false) : p,
          ],
        ),
      );
      expect(find.byType(SeasonalArtView), findsNothing);
      final context = tester.element(find.text('Halloween'));
      expect(
        Theme.of(context).colorScheme.primaryContainer,
        Accents.defaultAccent.fill,
      );
    });
  });

  group('pool (S4)', () {
    testWidgets('lists everything with the tag, adds and removes', (
      tester,
    ) async {
      final container = await open(tester, 'christmas-2026');
      await tester.tap(find.text('All Christmas'));
      await tester.pumpAndSettle();
      expect(container.read(fabActionProvider)?.label, 'New Christmas entry');
      expect(find.text('0 of 6 done'), findsNothing);
      expect(find.text('The Nightmare Before Christmas'), findsOneWidget);
      expect(find.textContaining('only in Christmas'), findsWidgets);
      expect(
        find.bySemanticsLabel('Add to plan: The Nightmare Before Christmas'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Remove from plan: Die Hard'),
        findsOneWidget,
      );
      expect(find.text('In 2026'), findsWidgets);

      await tester.tap(
        find.bySemanticsLabel('Add to plan: The Nightmare Before Christmas'),
      );
      await tester.pumpAndSettle();
      var plan = repo(container).current!.planById('christmas-2026')!;
      expect(
        plan.itemFor('movies/the-nightmare-before-christmas-1993')!.repeat,
        isTrue,
      );
      await tester.tap(find.bySemanticsLabel('Remove from plan: Die Hard'));
      await tester.pumpAndSettle();
      plan = repo(container).current!.planById('christmas-2026')!;
      expect(plan.itemFor('movies/die-hard-1988'), isNull);
    });

    testWidgets('the row actions edit, untag or delete the entry', (
      tester,
    ) async {
      final container = await open(tester, 'christmas-2026');
      await tester.tap(find.text('All Christmas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More actions: Klaus'));
      await tester.pumpAndSettle();
      expect(find.text('Edit entry'), findsOneWidget);
      expect(find.text('Remove #christmas'), findsOneWidget);
      await tester.tap(find.text('Remove #christmas'));
      await tester.pumpAndSettle();
      expect(
        repo(container).current!.entryById('movies/klaus-2019')!.tags,
        isNot(contains('christmas')),
      );
      expect(find.text('Klaus'), findsNothing);

      await tester.tap(find.byTooltip('More actions: Die Hard'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Die Hard?'), findsOneWidget);
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('Delete')),
      );
      await tester.pumpAndSettle();
      expect(
        repo(container).current!.entryById('movies/die-hard-1988'),
        isNull,
      );
    });
  });

  group('header menus', () {
    testWidgets('the year chip switches to a sibling plan', (tester) async {
      await open(tester, 'halloween-2026');
      await tester.tap(find.bySemanticsLabel('Choose year'));
      await tester.pumpAndSettle();
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('New year…'), findsOneWidget);
      await tester.tap(find.text('2025'));
      await tester.pumpAndSettle();
      expect(find.text('3 of 3 done'), findsOneWidget);
      expect(find.text('Hill House'), findsNothing);
      expect(find.text('The Haunting of Hill House'), findsOneWidget);
    });

    testWidgets('"New year…" opens a copy for the next year', (tester) async {
      final container = await open(tester, 'halloween-2026');
      await tester.tap(find.bySemanticsLabel('Choose year'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New year…'));
      await tester.pumpAndSettle();
      expect(find.text('New plan'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Halloween'), findsWidgets);
      expect(find.widgetWithText(TextField, '2027'), findsWidgets);
      expect(find.text('Copy from Halloween 2026'), findsOneWidget);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      final plan = repo(container).current!.planById('halloween-2027')!;
      expect(plan.items.length, 6); // The unfinished ones, without dates.
      expect(plan.items.every((i) => !i.done && i.when == null), isTrue);
      expect(plan.timeline, isTrue);
      expect(find.text('0 of 6 done'), findsOneWidget); // Switched to it.
    });

    testWidgets('the plan menu deletes the plan (D3, D5)', (tester) async {
      final container = await open(tester, 'christmas-2026');
      await tester.tap(find.byTooltip('Plan options'));
      await tester.pumpAndSettle();
      expect(find.text('Edit plan'), findsOneWidget);
      expect(find.text('Copy to a new year'), findsOneWidget);
      await tester.tap(find.text('Delete plan'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Christmas 2026?'), findsOneWidget);
      expect(find.text('Its 6 entries stay in your library.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo(container).current!.planById('christmas-2026'), isNotNull);
      await tester.tap(find.byTooltip('Plan options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete plan'));
      await tester.pumpAndSettle();
      expect(repo(container).current!.planById('christmas-2026'), isNull);
      expect(find.byType(PlanScreen), findsNothing);
    });
  });
}
