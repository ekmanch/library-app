import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/entry_id.dart';
import 'package:library_app/data/models/media_type.dart';

void main() {
  group('slugify', () {
    test('lowercases and hyphenates', () {
      expect(slugify('The Mummy'), 'the-mummy');
      expect(slugify('  Dune: Part Two! '), 'dune-part-two');
      expect(slugify('Wallace & Gromit'), 'wallace-gromit');
    });

    test('drops apostrophes instead of hyphenating them', () {
      expect(slugify("Salem's Lot"), 'salems-lot');
      expect(slugify('Gerald’s Game'), 'geralds-game');
      expect(
        slugify("Frieren: Beyond Journey's End"),
        'frieren-beyond-journeys-end',
      );
      expect(slugify("Gasolin'"), 'gasolin');
    });

    test('folds diacritics to ASCII', () {
      expect(slugify('Amélie'), 'amelie');
      expect(slugify('Shinichirō Watanabe'), 'shinichiro-watanabe');
      expect(slugify('Björk'), 'bjork');
      expect(slugify('Blue Öyster Cult'), 'blue-oyster-cult');
    });

    test('keeps digits', () {
      expect(slugify('2Pac'), '2pac');
      expect(slugify('Blade Runner 2049'), 'blade-runner-2049');
    });
  });

  group('EntryId.generate', () {
    test('uses the year for every type but music', () {
      for (final type in MediaType.values.where((t) => t != MediaType.music)) {
        final id = EntryId.generate(
          type: type,
          title: 'The Mummy',
          year: '1999',
          artist: 'Ignored',
          existingIds: const [],
        );
        expect(id, '${type.name}/the-mummy-1999');
      }
    });

    test('books use the year, not the author', () {
      final id = EntryId.generate(
        type: MediaType.books,
        title: "Salem's Lot",
        year: '1975',
        existingIds: const [],
      );
      expect(id, 'books/salems-lot-1975');
    });

    test('uses the artist for music, never the year', () {
      final id = EntryId.generate(
        type: MediaType.music,
        title: 'Dirt',
        year: '1992',
        artist: 'Alice in Chains',
        existingIds: const [],
      );
      expect(id, 'music/dirt-alice-in-chains');
    });

    test('works without a year or artist', () {
      expect(
        EntryId.generate(
          type: MediaType.books,
          title: 'Piranesi',
          existingIds: const [],
        ),
        'books/piranesi',
      );
      expect(
        EntryId.generate(
          type: MediaType.music,
          title: 'Irish Pub Songs',
          existingIds: const [],
        ),
        'music/irish-pub-songs',
      );
    });

    test('falls back to "untitled" when nothing survives slugifying', () {
      expect(
        EntryId.generate(
          type: MediaType.games,
          title: '???',
          existingIds: const [],
        ),
        'games/untitled',
      );
    });

    test('appends -2, then -3 on collision for a year type', () {
      final existing = <String>['movies/the-mummy-1999'];
      String next() => EntryId.generate(
        type: MediaType.movies,
        title: 'The Mummy',
        year: '1999',
        existingIds: existing,
      );
      final second = next();
      expect(second, 'movies/the-mummy-1999-2');
      existing.add(second);
      expect(next(), 'movies/the-mummy-1999-3');
    });

    test('appends -2, then -3 on collision for music', () {
      final existing = <String>['music/stilla-natt-adolf-fredriks-ungdomskor'];
      String next() => EntryId.generate(
        type: MediaType.music,
        title: 'Stilla natt',
        artist: 'Adolf Fredriks Ungdomskör',
        existingIds: existing,
      );
      final second = next();
      expect(second, 'music/stilla-natt-adolf-fredriks-ungdomskor-2');
      existing.add(second);
      expect(next(), 'music/stilla-natt-adolf-fredriks-ungdomskor-3');
    });

    test('skips a taken suffix', () {
      final id = EntryId.generate(
        type: MediaType.shows,
        title: 'IT',
        year: '1990',
        existingIds: const ['shows/it-1990', 'shows/it-1990-2'],
      );
      expect(id, 'shows/it-1990-3');
    });
  });
}
