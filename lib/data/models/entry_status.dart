import 'package:json_annotation/json_annotation.dart';

enum EntryStatus {
  want,
  @JsonValue('in_progress')
  inProgress,
  done,
  dnf,
}
