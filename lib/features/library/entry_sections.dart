import 'dart:ui' show Color;

import '../../data/models/entry.dart';
import '../../data/models/entry_id.dart';
import '../../data/models/media_type.dart';
import '../../widgets/labels.dart';
import 'library_filter.dart';
import 'library_sort.dart';

/// A run of consecutive entries in a sorted list that share a heading:
/// a decade, a month added, or a first letter (A23 to A26).
class EntrySection {
  const EntrySection({
    required this.label,
    required this.railLabel,
    required this.bubbleLabel,
    required this.entries,
    this.uppercaseHeader = true,
    this.color,
    this.dotColor,
  });

  /// The header above the rows: "2020s", "October 2026", "A".
  final String label;

  /// Headers are written in capitals like other section labels, except
  /// decades: "1990S" reads wrong, so they stay "1990s".
  final bool uppercaseHeader;

  /// The header as shown.
  String get headerText => uppercaseHeader ? label.toUpperCase() : label;

  /// Header color; the list's type color when null.
  final Color? color;

  /// When set, the rail shows a dot of this color instead of [railLabel]
  /// (L6: one dot per type in filtered results).
  final Color? dotColor;

  /// The short form on the rail: "20s", "Oct", "A".
  final String railLabel;

  /// The grid's drag label: "2020s", "Oct 2026", "A".
  final String bubbleLabel;
  final List<Entry> entries;
}

const _months = [
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

/// Groups an already sorted list into sections that follow the sort: decades
/// for the year orders (with "Older" before 1960 and a last section for
/// entries without a date), months of the current year and then whole years
/// for newest added, first letters for title order with "#" for digits.
List<EntrySection> sectionEntries(
  List<Entry> sorted,
  LibrarySort sort, {
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final sections = <EntrySection>[];
  EntrySection? open;
  for (final entry in sorted) {
    final key = _keyOf(entry, sort, now);
    if (open == null || open.label != key.label) {
      open = EntrySection(
        label: key.label,
        railLabel: key.railLabel,
        bubbleLabel: key.bubbleLabel,
        entries: [],
        uppercaseHeader: key.uppercaseHeader,
      );
      sections.add(open);
    }
    open.entries.add(entry);
  }
  return sections;
}

EntrySection _keyOf(Entry entry, LibrarySort sort, DateTime now) {
  switch (sort) {
    case LibrarySort.newestAdded:
      final added = entry.added;
      if (added.year == now.year) {
        final month = _months[added.month - 1];
        return EntrySection(
          label: '$month ${added.year}',
          railLabel: month.substring(0, 3),
          bubbleLabel: '${month.substring(0, 3)} ${added.year}',
          entries: const [],
        );
      }
      final year = '${added.year}';
      return EntrySection(
        label: year,
        railLabel: year,
        bubbleLabel: year,
        entries: const [],
      );
    case LibrarySort.yearNewest:
    case LibrarySort.yearOldest:
      final decade = Decade.of(entry.year);
      if (decade == null) {
        return const EntrySection(
          label: 'Not released yet',
          railLabel: 'TBA',
          bubbleLabel: 'Not released yet',
          entries: [],
        );
      }
      return EntrySection(
        label: decade.label,
        railLabel: decade.isOlder
            ? 'Older'
            : '${(decade.start! % 100).toString().padLeft(2, '0')}s',
        bubbleLabel: decade.label,
        entries: const [],
        uppercaseHeader: decade.isOlder,
      );
    case LibrarySort.titleAz:
      final slug = slugify(entry.title);
      final first = slug.isEmpty ? '' : slug[0];
      final letter = RegExp('[a-z]').hasMatch(first)
          ? first.toUpperCase()
          : '#';
      return EntrySection(
        label: letter,
        railLabel: letter,
        bubbleLabel: letter,
        entries: const [],
      );
  }
}

/// A23 to A26: the jump rail (with its section headers) or the grid's
/// fast-scroll thumb appears only when the list is at least three screens
/// tall and has two sections or more.
bool showJumpRail({
  required int sectionCount,
  required double contentHeight,
  required double viewportHeight,
}) => sectionCount >= 2 && contentHeight >= 3 * viewportHeight;

/// Filtered results with several types (A3, L6): one section per type, in
/// type order, each with its color for the header and the rail dot.
List<EntrySection> sectionEntriesByType(
  List<Entry> sorted,
  Color Function(MediaType type) colorOf,
) {
  return [
    for (final type in MediaType.values)
      if (sorted.any((e) => e.type == type))
        EntrySection(
          label: type.label,
          railLabel: type.label,
          bubbleLabel: type.label,
          entries: sorted.where((e) => e.type == type).toList(),
          color: colorOf(type),
          dotColor: colorOf(type),
        ),
  ];
}
