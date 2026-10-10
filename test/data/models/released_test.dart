import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/released.dart';

void main() {
  group('Released.parse', () {
    test('reads the three precisions and writes them back unchanged', () {
      for (final text in ['1999', '2026-12', '2026-12-25']) {
        expect(Released.parse(text).toString(), text);
      }
      expect(Released.parse('2026-12-25'), const Released(2026, 12, 25));
      expect(Released.parse('2026-12'), const Released(2026, 12));
      expect(Released.parse('1999'), const Released(1999));
    });

    test('rejects other shapes', () {
      for (final bad in ['', '99', '2026-1', '2026-13', '2026-02-30', 'soon']) {
        expect(Released.tryParse(bad), isNull, reason: bad);
        expect(() => Released.parse(bad), throwsFormatException, reason: bad);
      }
    });
  });

  group('isReleasedOn', () {
    test('a full date is out on that day', () {
      const r = Released(2026, 12, 25);
      expect(r.isReleasedOn(DateTime(2026, 12, 24)), isFalse);
      expect(r.isReleasedOn(DateTime(2026, 12, 25, 23, 59)), isTrue);
    });

    test('a year-month is out only after the month ends', () {
      const r = Released(2026, 12);
      expect(r.isReleasedOn(DateTime(2026, 12, 1)), isFalse);
      expect(r.isReleasedOn(DateTime(2026, 12, 31)), isFalse);
      expect(r.isReleasedOn(DateTime(2027, 1, 1)), isTrue);
    });

    test('a year is out only after the year ends', () {
      const r = Released(2027);
      expect(r.isReleasedOn(DateTime(2027, 1, 1)), isFalse);
      expect(r.isReleasedOn(DateTime(2027, 11, 30)), isFalse);
      expect(r.isReleasedOn(DateTime(2028, 1, 1)), isTrue);
    });
  });

  test('converter round-trips', () {
    const converter = ReleasedConverter();
    expect(converter.toJson(converter.fromJson('2026-12')), '2026-12');
  });
}
