import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/lookup/lookup_failure.dart';
import 'package:library_app/data/lookup/lookup_match.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/dev/fake_lookup.dart';

void main() {
  test('the catalog matches titles, case-insensitively, by type', () {
    expect(FakeLookupSource.catalogSearch(''), isEmpty);
    expect(FakeLookupSource.catalogSearch('carrie').length, 4);
    expect(
      FakeLookupSource.catalogSearch(
        'CARRIE',
        type: MediaType.books,
      ).single.creator,
      'Stephen King',
    );
    expect(FakeLookupSource.catalogSearch('zelda'), isEmpty);
    final tlou = FakeLookupSource.catalogSearch(
      'the last of us',
      type: MediaType.games,
    ).first;
    expect(tlou.platforms.first, 'PlayStation 3');
    expect(tlou.tags, contains('zombies'));
    expect(tlou.source, 'igdb:1009');
    expect(tlou.coverUrl, 'fake://cover/poster/igdb:1009');
  });

  test('every match has tags, an id in the stored format and a cover', () {
    final idPattern = RegExp(
      r'^(tmdb:(movie|tv)|igdb|anilist|openlibrary|deezer:(album|track)):[^:]+$',
    );
    for (final match in fakeCatalog) {
      expect(match.tags, isNotEmpty, reason: match.title);
      expect(match.source, matches(idPattern), reason: match.title);
      expect(LookupMatch.providerOf(match.source), isNot('fake'));
      expect(
        match.coverUrl,
        startsWith(
          match.type == MediaType.music
              ? 'fake://cover/square/'
              : 'fake://cover/poster/',
        ),
      );
    }
    final song = fakeCatalog.singleWhere((m) => m.album != null);
    expect(song.source, startsWith('deezer:track:'));
    expect(song.albumSource, 'deezer:album:91627');
  });

  test('titles starting with the query come first', () {
    final titles = FakeLookupSource.catalogSearch('blade')
        .map((m) => m.title)
        .toList();
    expect(titles.first, 'Blade Runner');
    expect(
      FakeLookupSource.catalogSearch('2049').single.title,
      'Blade Runner 2049',
    );
  });

  test('search answers from the catalog and records the call', () async {
    final fake = FakeLookupSource();
    final hits = await fake.search('dune', type: MediaType.movies, limit: 1);
    expect(hits.single.title, 'Dune');
    expect(fake.calls, ['search:dune:movies']);
  });

  test('match finds a catalog title by year, else makes one up', () async {
    final fake = FakeLookupSource();
    final carrie = await fake.match(
      'Carrie',
      type: MediaType.movies,
      year: 1976,
    );
    expect(carrie!.creator, 'Brian De Palma');
    final dirt = await fake.match(
      'Dirt',
      type: MediaType.music,
      creator: 'Alice in Chains',
    );
    expect(dirt!.source, 'fake:dirt');
    expect(dirt.coverUrl, 'fake://cover/square/fake:dirt');
    expect(await fake.match('!!!', type: MediaType.books), isNull);
    expect(
      await fake.coverUrl('igdb:1009', type: MediaType.games),
      'fake://cover/poster/igdb:1009',
    );
  });

  test('a failure and a missing key are reported like a real source', () {
    final offline = FakeLookupSource(failure: LookupFailure.offline);
    expect(
      offline.search('dune', type: MediaType.movies),
      throwsA(
        isA<LookupException>().having(
          (e) => e.failure,
          'failure',
          LookupFailure.offline,
        ),
      ),
    );
    expect(FakeLookupSource(configured: false).isConfigured, isFalse);
    expect(offline.issued('tmdb:movie:1'), isTrue);
  });

  test('the fixture albums Dirt and Dark Side have a track list', () async {
    final fake = FakeLookupSource();
    expect((await fake.albumTracks('fake:dirt')).length, 13);
    expect(
      (await fake.albumTracks('deezer:album:91627')).first.title,
      'Them Bones',
    );
    expect(
      (await fake.albumTracks('fake:the-dark-side-of-the-moon')).last.title,
      'Eclipse',
    );
    expect(await fake.albumTracks('fake:nothing'), isEmpty);
    expect(
      await fake.artistPhotoUrl('Kate Bush'),
      'fake://cover/square/artist:kate-bush',
    );
    expect(await fake.artistPhotoUrl('Various Artists'), isNull);
  });
}
