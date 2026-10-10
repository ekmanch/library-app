import 'package:freezed_annotation/freezed_annotation.dart';

import 'entry.dart';
import 'media_type.dart';
import 'plan.dart';
import 'tag_category.dart';

part 'library.freezed.dart';
part 'library.g.dart';

/// The whole `library.json` file, version 2.
@freezed
abstract class Library with _$Library {
  const Library._();

  const factory Library({
    @Default(2) int version,
    @Default({}) Map<TagCategory, List<String>> tags,
    @Default([]) List<Entry> entries,
    @Default([]) List<Plan> plans,
  }) = _Library;

  factory Library.fromJson(Map<String, Object?> json) =>
      _$LibraryFromJson(json);

  Entry? entryById(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Plan? planById(String id) {
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  List<Entry> entriesOfType(MediaType type) =>
      entries.where((e) => e.type == type).toList();

  /// Every tag name in the map, in any category.
  Set<String> get allTags => {for (final names in tags.values) ...names};

  /// Tags used by at least one entry or one plan.
  Set<String> get usedTags => {
    for (final entry in entries) ...entry.tags,
    for (final plan in plans) ...plan.tags,
  };

  /// Drops tags no entry and no plan uses, and categories left empty.
  /// Order within a category is kept.
  Library withUnusedTagsRemoved() {
    final used = usedTags;
    final pruned = <TagCategory, List<String>>{};
    for (final MapEntry(key: category, value: names) in tags.entries) {
      final kept = names.where(used.contains).toList();
      if (kept.isNotEmpty) pruned[category] = kept;
    }
    return copyWith(tags: pruned);
  }
}
