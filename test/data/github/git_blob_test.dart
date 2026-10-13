import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/github/git_blob.dart';

void main() {
  test('matches what git hash-object gives', () {
    // `printf '' | git hash-object --stdin`
    expect(gitBlobSha(const []), 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391');
    // `printf 'hello\n' | git hash-object --stdin`
    expect(
      gitBlobSha(utf8.encode('hello\n')),
      'ce013625030ba8dba906f756967f9e9ca394464a',
    );
  });

  test('hashes bytes, so non-ASCII text counts its UTF-8 length', () {
    // `printf 'Pokémon' | git hash-object --stdin`
    expect(
      gitBlobSha(utf8.encode('Pokémon')),
      'a19365e94e41b31b3986facbe0299b09d2c290e1',
    );
  });
}
