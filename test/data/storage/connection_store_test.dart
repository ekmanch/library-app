import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/storage/connection_store.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('libri-connection-');
    file = File('${dir.path}/connection.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('a missing or unreadable file is no connection', () async {
    expect(await FileConnectionStore(file).load(), isNull);
    file.writeAsStringSync('{"repository": ');
    expect(await FileConnectionStore(file).load(), isNull);
  });

  test('a saved connection survives a restart and clear removes it', () async {
    final store = FileConnectionStore(file);
    await store.save({'repository': 'ekmanch/library', 'file': 'library.json'});
    expect(await FileConnectionStore(file).load(), {
      'repository': 'ekmanch/library',
      'file': 'library.json',
    });
    expect(file.readAsStringSync(), endsWith('}\n'));
    await store.clear();
    expect(file.existsSync(), isFalse);
    expect(await FileConnectionStore(file).load(), isNull);
  });
}
