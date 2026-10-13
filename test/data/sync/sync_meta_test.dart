import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/sync/sync_meta.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('libri-meta-'));
  tearDown(() => dir.deleteSync(recursive: true));

  final meta = SyncMeta(
    etag: '"abc"',
    remoteSha: 'r' * 40,
    canonicalSha: 'c' * 40,
    commitSha: 'd' * 40,
    lastSynced: DateTime.utc(2026, 10, 13, 20, 1),
    lastChecked: DateTime.utc(2026, 10, 13, 20, 5),
  );

  test('round-trips through sync.json', () async {
    final store = SyncMetaStore(File('${dir.path}/sync.json'));
    expect(await store.load(), isNull);
    await store.save(meta);
    expect(await SyncMetaStore(File('${dir.path}/sync.json')).load(), meta);
    await store.delete();
    expect(await store.load(), isNull);
  });

  test('copyWith can clear the etag and the commit', () {
    final cleared = meta.copyWith(etag: null, commitSha: null);
    expect(cleared.etag, isNull);
    expect(cleared.commitSha, isNull);
    expect(cleared.remoteSha, meta.remoteSha);
    expect(meta.copyWith(lastChecked: DateTime.utc(2027)).etag, '"abc"');
  });

  test('a file without the shas is no meta', () {
    expect(SyncMeta.fromJson({'etag': 'x'}), isNull);
  });
}
