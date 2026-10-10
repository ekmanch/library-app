import 'package:json_annotation/json_annotation.dart';

import 'entry.dart';
import 'media_type.dart';
import 'music_kind.dart';

enum EntryStatus {
  want,
  @JsonValue('in_progress')
  inProgress,
  done,
  dnf;

  /// The statuses an entry can have. Music has no DNF: nobody marks a
  /// three-minute song as not finished. A song is not "in progress" either.
  /// Without a [kind], music gets the album choices.
  static List<EntryStatus> optionsFor(MediaType type, {MusicKind? kind}) {
    if (type != MediaType.music) return values;
    return kind == MusicKind.song
        ? const [want, done]
        : const [want, inProgress, done];
  }

  static List<EntryStatus> optionsForEntry(Entry entry) =>
      optionsFor(entry.type, kind: entry.kind);
}
