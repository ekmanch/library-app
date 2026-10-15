import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/widgets/search_field.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('one outline, no inner border, clear button once typed', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await pumpThemed(
      tester,
      SearchField(
        controller: controller,
        hintText: 'Search titles and tags',
        onChanged: changes.add,
      ),
    );
    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.border, InputBorder.none);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
    expect(decoration.filled, isFalse);
    expect(find.byTooltip('Clear'), findsNothing);
    expect(tester.getSize(find.byType(SearchField)).height, 52);

    await tester.enterText(find.byType(TextField), 'mi');
    await tester.pump();
    expect(find.byTooltip('Clear'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changes, ['mi', '']);
  });

  testWidgets('the text sits at the vertical center of the box, one line', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      const Padding(
        padding: EdgeInsets.all(20),
        child: SearchField(hintText: 'Search'),
      ),
    );
    await tester.enterText(find.byType(TextField), 'fkfk');
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, 1);
    final box = tester.getRect(find.byType(SearchField));
    final text = tester.getRect(find.byType(EditableText));
    expect(text.center.dy, closeTo(box.center.dy, 1));
    expect(box.height, 52);

    // A tap on the box outside the field focuses it.
    await tester.tap(find.byType(SearchField), warnIfMissed: false);
    await tester.pump();
    expect(field.focusNode!.hasFocus, isTrue);
  });
}
