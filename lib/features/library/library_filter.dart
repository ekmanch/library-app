import 'package:flutter/foundation.dart';

import '../../data/models/entry.dart';
import '../../data/models/entry_status.dart';
import '../../data/models/media_type.dart';
import '../../widgets/labels.dart';

/// A release decade in the filter sheet: "Older" for everything before
/// [oldestNamed], then one chip per decade. The chips come from the library:
/// the row runs from the earliest to the latest decade that has an entry,
/// with the decades in between filled in so there is no gap, and "Older"
/// only when something is older than 1960.
@immutable
class Decade implements Comparable<Decade> {
  const Decade(int this.start) : assert(start % 10 == 0);
  const Decade.older() : start = null;

  /// The first year of the decade, null for "Older".
  final int? start;

  static const oldestNamed = 1960;

  bool get isOlder => start == null;

  String get label => isOlder ? 'Older' : '${start}s';

  static Decade? of(int? year) {
    if (year == null) return null;
    if (year < oldestNamed) return const Decade.older();
    return Decade(year ~/ 10 * 10);
  }

  /// The chips for a library whose entries have [years] (nulls ignored).
  static List<Decade> optionsFor(Iterable<int?> years) {
    var older = false;
    int? first;
    int? last;
    for (final year in years) {
      if (year == null) continue;
      if (year < oldestNamed) {
        older = true;
        continue;
      }
      final start = year ~/ 10 * 10;
      if (first == null || start < first) first = start;
      if (last == null || start > last) last = start;
    }
    return [
      if (older) const Decade.older(),
      if (first != null)
        for (var y = first; y <= last!; y += 10) Decade(y),
    ];
  }

  @override
  int compareTo(Decade other) => (start ?? 0).compareTo(other.start ?? 0);

  @override
  bool operator ==(Object other) => other is Decade && other.start == start;

  @override
  int get hashCode => start.hashCode;

  @override
  String toString() => label;
}

/// The filter sheet's choices (A2). Within type, status and released any
/// choice matches; every chosen tag must be on the entry. Seasonal-only
/// entries are hidden unless [includeSeasonalOnly] is on.
@immutable
class LibraryFilter {
  const LibraryFilter({
    this.types = const {},
    this.statuses = const {},
    this.decades = const {},
    this.tags = const {},
    this.includeSeasonalOnly = false,
  });

  final Set<MediaType> types;
  final Set<EntryStatus> statuses;
  final Set<Decade> decades;
  final Set<String> tags;
  final bool includeSeasonalOnly;

  static const none = LibraryFilter();

  /// True when nothing is chosen, so the home shows the plain library.
  bool get isEmpty =>
      types.isEmpty &&
      statuses.isEmpty &&
      decades.isEmpty &&
      tags.isEmpty &&
      !includeSeasonalOnly;

  bool get isActive => !isEmpty;

  /// Spells out a filter that matches nothing (A10): "No books are both
  /// in progress and tagged #christmas. Remove a filter to see more."
  String get noMatchesText {
    String join(List<String> parts, String word) => parts.length < 2
        ? parts.join()
        : '${parts.sublist(0, parts.length - 1).join(', ')} $word ${parts.last}';
    String plural(MediaType t) => switch (t) {
      MediaType.music => 'albums or songs',
      _ => t.label.toLowerCase(),
    };
    final subject = types.isEmpty
        ? 'entries'
        : join([
            for (final t in MediaType.values)
              if (types.contains(t)) plural(t),
          ], 'or');
    final conditions = [
      if (statuses.isNotEmpty)
        join([
          for (final s in EntryStatus.values)
            if (statuses.contains(s))
              switch (s) {
                EntryStatus.want => 'wanted',
                EntryStatus.inProgress => 'in progress',
                EntryStatus.done => 'done',
                EntryStatus.dnf => 'not finished',
              },
        ], 'or'),
      if (decades.isNotEmpty)
        join([
          for (final d in decades.toList()..sort())
            d.isOlder
                ? 'from before ${Decade.oldestNamed}'
                : 'from the ${d.label}',
        ], 'or'),
      if (tags.isNotEmpty)
        'tagged ${join([for (final tag in tags) '#$tag'], 'and')}',
    ];
    const tail = 'Remove a filter to see more.';
    if (conditions.isEmpty) return tail;
    final what = switch (conditions.length) {
      1 => conditions.single,
      2 => 'both ${conditions[0]} and ${conditions[1]}',
      _ => join(conditions, 'and'),
    };
    return 'No $subject are $what. $tail';
  }

