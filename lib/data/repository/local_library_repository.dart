import 'dart:async';
import 'dart:io';

import '../library_codec.dart';
import '../models/library.dart';
import '../operations/library_operation.dart';
import '../storage/atomic_file.dart';
import 'library_repository.dart';

/// Keeps the library in a `library.json` on the device, so changes survive
/// a restart. The file is written in the canonical form after every change
/// that alters it.
///
/// On the first start there is no file yet; it is created from [seed] (the
/// bundled fixture until the GitHub connection exists). A file that cannot
/// be read is never overwritten: it is renamed aside with an `.unreadable`
/// suffix and the library starts again from [seed].
class LocalLibraryRepository implements LibraryRepository {
  LocalLibraryRepository(this.file, {required this.seed});

  final File file;

  /// The library text for a new install.
  final Future<String> Function() seed;
  final _changes = StreamController<Library>.broadcast();
  Future<Library>? _loading;
  Library? _library;

  /// The text last written (or read), to skip writes that change nothing.
  String? _written;

  /// Writes run one after another, in the order the changes were applied.
  Future<void> _writing = Future.value();

  @override
  Future<Library> load() async {
    if (_library != null) return _library!;
    _loading ??= _read();
    final loaded = await _loading!;
    // An apply may have run while the file was loading; keep its result.
    return _library ??= loaded;
  }

  Future<Library> _read() async {
    if (await file.exists()) {
      final text = await file.readAsString();
      try {
        final library = decodeLibrary(text);
        _written = text;
        return library;
      } on Object {
        await file.rename(_asidePath());
      }
    }
    final library = decodeLibrary(await seed());
    await _save(library);
    return library;
  }

  String _asidePath() {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '${file.path}.$stamp.unreadable';
  }

  @override
  Stream<Library> watch() async* {
    yield await load();
    yield* _changes.stream;
  }

  /// Applies [operation], shows the result at once and returns when the
  /// file is written. A failed write is rethrown here; the change stays in
  /// memory and is written with the next one.
  @override
  Future<Library> apply(LibraryOperation operation) async {
    await load();
    // Read after the await: another change may have landed meanwhile, and
    // this one must build on it.
    final current = _library!;
    final next = operation.apply(current);
    if (next == current) return current;
    _library = next;
    _changes.add(next);
    await _save(next);
    return next;
  }

  /// Swaps in a whole library, e.g. a fresh copy from GitHub, shows it at
  /// once and returns when the file is written. Nothing happens when it
  /// is the library already held.
  Future<Library> replace(Library library) async {
    await load();
    if (library == _library) return library;
    _library = library;
    _changes.add(library);
    await _save(library);
    return library;
  }

  /// Removes the file (Disconnect). The in-memory library stays until the
  /// repository is disposed.
  Future<void> delete() {
    final deletion = _writing.then((_) async {
      if (await file.exists()) await file.delete();
      _written = null;
    });
    _writing = deletion.catchError((Object _) {});
    return deletion;
  }

  Future<void> _save(Library library) {
    final write = _writing.then((_) async {
      // A later change may already be in memory; write the newest.
      final text = encodeLibrary(_library ?? library);
      if (text == _written) return;
      await writeAtomically(file, text);
      _written = text;
    });
    // Keep the chain going after a failure; the caller still sees it.
    _writing = write.catchError((Object _) {});
    return write;
  }

  /// The current in-memory library, if loaded.
  Library? get current => _library;

  /// Waits for every pending write.
  Future<void> flush() => _writing;

  void dispose() => _changes.close();
}
