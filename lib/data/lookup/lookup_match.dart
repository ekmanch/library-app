import 'package:flutter/foundation.dart';

import '../models/media_type.dart';
import '../models/released.dart';

/// One candidate from a title lookup (A13), or the match a cover was
/// resolved from. Filled by the sources in `lib/data/lookup/`; the fake in
/// `lib/dev/fake_lookup.dart` serves a fixed catalog for tests and demos.
@immutable
class LookupMatch {
  const LookupMatch({
    required this.type,
    required this.title,
    required this.source,
    this.released,
    this.creator,
    this.description = '',
    this.album,
    this.albumSource,
    this.platforms = const [],
    this.tags = const [],
    this.coverUrl,
  });

  final MediaType type;
  final String title;

  /// The lookup id, as stored on the entry: "tmdb:movie:603",
  /// "deezer:album:302127", "openlibrary:OL45804W".
  final String source;

  final Released? released;
  final String? creator;
  final String description;

  /// For a song: the album it is on, and that album's lookup id.
  final String? album;
  final String? albumSource;

  /// For a game: the platforms it is out on, as the lookup lists them.
  final List<String> platforms;

  /// Tag names the lookup suggests (genres, themes). The form matches them
  /// to the library's tags and offers the rest as new ones.
  final List<String> tags;

  /// A cover or artwork image, sized for a list row.
  final String? coverUrl;

  /// The provider part of a lookup id: "tmdb" for "tmdb:movie:603".
  static String providerOf(String source) =>
      source.substring(0, source.indexOf(':').clamp(0, source.length));

  LookupMatch copyWith({
    Released? released,
    String? creator,
    String? description,
    String? album,
    String? albumSource,
    List<String>? platforms,
    List<String>? tags,
    String? coverUrl,
  }) => LookupMatch(
    type: type,
    title: title,
    source: source,
    released: released ?? this.released,
    creator: creator ?? this.creator,
    description: description ?? this.description,
    album: album ?? this.album,
    albumSource: albumSource ?? this.albumSource,
    platforms: platforms ?? this.platforms,
    tags: tags ?? this.tags,
    coverUrl: coverUrl ?? this.coverUrl,
  );

  @override
  bool operator ==(Object other) =>
      other is LookupMatch &&
      other.type == type &&
      other.title == title &&
      other.source == source &&
      other.released == released &&
      other.creator == creator &&
      other.description == description &&
      other.album == album &&
      other.albumSource == albumSource &&
      listEquals(other.platforms, platforms) &&
      listEquals(other.tags, tags) &&
      other.coverUrl == coverUrl;

  @override
  int get hashCode => Object.hash(type, title, source, released, coverUrl);

  @override
  String toString() => 'LookupMatch($source, $title)';
}
