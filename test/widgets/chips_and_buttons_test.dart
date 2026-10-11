import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/theme/app_theme.dart';
import 'package:library_app/widgets/app_buttons.dart';
import 'package:library_app/widgets/chips.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('PillChip is 44 px tall, reports taps and selection', (
    tester,
  ) async {
    var taps = 0;
    await pumpThemed(
      tester,
      Center(
        child: PillChip(
          label: 'Movies',
          selected: true,
          dotColor: Colors.amber,
          onTap: () => taps++,
        ),
      ),
    );
    expect(tester.getSize(find.byType(PillChip)).height, 44);
    expect(isSelected(tester, find.text('Movies')), isTrue);
    await tester.tap(find.text('Movies'));
    expect(taps, 1);
  });

  testWidgets('TagChip shows a hash before the name', (tester) async {
    await pumpThemed(tester, const TagChip('horror'));
    expect(find.text('#horror'), findsOneWidget);
  });

  testWidgets('destructive buttons use red text on the grey outline', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      Column(
        children: [
          AppButton(
            label: 'Delete',
            kind: AppButtonKind.destructive,
            onPressed: () {},
          ),
          AppButton(
            label: 'Cancel',
            kind: AppButtonKind.outline,
            onPressed: () {},
          ),
          AppButton(label: 'Save', onPressed: () {}),
        ],
      ),
    );
    final context = tester.element(find.text('Delete'));
    final colors = LibraryColors.of(context);
    final delete = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Delete'),
    );
    final style = delete.style!;
    // No fill: the grey outline from the theme and red text.
    expect(style.backgroundColor?.resolve({}), isNull);
    expect(style.foregroundColor!.resolve({}), colors.dangerText);
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Save')).height,
      48,
    );
    expect(find.byType(OutlinedButton), findsNWidgets(2));
  });
}
