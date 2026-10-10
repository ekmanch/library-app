import '../../data/models/entry.dart';
import '../../data/models/entry_status.dart';

/// The sort choices in D1.
enum LibrarySort { newestAdded, titleAz, yearNewest, yearOldest }

extension LibrarySortLabel on LibrarySort {
  String get label => switch (this) {
    LibrarySort.newestAdded => 'Newest added',
    LibrarySort.titleAz => 'Title, A to Z',
    LibrarySort.yearNewest => 'Year, newest first',
    LibrarySort.yearOldest => 'Year, oldest first',
  };
}

int _byTitle(Entry a, Entry b) =>
    a.title.toLowerCase().compareTo(b.title.toLowerCase());

int _byAddedDesc(Entry a, Entry b) {
  final c = b.added.compareTo(a.added);
  return c != 0 ? c : _byTitle(a, b);
}

/// Entries without a year go last in both year orders.
int _byYear(Entry a, Entry b, {required bool newestFirst}) {
  final ya = a.year, yb = b.year;
  if (ya == null && yb == null) return _byTitle(a, b);
  if (ya == null) return 1;
  if (yb == null) return -1;
  final c = newestFirst ? yb.compareTo(ya) : ya.compareTo(yb);
  return c != 0 ? c : _byTitle(a, b);
}

/// A new, sorted list.
List<Entry> sortEntries(Iterable<Entry> entries, LibrarySort sort) {
  final list = entries.toList();
  switch (sort) {
    case LibrarySort.newestAdded:
      list.sort(_byAddedDesc);
    case LibrarySort.titleAz:
      list.sort(_byTitle);
    case LibrarySort.yearNewest:
      list.sort((a, b) => _byYear(a, b, newestFirst: true));
    case LibrarySort.yearOldest:
      list.sort((a, b) => _byYear(a, b, newestFirst: false));
  }
  return list;
}

/// The order on the library home (A1): In progress, then Want, then Done,
/// then DNF; newest added first within each.
List<Entry> homeOrder(Iterable<Entry> entries) {
  int rank(EntryStatus s) => switch (s) {
    EntryStatus.inProgress => 0,
    EntryStatus.want => 1,
    EntryStatus.done => 2,
    EntryStatus.dnf => 3,
  };
  final list = entries.toList();
  list.sort((a, b) {
    final c = rank(a.status).compareTo(rank(b.status));
    return c != 0 ? c : _byAddedDesc(a, b);
  });
  return list;
}
