import '../data/models/entry_status.dart';
import '../data/models/media_type.dart';

/// UI words for the enums. American spelling, sentence case.
extension EntryStatusLabel on EntryStatus {
  String get label => switch (this) {
    EntryStatus.want => 'Want',
    EntryStatus.inProgress => 'In progress',
    EntryStatus.done => 'Done',
    EntryStatus.dnf => 'DNF',
  };
}

extension MediaTypeLabel on MediaType {
  /// Plural, for headings and chips: "Movies".
  String get label => switch (this) {
    MediaType.movies => 'Movies',
    MediaType.shows => 'Shows',
    MediaType.books => 'Books',
    MediaType.games => 'Games',
    MediaType.music => 'Music',
    MediaType.anime => 'Anime',
  };

  /// Singular, for one entry: "Movie", "Album" is handled by the caller.
  String get singular => switch (this) {
    MediaType.movies => 'Movie',
    MediaType.shows => 'Show',
    MediaType.books => 'Book',
    MediaType.games => 'Game',
    MediaType.music => 'Music',
    MediaType.anime => 'Anime',
  };
}
