import 'package:json_annotation/json_annotation.dart';

/// Converts a calendar date to and from "2026-10-01". The time part is
/// always midnight, local time.
class DateOnlyConverter implements JsonConverter<DateTime, String> {
  const DateOnlyConverter();

  static final _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  @override
  DateTime fromJson(String json) {
    final match = _pattern.firstMatch(json);
    if (match == null) throw FormatException('Not a date: "$json"');
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  @override
  String toJson(DateTime object) => formatDate(object);

  static String formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-'
        '${two(date.month)}-${two(date.day)}';
  }
}
