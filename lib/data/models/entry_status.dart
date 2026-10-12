import 'package:json_annotation/json_annotation.dart';

import 'entry.dart';
import 'media_type.dart';

enum EntryStatus {
  want,
  @JsonValue('in_progress')
  inProgress,
  done,
  dnf;

  /// The statuses an entry can have. A movie or an album is watched or
  /// heard in one sitting, so neither is ever "in progress". Music has no
  /// DNF either: nobody marks a three-minute song as not finished.
  static List<EntryStatus> optionsFor(MediaType type) => switch (type) {
    MediaType.movies => const [want, done, dnf],
    MediaType.music => const [want, done],
    _ => values,
  };

  static List<EntryStatus> optionsForEntry(Entry entry) =>
      optionsFor(entry.type);
}
