import 'package:freezed_annotation/freezed_annotation.dart';

part 'track.freezed.dart';
part 'track.g.dart';

/// A rated track on an album entry. Only rated tracks are stored; a track is
/// not a song entry. [id] is the lookup id, when known.
@freezed
abstract class Track with _$Track {
  const factory Track({
    required String title,
    @JsonKey(includeIfNull: false) String? id,
    required int rating,
  }) = _Track;

  factory Track.fromJson(Map<String, Object?> json) => _$TrackFromJson(json);
}