  /// The type when a single type is the only filter. That is not a results
  /// screen: the home shows that type's view instead (the L6 note).
  MediaType? get onlyType =>
      types.length == 1 &&
          statuses.isEmpty &&
          decades.isEmpty &&
          tags.isEmpty &&
          !includeSeasonalOnly
      ? types.single
      : null;

  /// Number shown on the filter button badge.
  int get count =>
      types.length +
      statuses.length +
      decades.length +
      tags.length +
      (includeSeasonalOnly ? 1 : 0);

  bool matches(Entry entry) {
    if (entry.seasonalOnly && !includeSeasonalOnly) return false;
    if (types.isNotEmpty && !types.contains(entry.type)) return false;
    if (statuses.isNotEmpty && !statuses.contains(entry.status)) return false;
    if (decades.isNotEmpty && !decades.contains(Decade.of(entry.year))) {
      return false;
    }
    return tags.every(entry.tags.contains);
  }

  List<Entry> apply(Iterable<Entry> entries) => entries.where(matches).toList();

  LibraryFilter copyWith({
    Set<MediaType>? types,
    Set<EntryStatus>? statuses,
    Set<Decade>? decades,
    Set<String>? tags,
    bool? includeSeasonalOnly,
  }) => LibraryFilter(
    types: types ?? this.types,
    statuses: statuses ?? this.statuses,
    decades: decades ?? this.decades,
    tags: tags ?? this.tags,
    includeSeasonalOnly: includeSeasonalOnly ?? this.includeSeasonalOnly,
  );

  static Set<T> _toggled<T>(Set<T> set, T value) =>
      set.contains(value) ? (set.toSet()..remove(value)) : {...set, value};

  LibraryFilter toggleType(MediaType t) => copyWith(types: _toggled(types, t));
  LibraryFilter toggleStatus(EntryStatus s) =>
      copyWith(statuses: _toggled(statuses, s));
  LibraryFilter toggleDecade(Decade d) =>
      copyWith(decades: _toggled(decades, d));
  LibraryFilter toggleTag(String tag) => copyWith(tags: _toggled(tags, tag));

  /// The removable chips of A3, in sheet order.
  List<ActiveFilterChip> get chips => [
    for (final t in MediaType.values)
      if (types.contains(t)) ActiveFilterChip(t.label, (f) => f.toggleType(t)),
    for (final s in EntryStatus.values)
      if (statuses.contains(s))
        ActiveFilterChip(s.label, (f) => f.toggleStatus(s)),
    for (final d in decades.toList()..sort())
      ActiveFilterChip(d.label, (f) => f.toggleDecade(d)),
    for (final tag in tags) ActiveFilterChip('#$tag', (f) => f.toggleTag(tag)),
    if (includeSeasonalOnly)
      ActiveFilterChip(
        'Seasonal-only included',
        (f) => f.copyWith(includeSeasonalOnly: false),
      ),
  ];

  @override
  bool operator ==(Object other) =>
      other is LibraryFilter &&
      setEquals(other.types, types) &&
      setEquals(other.statuses, statuses) &&
      setEquals(other.decades, decades) &&
      setEquals(other.tags, tags) &&
      other.includeSeasonalOnly == includeSeasonalOnly;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(types),
    Object.hashAllUnordered(statuses),
    Object.hashAllUnordered(decades),
    Object.hashAllUnordered(tags),
    includeSeasonalOnly,
  );
}

/// One active filter and how to remove it.
class ActiveFilterChip {
  const ActiveFilterChip(this.label, this.remove);
  final String label;
  final LibraryFilter Function(LibraryFilter) remove;
}
