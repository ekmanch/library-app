import '../data/models/entry.dart';
import '../data/models/entry_status.dart';
import '../data/models/library.dart';
import '../data/models/media_type.dart';
import '../data/models/released.dart';

/// Development only: pads every type with generated entries so that the
/// long-list rail (A23 to A25) and the grid's fast scroll (A26) can be tried
/// on a device. Enabled with `--dart-define=LONG_LISTS=true`.
const longListsEnabled = bool.fromEnvironment('LONG_LISTS');

/// [perType] extra entries per type, cloned from that type's first entry,
/// spread over the decades since 1925 and over the last two years of added
/// dates, with a mix of statuses.
Library padForLongLists(Library library, {int perType = 120}) {
  final extra = <Entry>[];
  for (final type in MediaType.values) {
    final base = library.entriesOfType(type).firstOrNull;
    if (base == null) continue;
    final statuses = EntryStatus.optionsFor(type, kind: base.kind);
    for (var i = 0; i < perType; i++) {
      extra.add(
        base.copyWith(
          id: '${type.name}/long-$i',
          title: '${base.title} ${i + 1}',
          released: Released(1925 + (i * 7) % 100),
          added: DateTime(2026, 10, 9).subtract(Duration(days: i * 5)),
          status: statuses[i % statuses.length],
          rating: null,
          tags: const [],
          tracks: null,
          seasonalOnly: false,
        ),
      );
    }
  }
  return library.copyWith(entries: [...library.entries, ...extra]);
}
