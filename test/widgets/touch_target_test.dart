import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/widgets/chips.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('a 40 dp chip looks 40 dp but answers taps 48 dp tall', (
    tester,
  ) async {
    var taps = 0;
    await pumpThemed(
      tester,
      Center(
        child: PillChip(
          label: 'PC',
          height: 40,
          selected: false,
          onTap: () => taps++,
        ),
      ),
    );
    final box = tester.getRect(find.byType(PillChip));
    expect(box.height, 40);
    // 3 dp above the drawn chip is still the chip.
    await tester.tapAt(Offset(box.center.dx, box.top - 3));
    expect(taps, 1);
    await tester.tapAt(Offset(box.center.dx, box.top - 6));
    expect(taps, 1);
    final handle = tester.ensureSemantics();
    final rect = tester.getSemantics(find.byType(PillChip)).rect;
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.width, greaterThanOrEqualTo(48));
    handle.dispose();
  });
}
