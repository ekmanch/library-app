import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/features/plans/plan_form_screen.dart';
import 'package:library_app/widgets/chips.dart';

import '../../helpers/pump_app.dart';

void main() {
  FixtureLibraryRepository repo(ProviderContainer c) =>
      c.read(libraryRepositoryProvider) as FixtureLibraryRepository;

  Finder hinted(String hint) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == hint,
  );

  testWidgets('S10: a free-form plan with the Settings defaults', (
    tester,
  ) async {
    final container = await pumpApp(tester, const PlanFormScreen.create());
    expect(find.text('New plan'), findsOneWidget);
    expect(find.text('Seasonal theme'), findsNothing);
    expect(find.text('Start with'), findsOneWidget);
    expect(find.text('A plain checklist without dates.'), findsOneWidget);
    final create = find.widgetWithText(FilledButton, 'Create');
    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    await tester.enterText(hinted('Summer vacation'), 'Summer vacation');
    await tester.pump();
    await tester.tap(create);
    await tester.pumpAndSettle();
    final plan = repo(container).current!.planById('summer-vacation')!;
    expect(plan.year, isNull);
    expect(plan.tags, isEmpty);
    expect(plan.timeline, isFalse);
    expect(plan.seasonalTheme, isTrue);
    expect(plan.items, isEmpty);
  });

  testWidgets('linked tags reveal the seasonal switch', (tester) async {
    final container = await pumpApp(tester, const PlanFormScreen.create());
    await tester.tap(find.byType(Switch)); // Timeline on.
    await tester.pump();
    expect(
      find.text('Entries sit on a timeline, each with a day or a period.'),
      findsOneWidget,
    );
    await tester.enterText(hinted('Summer vacation'), 'Spooky');
    await tester.enterText(hinted('2027'), '2027');
    await tester.tap(find.text('Choose from your tags'));
    await tester.pumpAndSettle();
    expect(find.text('Linked hashtags'), findsOneWidget);
    await tester.enterText(hinted('Search tags'), 'hallo');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PillChip, '#christmas'), findsNothing);
    await tester.tap(find.widgetWithText(PillChip, '#halloween'));
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('#halloween'), findsOneWidget);
    expect(find.text('Seasonal theme'), findsOneWidget);
    expect(
      find.text('Halloween artwork and an orange accent inside this plan.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
    final plan = repo(container).current!.planById('spooky-2027')!;
    expect(plan.tags, ['halloween']);
    expect(plan.year, 2027);
    expect(plan.timeline, isTrue);
  });

  testWidgets('a bad year blocks Create', (tester) async {
    await pumpApp(tester, const PlanFormScreen.create());
    await tester.enterText(hinted('Summer vacation'), 'X');
    await tester.enterText(hinted('2027'), '27');
    await tester.pump();
    expect(find.text('A year like 2027'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Create'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('"Copy a plan" picks a source and copies its open items', (
    tester,
  ) async {
    final container = await pumpApp(tester, const PlanFormScreen.create());
    await tester.tap(find.text('Copy a plan'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a plan to copy'), findsOneWidget);
    await tester.tap(find.text('Choose a plan to copy'));
    await tester.pumpAndSettle();
    expect(find.text('Copy from'), findsOneWidget);
    await tester.tap(find.text('Christmas 2026'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Christmas'), findsWidgets);
    expect(find.widgetWithText(TextField, '2027'), findsWidgets);
    expect(find.text('#christmas'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();
    final plan = repo(container).current!.planById('christmas-2027')!;
    expect(plan.items.length, 6);
    expect(plan.tags, ['christmas']);
  });

  testWidgets('S9: edit saves, and Delete plan removes it', (tester) async {
    final fixture = loadFixture();
    final plan = fixture.planById('christmas-2026')!;
    final container = await pumpApp(tester, PlanFormScreen.edit(plan));
    expect(find.text('Edit plan'), findsOneWidget);
    expect(find.text('Start with'), findsNothing);
    expect(find.widgetWithText(TextField, 'Christmas'), findsWidgets);
    await tester.enterText(
      find.widgetWithText(TextField, 'Christmas').first,
      'Yule',
    );
    await tester.scrollUntilVisible(
      find.text('Timeline'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(Switch).last); // Timeline on.
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = repo(container).current!.planById('christmas-2026')!;
    expect(saved.name, 'Yule');
    expect(saved.timeline, isTrue);
    expect(saved.items.length, 6);
  });

  testWidgets('S9: Delete plan asks and removes it', (tester) async {
    final plan = loadFixture().planById('christmas-2026')!;
    final container = await pumpApp(tester, PlanFormScreen.edit(plan));
    await tester.scrollUntilVisible(
      find.text('Delete plan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete plan'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Christmas 2026?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete plan'));
    await tester.pumpAndSettle();
    expect(repo(container).current!.planById('christmas-2026'), isNull);
    expect(find.byType(PlanFormScreen), findsNothing);
  });
}
