import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/widgets/segmented_control.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('reports the tapped segment and marks the selected one', (
    tester,
  ) async {
    EntryStatus? picked;
    await pumpThemed(
      tester,
      StatusSegmentedControl(
        selected: null,
        includeAll: true,
        onChanged: (value) => picked = value,
      ),
    );
    expect(find.text('All'), findsOneWidget);
    for (final status in EntryStatus.values) {
      expect(
        find.text(
          status == EntryStatus.inProgress
              ? 'In progress'
              : status.name == 'dnf'
              ? 'DNF'
              : status.name[0].toUpperCase() + status.name.substring(1),
        ),
        findsOneWidget,
      );
    }
    expect(isSelected(tester, find.text('All')), isTrue);
    expect(isSelected(tester, find.text('Done')), isFalse);

    await tester.tap(find.text('Done'));
    expect(picked, EntryStatus.done);
  });

  testWidgets('segments are 44 px tall and fill the row evenly', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      SegmentedControl<int>(
        segments: const [SegmentOption(1, 'One'), SegmentOption(2, 'Two')],
        selected: 1,
        onChanged: (_) {},
      ),
    );
    final one = tester.getSize(
      find.ancestor(of: find.text('One'), matching: find.byType(InkWell)).first,
    );
    final two = tester.getSize(
      find.ancestor(of: find.text('Two'), matching: find.byType(InkWell)).first,
    );
    expect(one.height, 44);
    expect(one.width, two.width);
  });

  testWidgets('accent style fills the selected segment with the accent', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      StatusSegmentedControl(
        selected: EntryStatus.want,
        style: SegmentedStyle.accent,
        inset: true,
        onChanged: (_) {},
      ),
    );
    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text('Want'), matching: find.byType(Material))
          .first,
    );
    final scheme = Theme.of(tester.element(find.text('Want'))).colorScheme;
    expect(material.color, scheme.primaryContainer);
  });
}
