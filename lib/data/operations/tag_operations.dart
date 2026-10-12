import '../models/library.dart';
import '../models/tag_category.dart';
import 'library_operation.dart';

/// Adds a tag to the tag map under a category. Tags are only created from
/// the entry form's tag picker (D10), right before the entry that uses them
/// is saved; a tag no entry or plan uses is pruned on the next edit.
class AddTag extends LibraryOperation {
  const AddTag(this.name, this.category);

  final String name;
  final TagCategory category;

  @override
  Library apply(Library library) {
    if (library.allTags.contains(name)) return library;
    final tags = {
      for (final MapEntry(key: k, value: v) in library.tags.entries) k: [...v],
    };
    tags.putIfAbsent(category, () => []).add(name);
    return library.copyWith(tags: tags);
  }

  @override
  String summary(Library before) => 'Add the tag #$name';
}
