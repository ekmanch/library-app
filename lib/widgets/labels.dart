import '../data/models/entry_status.dart';
import '../data/models/media_type.dart';
import '../data/models/tag_category.dart';

/// UI words for the enums. American spelling, sentence case.
extension EntryStatusLabel on EntryStatus {
  String get label => switch (this) {
    EntryStatus.want => 'Want',
    EntryStatus.inProgress => 'In progress',
    EntryStatus.done => 'Done',
    EntryStatus.dnf => 'DNF',
  };

  /// Mid-sentence form: "want", "in progress", "done", "DNF".
  String get lowerLabel =>
      this == EntryStatus.dnf ? label : label.toLowerCase();
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

/// "7 movies", "1 book", "3 anime". Music gets "entries" until the artist
/// screens of phase 1d replace its list.
String countLabel(MediaType type, int count) {
  final (one, many) = switch (type) {
    MediaType.movies => ('movie', 'movies'),
    MediaType.shows => ('show', 'shows'),
    MediaType.books => ('book', 'books'),
    MediaType.games => ('game', 'games'),
    MediaType.music => ('entry', 'entries'),
    MediaType.anime => ('anime', 'anime'),
  };
  return '$count ${count == 1 ? one : many}';
}

extension TagCategoryLabel on TagCategory {
  String get label => switch (this) {
    TagCategory.genre => 'Genre',
    TagCategory.animationStyle => 'Animation style',
    TagCategory.gameGenre => 'Game genre',
    TagCategory.mood => 'Mood',
    TagCategory.season => 'Season',
    TagCategory.creators => 'Creators',
    TagCategory.other => 'Other',
  };
}

/// The label of the one `creator` field, by type (DESIGN.md section 8).
String creatorLabel(MediaType type) => switch (type) {
  MediaType.movies => 'Director',
  MediaType.shows => 'Creator',
  MediaType.books => 'Author',
  MediaType.games => 'Studio',
  MediaType.music => 'Artist',
  MediaType.anime => 'Studio',
};

/// "8 / 10", or "Not rated".
String ratingLabel(int? rating) =>
    rating == null ? 'Not rated' : '$rating / 10';
