import 'dart:convert';
import 'dart:io';

import '../storage/atomic_file.dart';
import 'track_info.dart';

/// Where fetched track lists are kept, by the album's lookup id.
abstract class TrackListStore {
  Future<List<TrackInfo>?> read(String albumSource);
  Future<void> write(String albumSource, List<TrackInfo> tracks);

  /// Drops every list but those of [keepSources].
  Future<void> prune(Set<String> keepSources);
}

/// For the tests, the walks and the FIRST_RUN demo.
class MemoryTrackListStore implements TrackListStore {
  final _lists = <String, List<TrackInfo>>{};

  @override
  Future<List<TrackInfo>?> read(String albumSource) async =>
      _lists[albumSource];

  @override
  Future<void> write(String albumSource, List<TrackInfo> tracks) async {
    _lists[albumSource] = List.unmodifiable(tracks);
  }

  @override
  Future<void> prune(Set<String> keepSources) async {
    _lists.removeWhere((source, _) => !keepSources.contains(source));
  }
}

/// One JSON file per album under `<cache>/tracks/`, named after the id
/// ("deezer-album-91627.json").
class FileTrackListStore implements TrackListStore {
  FileTrackListStore(this.directory);

  final Directory directory;

  static const _encoder = JsonEncoder.withIndent('  ');

  Directory get _tracks =>
      Directory('${directory.path}${Platform.pathSeparator}tracks');

  static String fileNameFor(String albumSource) =>
      '${albumSource.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')}.json';

  File _file(String albumSource) => File(
    '${_tracks.path}${Platform.pathSeparator}${fileNameFor(albumSource)}',
  );

  @override
  Future<List<TrackInfo>?> read(String albumSource) async {
    final file = _file(albumSource);
    try {
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, Object?> || json['source'] != albumSource) {
        return null;
      }
      return [
        for (final item in json['tracks'] as List<Object?>? ?? const [])
          if (item is Map<String, Object?> &&
              item['id'] is String &&
              item['title'] is String)
            (id: item['id'] as String, title: item['title'] as String),
      ];
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String albumSource, List<TrackInfo> tracks) =>
      writeAtomically(
        _file(albumSource),
        '${_encoder.convert({
          'source': albumSource,
          'fetched': DateTime.now().toUtc().toIso8601String(),
          'tracks': [
            for (final t in tracks) {'id': t.id, 'title': t.title},
          ],
        })}\n',
      );

  @override
  Future<void> prune(Set<String> keepSources) async {
    if (!await _tracks.exists()) return;
    final keep = {for (final s in keepSources) fileNameFor(s)};
    await for (final entity in _tracks.list()) {
      if (entity is File && !keep.contains(entity.uri.pathSegments.last)) {
        try {
          await entity.delete();
        } on FileSystemException {
          // The next prune gets it.
        }
      }
    }
  }
}
