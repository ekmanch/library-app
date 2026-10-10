import 'package:freezed_annotation/freezed_annotation.dart'
    show JsonConverter, immutable;

/// A release date with flexible precision: a year, a year and month, or a
/// full date. Stored as text: "1999", "2026-12" or "2026-12-25".
///
/// A partial date counts as released only once its period has ended, so
/// "2027" is "Not released yet" until 2028-01-01. Otherwise a game "coming
/// in 2027" would look released in January.
@immutable
class Released {
  const Released(this.year, [this.month, this.day])
    : assert(month == null || (month >= 1 && month <= 12)),
      assert(day == null || (day >= 1 && day <= 31)),
      assert(day == null || month != null, 'a day needs a month');

  final int year;
  final int? month;
  final int? day;

  static final _pattern = RegExp(r'^(\d{4})(?:-(\d{2})(?:-(\d{2}))?)?$');

  /// Parses "1999", "2026-12" or "2026-12-25".
  static Released parse(String text) {
    final released = tryParse(text);
    if (released == null) {
      throw FormatException('Not a release date: "$text"');
    }
    return released;
  }

  static Released? tryParse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = match.group(2) == null ? null : int.parse(match.group(2)!);
    final day = match.group(3) == null ? null : int.parse(match.group(3)!);
    if (month != null && (month < 1 || month > 12)) return null;
    if (day != null) {
      final lastDay = DateTime(year, month! + 1, 0).day;
      if (day < 1 || day > lastDay) return null;
    }
    return Released(year, month, day);
  }

  /// The first day on which the title counts as released.
  DateTime get availableFrom {
    if (day != null) return DateTime(year, month!, day!);
    if (month != null) return DateTime(year, month! + 1, 1);
    return DateTime(year + 1, 1, 1);
  }

  bool isReleasedOn(DateTime today) {
    final date = DateTime(today.year, today.month, today.day);
    return !date.isBefore(availableFrom);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  String toString() {
    final buffer = StringBuffer(year.toString().padLeft(4, '0'));
    if (month != null) buffer.write('-${_two(month!)}');
    if (day != null) buffer.write('-${_two(day!)}');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is Released &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

class ReleasedConverter implements JsonConverter<Released, String> {
  const ReleasedConverter();

  @override
  Released fromJson(String json) => Released.parse(json);

  @override
  String toJson(Released object) => object.toString();
}
