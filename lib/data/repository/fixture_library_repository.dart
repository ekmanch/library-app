import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;

import '../library_codec.dart';
import '../models/library.dart';
import '../operations/library_operation.dart';
import 'library_repository.dart';

/// Loads `assets/fixtures/library.json` and keeps every change in memory
/// only. Nothing is ever written anywhere.
class FixtureLibraryRepository implements LibraryRepository {
  FixtureLibraryRepository({Future<String> Function()? loadJson})
    : _loadJson = loadJson ?? _loadAsset;

  static const assetPath = 'assets/fixtures/library.json';

  static Future<String> _loadAsset() => rootBundle.loadString(assetPath);

  final Future<String> Function() _loadJson;
  final _changes = StreamController<Library>.broadcast();
  Future<Library>? _loading;
  Library? _library;

  @override
  Future<Library> load() async {
    if (_library != null) return _library!;
    _loading ??= _loadJson().then(decodeLibrary);
    final loaded = await _loading!;
    // An apply may have run while the file was loading; keep its result.
    return _library ??= loaded;
  }

  @override
  Stream<Library> watch() async* {
    yield await load();
    yield* _changes.stream;
  }

  @override
  Future<Library> apply(LibraryOperation operation) async {
    final next = operation.apply(await load());
    _library = next;
    _changes.add(next);
    return next;
  }

  /// The current in-memory library, if loaded.
  Library? get current => _library;

  void dispose() => _changes.close();
}
