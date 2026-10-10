import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/entry_id.dart';
import 'package:library_app/data/models/media_type.dart';

void main() {
  group('slugify', () {
    test('lowercases and hyphenates', () {
      expect(slugify('The Mummy'), 'the-mummy');
      expect(
        slugify("Frieren: Beyond Journey's End"),
        'frieren-beyond-journey-s-end',
      );
      expect(slugify('  Dune: Part Two! '), 'dune-part-two');
    });

    test('folds diacritics to ASCII', () {
      expect(slugify('Amélie'), 'amelie');
      expect(slugify('Shinichirō Watanabe'), 'shinichiro-watanabe');
      expect(slugify('Björk'), 'bjork');
    });

    test('keeps digits', () {
      expect(slugify('2Pac'), '2pac');
    });
  });

  group('EntryId.generate', () {
    test('uses the year for most types', () {
      final id = EntryId.generate(
        type: MediaType.movies,
        title: 'The Mummy',
        year: '1999',
        existingIds: const [],
      );
      expect(id, 'movies/the-mummy-1999');
    });

    test('uses the artist for music', () {
      final id = EntryId.generate(
        type: MediaType.music,
        title: 'Dirt',
        year: '1992',
        artist: 'Alice in Chains',
        existingIds: const [],
      );
      expect(id, 'music/dirt-alice-in-chains');
    });

    test('works without a year', () {
      final id = EntryId.generate(
        type: MediaType.books,
        title: 'Piranesi',
        existingIds: const [],
      );
      expect(id, 'books/piranesi');
    });

    test('appends a number on collision', () {
      final existing = ['movies/the-mummy-1999', 'movies/the-mummy-1999-2'];
      final id = EntryId.generate(
        type: MediaType.movies,
        title: 'The Mummy',
        year: '1999',
        existingIds: existing,
      );
      expect(id, 'movies/the-mummy-1999-3');
    });
  });
}
