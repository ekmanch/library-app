import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/released.dart';
import 'package:library_app/features/entry/released_sheet.dart';
import 'package:library_app/widgets/wheel_picker.dart';

import '../../helpers/pump.dart';

void main() {
  final today = DateTime(2026, 10, 14);
  const row = WheelColumn.itemExtent;

  /// Opens the sheet on [initial] and collects what it hands back.
  Future<List<Released?>> open(WidgetTester tester, Released? initial) async {
    final changes = <Released?>[];
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showReleasedSheet(
            context,
            initial: initial,
            onChanged: changes.add,
            today: today,
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return changes;
  }

  /// A slow drag, so the wheel settles on the row [rows] away instead of
  /// flinging past it.
  Future<void> turn(WidgetTester tester, Finder from, int rows) async {
    await tester.timedDrag(
      from,
      Offset(0, -row * rows),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the value and applies every change at once', (
    tester,
  ) async {
    final changes = await open(tester, const Released(2013, 6, 14));
    expect(find.text('Released'), findsOneWidget);
    expect(find.text('June 14, 2013'), findsOneWidget);
    expect(find.text('2013'), findsOneWidget);
    expect(find.text('Jun'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text(ReleasedSheet.hint), findsOneWidget);

    // Tapping a neighbor scrolls to it.
    await tester.tap(find.text('May'));
    await tester.pumpAndSettle();
    expect(find.text('May 14, 2013'), findsOneWidget);
    expect(changes.last, const Released(2013, 5, 14));

    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('Released'), findsNothing);
  });

  testWidgets('"—" on the month drops the day and empties the day wheel', (
    tester,
  ) async {
    final changes = await open(tester, const Released(2013, 6, 14));
    await turn(tester, find.text('Jun'), -6);
    expect(find.text('Year only: 2013'), findsOneWidget);
    expect(changes.last, const Released(2013));
    // Only "—" is left on the day wheel: one on the month, one on the day.
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('14'), findsNothing);
  });

  testWidgets('a day the new month lacks becomes its last day', (tester) async {
    final changes = await open(tester, const Released(2024, 1, 31));
    await turn(tester, find.text('Jan'), 1);
    expect(find.text('February 29, 2024'), findsOneWidget);
    expect(changes.last, const Released(2024, 2, 29));
  });

  testWidgets('tapping the chosen year turns it into a numeric field', (
    tester,
  ) async {
    final changes = await open(tester, const Released(2013));
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('2013'));
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, '2013');

    await tester.enterText(field, '10');
    await tester.pump();
    expect(changes, isEmpty);
    await tester.enterText(field, '1066');
    await tester.pump();
    expect(find.text('Year only: 1066'), findsOneWidget);
    expect(changes.last, const Released(1066));
  });

  testWidgets('the keyboard pushes the typed year into view', (tester) async {
    await open(tester, const Released(2013));
    await tester.tap(find.text('2013'));
    await tester.pumpAndSettle();
    // A keyboard two fifths of the screen tall, as on the phone. The view
    // insets are in physical pixels.
    final screen = tester.view.physicalSize.height;
    tester.view.viewInsets = FakeViewPadding(bottom: screen * 0.4);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    final visibleBottom = screen * 0.6 / tester.view.devicePixelRatio;
    expect(tester.getBottomLeft(field).dy, lessThanOrEqualTo(visibleBottom));
    expect(tester.getTopLeft(field).dy, greaterThanOrEqualTo(0));
    expect(find.text('Year only: 2013'), findsOneWidget);
  });

  testWidgets('with nothing set it opens on this year and stays unset', (
    tester,
  ) async {
    final changes = await open(tester, null);
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('the wheel runs from 1800 to five years ahead', (tester) async {
    final changes = await open(tester, const Released(2031));
    expect(find.text('2031'), findsOneWidget);
    expect(find.text('2032'), findsNothing);
    await turn(tester, find.text('2031'), 1);
    expect(changes, isEmpty);
    expect(find.text('Year only: 2031'), findsOneWidget);
  });

  testWidgets('Clear empties the field and goes away', (tester) async {
    final changes = await open(tester, const Released(2013, 6, 14));
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(changes.last, isNull);
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
    expect(find.text('2026'), findsOneWidget);
  });
}
