import 'dart:convert';

import 'models/library.dart';

/// The one place `library.json` text is produced.
///
/// The output is canonical so that a save produces a minimal git diff:
/// two-space indent, one trailing newline, keys in model declaration order,
/// entries and plans in the order they are stored. Decoding then encoding
/// a canonical file gives back the same bytes.
const _encoder = JsonEncoder.withIndent('  ');

Library decodeLibrary(String text) =>
    Library.fromJson(jsonDecode(text) as Map<String, Object?>);

String encodeLibrary(Library library) =>
    '${_encoder.convert(library.toJson())}\n';
