import 'dart:convert';

import 'models/library.dart';
import 'models/tag_category.dart';

/// The one place `library.json` text is produced.
///
/// The output is canonical so that a save produces a minimal git diff:
/// two-space indent, one trailing newline, keys in model declaration order,
/// tag categories in [TagCategory] order, entries and plans in the order
/// they are stored. Decoding then encoding a canonical file gives back the
/// same bytes.
const _encoder = JsonEncoder.withIndent('  ');

/// Decodes [text]. A file whose tag categories are out of order (one the
/// app wrote before it kept them in order) comes back in order, so the
/// screens list the groups right and the next save moves the group.
Library decodeLibrary(String text) => _inCategoryOrder(
  Library.fromJson(jsonDecode(text) as Map<String, Object?>),
);

String encodeLibrary(Library library) =>
    '${_encoder.convert(_inCategoryOrder(library).toJson())}\n';

Library _inCategoryOrder(Library library) {
  final ordered = Library.tagsInCategoryOrder(library.tags);
  if (ordered.keys.toList().toString() ==
      library.tags.keys.toList().toString()) {
    return library;
  }
  return library.copyWith(tags: ordered);
}
