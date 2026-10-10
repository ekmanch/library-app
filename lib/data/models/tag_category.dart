import 'package:json_annotation/json_annotation.dart';

/// Tag categories. The JSON keys of the `tags` map are the display names.
enum TagCategory {
  @JsonValue('Genre')
  genre,
  @JsonValue('Animation style')
  animationStyle,
  @JsonValue('Game genre')
  gameGenre,
  @JsonValue('Mood')
  mood,
  @JsonValue('Season')
  season,
  @JsonValue('Creators')
  creators,
  @JsonValue('Other')
  other,
}
