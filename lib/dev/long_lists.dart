import '../data/models/entry.dart';
import '../data/models/entry_status.dart';
import '../data/models/library.dart';
import '../data/models/media_type.dart';
import '../data/models/music_kind.dart';
import '../data/models/released.dart';

/// Development only: pads every type with generated entries so that the
/// long-list rail (A23 to A25) and the grid's fast scroll (A26) can be tried
/// on a device. Enabled with `--dart-define=LONG_LISTS=true`.
const longListsEnabled = bool.fromEnvironment('LONG_LISTS');

/// [perType] extra entries per type, cloned from that type's first entry,
/// spread over the decades since 1925 and over the last two years of added
/// dates, with a mix of statuses. Music is spread over generated artists
/// (some starting with "The", one "Various Artists") and over albums and
/// songs, so the artist list (A14) gets long too.
Library padForLongLists(Library library, {int perType = 120}) {
  final extra = <Entry>[];
  for (final type in MediaType.values) {
    final base = library.entriesOfType(type).firstOrNull;
    if (base == null) continue;
    final music = type == MediaType.music;
    for (var i = 0; i < perType; i++) {
      final kind = !music
          ? null
          : i % 4 == 3
          ? MusicKind.song
          : MusicKind.album;
      final statuses = EntryStatus.optionsFor(type, kind: kind ?? base.kind);
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
          creator: !music ? base.creator : _artistName(i),
          kind: kind ?? base.kind,
          album: kind == MusicKind.song ? 'Album ${i ~/ 4}' : null,
        ),
      );
    }
  }
  return library.copyWith(entries: [...library.entries, ...extra]);
}

/// Names spread over the alphabet ("B-Side Project 1", "The C-Side
/// Project 2", a few starting with a digit), with every ninth "Various
/// Artists", so the rail, the "The" rule and the pinned-last rule can all
/// be tried.
String _artistName(int i) {
  if (i % 9 == 8) return 'Various Artists';
  final the = i % 3 == 0 ? 'The ' : '';
  final letter = i % 10 == 9
      ? '${i % 7}'
      : String.fromCharCode('A'.codeUnitAt(0) + i % 26);
  return '$the$letter-Side Project ${i ~/ 26 + 1}';
}
