import 'dart:convert';
import 'dart:io';

import 'atomic_file.dart';

/// A small JSON object on the device, written atomically with writes run
/// one after another. A missing or unreadable file reads as null; the
/// caller decides what that means.
class JsonFile {
  JsonFile(this.file);

  final File file;
  static const _encoder = JsonEncoder.withIndent('  ');
  Future<void> _writing = Future.value();

  Future<Map<String, Object?>?> read() async {
    try {
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return json is Map<String, Object?> ? json : null;
    } on Object {
      return null;
    }
  }

  Future<void> write(Map<String, Object?> json) {
    final text = '${_encoder.convert(json)}\n';
    final write = _writing.then((_) => writeAtomically(file, text));
    _writing = write.catchError((Object _) {});
    return write;
  }

  /// Removes the file, after any write still in progress.
  Future<void> delete() {
    final deletion = _writing.then((_) async {
      if (await file.exists()) await file.delete();
    });
    _writing = deletion.catchError((Object _) {});
    return deletion;
  }

  /// Waits for every pending write.
  Future<void> flush() => _writing;
}
