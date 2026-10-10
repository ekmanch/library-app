import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/operations/operations.dart';

void main() {
  final file = File('assets/fixtures/library.json');

  test('decoding then encoding the fixture is byte-identical', () {
    final text = file.readAsStringSync();
    expect(encodeLibrary(decodeLibrary(text)), text);
  });

  test('a rating change touches exactly one line', () {
    final library = decodeLibrary(file.readAsStringSync());
    final before = encodeLibrary(library).split('\n');
    final changed = const SetRating('movies/the-mummy-1999', 7).apply(library);
    final after = encodeLibrary(changed).split('\n');

    expect(after.length, before.length);
    final diffs = [
      for (var i = 0; i < before.length; i++)
        if (before[i] != after[i]) (before[i], after[i]),
    ];
    expect(diffs, [('      "rating": 9,', '      "rating": 7,')]);
  });

  test('clearing a rating keeps the key', () {
    final library = decodeLibrary(file.readAsStringSync());
    final changed = const SetRating(
      'movies/the-mummy-1999',
      null,
    ).apply(library);
    expect(encodeLibrary(changed), contains('"rating": null'));
  });
}
