import '../../data/models/plan_item.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "Oct 17".
String formatMonthDay(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// "Sat Oct 17".
String formatWeekdayDay(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${formatMonthDay(d)}';

/// "Oct 19–31", "Oct 28 – Nov 2", or "Sat Oct 17" for one day. Years are
/// added only when the period is not in [year].
String formatWhen(PlanWhen when, {int? year}) {
  final from = when.from, to = when.to;
  String withYear(DateTime d, String text) =>
      year != null && d.year != year ? '$text ${d.year}' : text;
  if (when.isSingleDay) return withYear(from, formatWeekdayDay(from));
  if (from.month == to.month && from.year == to.year) {
    return withYear(from, '${formatMonthDay(from)}–${to.day}');
  }
  return '${withYear(from, formatMonthDay(from))} – '
      '${withYear(to, formatMonthDay(to))}';
}

/// Midnight of [d], so date arithmetic ignores the time of day.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
