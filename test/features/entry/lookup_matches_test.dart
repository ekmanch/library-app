import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/features/entry/lookup_matches.dart';

void main() {
  test('fakeLookup matches titles, case-insensitively, by type', () {
    expect(fakeLookup(''), isEmpty);
    expect(fakeLookup('carrie').length, 4);
    expect(
      fakeLookup('CARRIE', type: MediaType.books).single.creator,
      'Stephen King',
    );
    expect(fakeLookup('zelda'), isEmpty);
    final tlou = fakeLookup('the last of us', type: MediaType.games).first;
    expect(tlou.platforms.first, 'PlayStation 3');
    expect(tlou.tags, contains('zombies'));
    expect(tlou.source, 'IGDB');
  });

  test('every match suggests tags, whatever its type', () {
    for (final query in [
      'the last of us',
      'carrie',
      'dune',
      'akira',
      'blade runner',
      'perfect blue',
      'hounds',
      'running up',
      'silent hill',
    ]) {
      for (final match in fakeLookup(query)) {
        expect(match.tags, isNotEmpty, reason: match.title);
        expect(match.source, isNotNull, reason: match.title);
      }
    }
  });

  test('titles starting with the query come first', () {
    final titles = fakeLookup('blade').map((m) => m.title).toList();
    expect(titles.first, 'Blade Runner');
    expect(fakeLookup('2049').single.title, 'Blade Runner 2049');
  });
}
