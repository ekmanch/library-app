import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/date_only_converter.dart';

void main() {
  const converter = DateOnlyConverter();

  test('reads and writes yyyy-MM-dd', () {
    expect(converter.fromJson('2026-10-01'), DateTime(2026, 10, 1));
    expect(converter.toJson(DateTime(2026, 1, 9)), '2026-01-09');
    expect(converter.toJson(converter.fromJson('2026-10-01')), '2026-10-01');
  });

  test('drops any time part when writing', () {
    expect(converter.toJson(DateTime(2026, 10, 1, 13, 45)), '2026-10-01');
  });

  test('rejects timestamps and other shapes', () {
    expect(
      () => converter.fromJson('2026-10-01T00:00:00'),
      throwsFormatException,
    );
    expect(() => converter.fromJson('2026-10'), throwsFormatException);
  });
}
