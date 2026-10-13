import 'dart:io';

import 'json_file.dart';

/// Where the library connection (repository, file, branch) is kept on the
/// device, as `connection.json`. The token is not here; see `TokenStore`.
abstract interface class ConnectionStore {
  /// The stored connection, or null when there is none.
  Future<Map<String, Object?>?> load();

  Future<void> save(Map<String, Object?> json);

  Future<void> clear();
}

class MemoryConnectionStore implements ConnectionStore {
  MemoryConnectionStore([this.saved]);

  Map<String, Object?>? saved;

  @override
  Future<Map<String, Object?>?> load() async => saved;

  @override
  Future<void> save(Map<String, Object?> json) async => saved = json;

  @override
  Future<void> clear() async => saved = null;
}

class FileConnectionStore implements ConnectionStore {
  FileConnectionStore(File file) : _file = JsonFile(file);

  final JsonFile _file;

  @override
  Future<Map<String, Object?>?> load() => _file.read();

  @override
  Future<void> save(Map<String, Object?> json) => _file.write(json);

  @override
  Future<void> clear() => _file.delete();
}
