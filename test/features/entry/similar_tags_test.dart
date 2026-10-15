import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/features/entry/similar_tags.dart';

void main() {
  test('normalizeTag cleans up what was typed', () {
    expect(normalizeTag('  #Sci Fi  '), 'sci-fi');
    expect(normalizeTag('stop__motion'), 'stop-motion');
    expect(normalizeTag('--odd--'), 'odd');
    expect(normalizeTag('#'), '');
  });

  group('findSimilarTag', () {
    const tags = ['horror', 'scifi', 'cozy', 'ghibli', 'fantasy', 'rpg'];

    test('same once hyphens are ignored', () {
      expect(findSimilarTag('sci-fi', tags), 'scifi');
    });

    test('singular versus plural', () {
      expect(findSimilarTag('horrors', tags), 'horror');
      expect(findSimilarTag('fantasies', tags), 'fantasy');
    });

    test('one letter different, two for six letters or more', () {
      expect(findSimilarTag('cosy', tags), 'cozy');
      expect(findSimilarTag('jrpg', tags), 'rpg');
      expect(findSimilarTag('fantasie', tags), 'fantasy');
      expect(findSimilarTag('horrr', tags), 'horror');
    });

    test('two neighboring letters swapped', () {
      expect(findSimilarTag('ghilbi', tags), 'ghibli');
    });

    test('nothing close, or the same tag, gives null', () {
      expect(findSimilarTag('gothic', tags), isNull);
      expect(findSimilarTag('horror', tags), isNull);
      expect(findSimilarTag('cz', tags), isNull);
      expect(findSimilarTag('', tags), isNull);
    });

    test('prefers the hyphen match over an edit', () {
      expect(findSimilarTag('sci-fi', ['scify', 'scifi']), 'scifi');
    });
  });

  test('canonicalTag maps a lookup\'s synonyms to the library\'s spelling', () {
    expect(canonicalTag('Science Fiction'), 'scifi');
    expect(canonicalTag('sci-fi'), 'scifi');
    expect(canonicalTag('#Horror tales'), 'horror');
    expect(canonicalTag('Role-playing RPG'), 'rpg');
    expect(canonicalTag('grunge'), 'grunge');
  });
}
