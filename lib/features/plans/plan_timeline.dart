import '../../data/models/plan.dart';
import '../../data/models/plan_item.dart';
import 'plan_dates.dart';

/// Where a timeline group sits relative to today (S2).
enum TimelineState { past, current, future, undated }

/// Items that share the same "When", shown under one heading with a rail
/// on the left. The rail is filled for the past, filled up to today for
/// the current group, and empty for what is still to come.
class TimelineGroup {
  const TimelineGroup({
    required this.title,
    required this.dates,
    required this.state,
    required this.items,
    this.todayFraction,
  });

  /// "Now", "Later", "Earlier", "Sat Oct 17" or "Whenever".
  final String title;

  /// "Oct 19–31", "One day", "No date".
  final String dates;
  final TimelineState state;
  final List<PlanItem> items;

  /// For the current group: how far today is through the period, 0 to 1.
  final double? todayFraction;
}

/// Groups a plan's items for the timeline: dated items in date order,
/// then the undated ones under "Whenever". Items with the same period
/// share a group.
List<TimelineGroup> timelineGroups(Plan plan, {DateTime? today}) {
  final now = dateOnly(today ?? DateTime.now());
  final dated = plan.items.where((i) => i.when != null).toList();
  final undated = plan.items.where((i) => i.when == null).toList();
  // Stable: ties keep the plan's order.
  final indexed = dated.indexed.toList()
    ..sort((a, b) {
      final wa = a.$2.when!, wb = b.$2.when!;
      final c = wa.from.compareTo(wb.from);
      if (c != 0) return c;
      final d = wa.to.compareTo(wb.to);
      return d != 0 ? d : a.$1.compareTo(b.$1);
    });

  final groups = <TimelineGroup>[];
  PlanWhen? open;
  var items = <PlanItem>[];
  void flush() {
    if (open == null) return;
    groups.add(_group(open, items, now, plan.year));
  }

  for (final (_, item) in indexed) {
    final when = item.when!;
    if (open == null || open != when) {
      flush();
      open = when;
      items = [];
    }
    items.add(item);
  }
  flush();
  if (undated.isNotEmpty) {
    groups.add(
      TimelineGroup(
        title: 'Whenever',
        dates: 'No date',
        state: TimelineState.undated,
        items: undated,
      ),
    );
  }
  return groups;
}

TimelineGroup _group(
  PlanWhen when,
  List<PlanItem> items,
  DateTime now,
  int? year,
) {
  final from = dateOnly(when.from), to = dateOnly(when.to);
  final TimelineState state;
  double? fraction;
  if (now.isAfter(to)) {
    state = TimelineState.past;
  } else if (now.isBefore(from)) {
    state = TimelineState.future;
  } else {
    state = TimelineState.current;
    final length = to.difference(from).inDays + 1;
    fraction = (now.difference(from).inDays + 0.5) / length;
  }
  final String title;
  if (when.isSingleDay) {
    title = formatWeekdayDay(from);
  } else {
    title = switch (state) {
      TimelineState.past => 'Earlier',
      TimelineState.current => 'Now',
      _ => 'Later',
    };
  }
  return TimelineGroup(
    title: title,
    dates: when.isSingleDay ? 'One day' : formatWhen(when, year: year),
    state: state,
    items: items,
    todayFraction: fraction,
  );
}
