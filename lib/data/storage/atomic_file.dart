import 'dart:io';

/// Writes [text] to [file] so that a crash or a full disk never leaves a
/// half-written file: the text goes to a sibling `.tmp` file first, which
/// then replaces [file] in one rename.
Future<void> writeAtomically(File file, String text) async {
  await file.parent.create(recursive: true);
  final temp = File('${file.path}.tmp');
  await temp.writeAsString(text, flush: true);
  await temp.rename(file.path);
}
