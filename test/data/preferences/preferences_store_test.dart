import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/preferences/preferences_store.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('libri-prefs-');
    file = File('${dir.path}/preferences.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('a missing or unreadable file reads as no preferences', () async {
    expect(await FilePreferencesStore(file).load(), isEmpty);
    file.writeAsStringSync('[1, 2');
    expect(await FilePreferencesStore(file).load(), isEmpty);
    file.writeAsStringSync('[1, 2]');
    expect(await FilePreferencesStore(file).load(), isEmpty);
  });

  test('saves survive a restart, the last one winning', () async {
    final store = FilePreferencesStore(file);
    await Future.wait([
      store.save({'theme': 'dark'}),
      store.save({'theme': 'light'}),
    ]);
    expect(await FilePreferencesStore(file).load(), {'theme': 'light'});
    expect(file.readAsStringSync(), endsWith('}\n'));
  });
}
