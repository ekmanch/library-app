import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/features/plans/when_sheet.dart';

void main() {
  // October 2026 starts on a Thursday: the second week row is Oct 5–11.
  final week = [for (var d = 5; d <= 11; d++) DateTime(2026, 10, d)];
  DateTime oct(int d) => DateTime(2026, 10, d);

  test('the band runs from the start dot to the end dot', () {
    expect(bandSpan(week, oct(6), oct(9)), (1.5, 4.5));
  });

  test('a row the range carries on from or into runs to the edge', () {
    expect(bandSpan(week, oct(8), oct(20)), (3.5, 7.0));
    expect(bandSpan(week, oct(1), oct(7)), (0.0, 2.5));
    expect(bandSpan(week, oct(1), oct(20)), (0.0, 7.0));
  });

  test('no band for one day, or a row outside the range', () {
    expect(bandSpan(week, oct(6), oct(6)), isNull);
    expect(bandSpan(week, oct(19), oct(22)), isNull);
    expect(bandSpan(week, null, null), isNull);
  });

  test('blanks in the first row do not stop the band', () {
    final first = <DateTime?>[null, null, null, oct(1), oct(2), oct(3), oct(4)];
    expect(bandSpan(first, oct(2), oct(10)), (4.5, 7.0));
  });
}
