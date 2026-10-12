import 'dart:convert';
import 'dart:io';

import '../storage/atomic_file.dart';

/// Where the display preferences live on the device. Kept apart from
/// [LibraryRepository]: preferences are never part of `library.json` and
/// never synced.
abstract class PreferencesStore {
  /// The stored preferences, or an empty map when there are none yet.
  Future<Map<String, Object?>> load();

  Future<void> save(Map<String, Object?> json);
}

/// Keeps nothing; the default outside the running app, e.g. in tests.
class MemoryPreferencesStore implements PreferencesStore {
  MemoryPreferencesStore([Map<String, Object?>? json]) : saved = json ?? {};

  /// The last saved preferences.
  Map<String, Object?> saved;

  @override
  Future<Map<String, Object?>> load() async => saved;

  @override
  Future<void> save(Map<String, Object?> json) async => saved = json;
}

/// `preferences.json` next to the local library file. A missing or
/// unreadable file means the defaults.
class FilePreferencesStore implements PreferencesStore {
  FilePreferencesStore(this.file);

  final File file;
  static const _encoder = JsonEncoder.withIndent('  ');

  /// Saves run one after another, so the newest always lands last.
  Future<void> _saving = Future.value();

  @override
  Future<Map<String, Object?>> load() async {
    try {
      if (!await file.exists()) return {};
      final json = jsonDecode(await file.readAsString());
      return json is Map<String, Object?> ? json : {};
    } on Object {
      return {};
    }
  }

  @override
  Future<void> save(Map<String, Object?> json) {
    final text = '${_encoder.convert(json)}\n';
    final write = _saving.then((_) => writeAtomically(file, text));
    _saving = write.catchError((Object _) {});
    return write;
  }
}
