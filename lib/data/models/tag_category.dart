import 'package:json_annotation/json_annotation.dart';

import 'media_type.dart';

/// Tag categories, in display order. The JSON keys of the `tags` map are
/// the display names.
enum TagCategory {
  /// Genres for movies, shows, books and anime.
  @JsonValue('Genres')
  genre,
  @JsonValue('Game genres')
  gameGenre,
  @JsonValue('Music genres')
  musicGenre,
  @JsonValue('Mood')
  mood,
  @JsonValue('Season')
  season,
  @JsonValue('Creators')
  creators,
  @JsonValue('Animation style')
  animationStyle,
  @JsonValue('Other')
  other;

  /// Whether the tag picker (D14) lists this category for an entry of
  /// [type] before anything is typed: game genres only for games, music
  /// genres only for music. A search finds every tag.
  bool offeredFor(MediaType type) => switch (this) {
    gameGenre => type == MediaType.games,
    musicGenre => type == MediaType.music,
    _ => true,
  };

  /// The category a new tag starts on in D10.
  static TagCategory defaultFor(MediaType type) => switch (type) {
    MediaType.games => gameGenre,
    MediaType.music => musicGenre,
    _ => genre,
  };
}
