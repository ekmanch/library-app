import 'package:freezed_annotation/freezed_annotation.dart';

import 'book_format.dart';
import 'date_only_converter.dart';
import 'entry_status.dart';
import 'media_type.dart';
import 'music_kind.dart';
import 'released.dart';
import 'track.dart';

part 'entry.freezed.dart';
part 'entry.g.dart';

/// One title in the library, of any type.
///
/// The field order here is the key order in `library.json`. Common fields are
/// always written, even when null, so an edit changes as few lines as
/// possible. Type-specific fields are omitted when absent.
@freezed
abstract class Entry with _$Entry {
  const Entry._();

  const factory Entry({
    required String id,
    required MediaType type,
    required String title,
    @ReleasedConverter() Released? released,
    String? creator,
    required EntryStatus status,
    int? rating,
    @Default([]) List<String> tags,
    @Default('') String note,
    @Default('') String description,
    @JsonKey(name: 'seasonal_only') @Default(false) bool seasonalOnly,
    @DateOnlyConverter() required DateTime added,
    // Games.
    @JsonKey(includeIfNull: false) String? platform,
    // Books.
    @JsonKey(includeIfNull: false) List<BookFormat>? formats,
    // Music.
    @JsonKey(includeIfNull: false) MusicKind? kind,
    @JsonKey(includeIfNull: false) String? album,
    @JsonKey(includeIfNull: false) List<Track>? tracks,
  }) = _Entry;

  factory Entry.fromJson(Map<String, Object?> json) => _$EntryFromJson(json);

  int? get year => released?.year;

  /// False only when a release date is known and still in the future.
  bool isReleasedOn(DateTime today) => released?.isReleasedOn(today) ?? true;
}
