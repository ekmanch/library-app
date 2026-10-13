import 'dart:io';

import 'package:flutter/foundation.dart';

import '../storage/json_file.dart';

/// What the app remembers about the copy of the library file on GitHub,
/// kept in `sync.json` next to the cache.
@immutable
class SyncMeta {
  const SyncMeta({
    this.etag,
    required this.remoteSha,
    required this.canonicalSha,
    this.commitSha,
    this.lastSynced,
    this.lastChecked,
  });

  /// The ETag of the last download, for the next conditional request.
  /// Opaque; null right after a save, when the next check is a full GET.
  final String? etag;

  /// The blob sha of the file on GitHub, as last seen or written. The
  /// Contents API wants it as the `sha` of the file being replaced.
  final String remoteSha;

  /// The blob sha of the remote file re-encoded in the app's canonical
  /// form. Equal to [remoteSha] once the app has saved; different for a
  /// file formatted by hand. The cache with no pending operations encodes
  /// to this sha.
  final String canonicalSha;

  /// The commit of the last save, when known.
  final String? commitSha;

  /// When the cache last matched GitHub (a download or a successful save).
  final DateTime? lastSynced;

  /// When GitHub was last asked whether the file changed.
  final DateTime? lastChecked;

  SyncMeta copyWith({
    Object? etag = _unset,
    String? remoteSha,
    String? canonicalSha,
    Object? commitSha = _unset,
    DateTime? lastSynced,
    DateTime? lastChecked,
  }) => SyncMeta(
    etag: etag == _unset ? this.etag : etag as String?,
    remoteSha: remoteSha ?? this.remoteSha,
    canonicalSha: canonicalSha ?? this.canonicalSha,
    commitSha: commitSha == _unset ? this.commitSha : commitSha as String?,
    lastSynced: lastSynced ?? this.lastSynced,
    lastChecked: lastChecked ?? this.lastChecked,
  );

  static const _unset = Object();

  Map<String, Object?> toJson() => {
    'etag': etag,
    'remoteSha': remoteSha,
    'canonicalSha': canonicalSha,
    'commitSha': commitSha,
    'lastSynced': lastSynced?.toUtc().toIso8601String(),
    'lastChecked': lastChecked?.toUtc().toIso8601String(),
  };

  /// Null when the map is not a sync meta (e.g. from an older app).
  static SyncMeta? fromJson(Map<String, Object?> json) {
    final remoteSha = json['remoteSha'];
    final canonicalSha = json['canonicalSha'];
    if (remoteSha is! String || canonicalSha is! String) return null;
    return SyncMeta(
      etag: json['etag'] as String?,
      remoteSha: remoteSha,
      canonicalSha: canonicalSha,
      commitSha: json['commitSha'] as String?,
      lastSynced: _date(json['lastSynced']),
      lastChecked: _date(json['lastChecked']),
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  @override
  bool operator ==(Object other) =>
      other is SyncMeta &&
      other.etag == etag &&
      other.remoteSha == remoteSha &&
      other.canonicalSha == canonicalSha &&
      other.commitSha == commitSha &&
      other.lastSynced == lastSynced &&
      other.lastChecked == lastChecked;

  @override
  int get hashCode => Object.hash(
    etag,
    remoteSha,
    canonicalSha,
    commitSha,
    lastSynced,
    lastChecked,
  );
}

/// `sync.json` on the device.
class SyncMetaStore {
  SyncMetaStore(File file) : _file = JsonFile(file);

  final JsonFile _file;

  /// The stored meta, or null when there is none (or it is unreadable,
  /// which just costs one full download).
  Future<SyncMeta?> load() async {
    final json = await _file.read();
    return json == null ? null : SyncMeta.fromJson(json);
  }

  Future<void> save(SyncMeta meta) => _file.write(meta.toJson());

  Future<void> delete() => _file.delete();
}
