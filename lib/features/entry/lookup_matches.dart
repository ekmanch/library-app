import 'package:flutter/foundation.dart';

import '../../data/models/entry.dart';
import '../../data/models/media_type.dart';
import '../../data/models/released.dart';

/// One candidate from a title lookup (A13). Phase 5 fills these from TMDB,
/// AniList and the rest; until then [fakeLookup] serves a fixed list.
@immutable
class LookupMatch {
  const LookupMatch({
    required this.type,
    required this.title,
    this.released,
    this.creator,
    this.description = '',
    this.album,
    this.platforms = const [],
    this.tags = const [],
    this.source,
  });

  final MediaType type;
  final String title;
  final Released? released;
  final String? creator;
  final String description;

  /// For a song: the album it is on.
  final String? album;

  /// For a game: the platforms it is out on, as the lookup lists them.
  final List<String> platforms;

  /// Tag names the lookup suggests (genres, themes). The form matches them
  /// to the library's tags and offers the rest as new ones.
  final List<String> tags;

  /// Where the details came from: "TMDB", "IGDB" and so on.
  final String? source;
}

/// One track of an album's track list, as the lookup would return it.
typedef TrackInfo = ({String id, String title});

/// The cached track list of [album] (A22), or null when none is cached.
/// Phase 5 fetches and caches these; until then two fixture albums have
/// one, and the rest show only their rated tracks.
List<TrackInfo>? fakeTrackList(Entry album) => _trackLists[album.id];

const _trackLists = <String, List<TrackInfo>>{
  'music/dirt-alice-in-chains': [
    (id: 'mb:7c9a1', title: 'Them Bones'),
    (id: 'mb:7c9a2', title: 'Dam That River'),
    (id: 'mb:7c9a3', title: 'Rain When I Die'),
    (id: 'mb:7c9a4', title: 'Down in a Hole'),
    (id: 'mb:7c9a5', title: 'Sickman'),
    (id: 'mb:7c9a7', title: 'Rooster'),
    (id: 'mb:7c9a6', title: 'Junkhead'),
    (id: 'mb:7c9a8', title: 'Dirt'),
    (id: 'mb:7c9a9', title: 'God Smack'),
    (id: 'mb:7c9a10', title: 'Iron Gland'),
    (id: 'mb:7c9a11', title: 'Hate to Feel'),
    (id: 'mb:7c9a12', title: 'Angry Chair'),
    (id: 'mb:7c9a13', title: 'Would?'),
  ],
  'music/the-dark-side-of-the-moon-pink-floyd': [
    (id: 'mb:dsotm01', title: 'Speak to Me'),
    (id: 'mb:dsotm02', title: 'Breathe (In the Air)'),
    (id: 'mb:dsotm03', title: 'On the Run'),
    (id: 'mb:dsotm04', title: 'Time'),
    (id: 'mb:dsotm05', title: 'The Great Gig in the Sky'),
    (id: 'mb:dsotm06', title: 'Money'),
    (id: 'mb:dsotm07', title: 'Us and Them'),
    (id: 'mb:dsotm08', title: 'Any Colour You Like'),
    (id: 'mb:dsotm09', title: 'Brain Damage'),
    (id: 'mb:dsotm10', title: 'Eclipse'),
  ],
};

/// Static matches for trying the new-entry flow without a network. Case
/// does not matter; a query matches when the title contains it.
List<LookupMatch> fakeLookup(String query, {MediaType? type}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final hits = _catalog.where(
    (m) =>
        (type == null || m.type == type) && m.title.toLowerCase().contains(q),
  );
  final starts = hits.where((m) => m.title.toLowerCase().startsWith(q));
  final rest = hits.where((m) => !m.title.toLowerCase().startsWith(q));
  return [...starts, ...rest];
}

const _catalog = <LookupMatch>[
  LookupMatch(
    type: MediaType.games,
    title: 'The Last of Us',
    released: Released(2013, 6, 14),
    creator: 'Naughty Dog',
    description: 'Joel and Ellie cross a ruined United States.',
    platforms: ['PlayStation 3', 'PlayStation 4', 'PlayStation 5', 'PC'],
    tags: [
      'horror',
      'adventure',
      'post-apocalyptic',
      'stealth',
      'survival',
      'zombies',
    ],
    source: 'IGDB',
  ),
  LookupMatch(
    type: MediaType.games,
    title: 'The Last of Us Part II',
    released: Released(2020, 6, 19),
    creator: 'Naughty Dog',
    description: 'Five years on, Ellie sets out for Seattle.',
    platforms: ['PlayStation 4', 'PlayStation 5', 'PC'],
    tags: ['adventure', 'post-apocalyptic', 'stealth', 'survival'],
    source: 'IGDB',
  ),
  LookupMatch(
    type: MediaType.shows,
    title: 'The Last of Us',
    released: Released(2023),
    creator: 'Craig Mazin, Neil Druckmann',
    description: 'The HBO adaptation of the game.',
    tags: ['drama', 'horror', 'post-apocalyptic'],
    source: 'TMDB',
  ),
  LookupMatch(
    type: MediaType.games,
    title: 'The Last of Us: Left Behind',
    released: Released(2014, 2, 14),
    creator: 'Naughty Dog',
    description: 'A standalone chapter about Ellie and Riley.',
    platforms: ['PlayStation 3', 'PlayStation 4'],
    tags: ['adventure', 'post-apocalyptic'],
    source: 'IGDB',
  ),
  LookupMatch(
    type: MediaType.shows,
    title: 'Carrie',
    released: Released(2026),
    creator: 'Mike Flanagan',
    description: 'A limited series take on the Stephen King novel.',
    tags: ['horror', 'drama'],
    source: 'TMDB',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Carrie',
    released: Released(2013),
    creator: 'Kimberly Peirce',
    description:
        'A shy teenager with telekinetic powers is pushed too far at prom.',
    tags: ['horror', 'drama'],
    source: 'TMDB',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Carrie',
    released: Released(1976),
    creator: 'Brian De Palma',
    description:
        'A sheltered girl discovers her powers after a cruel prank at prom.',
    tags: ['horror', 'classic'],
    source: 'TMDB',
  ),
  LookupMatch(
    type: MediaType.books,
    title: 'Carrie',
    released: Released(1974),
    creator: 'Stephen King',
    description:
        "Stephen King's first novel, told through clippings and "
        'testimony.',
    tags: ['horror', 'stephen-king'],
    source: 'Open Library',
  ),
  LookupMatch(
    type: MediaType.books,
    title: 'Dune',
    released: Released(1965),
    creator: 'Frank Herbert',
    description: 'Paul Atreides and the desert planet Arrakis.',
    tags: ['sci-fi', 'epic', 'classic'],
    source: 'Open Library',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Dune',
    released: Released(1984),
    creator: 'David Lynch',
    description: "David Lynch's adaptation of the Frank Herbert novel.",
    tags: ['sci-fi', 'epic', 'cult'],
    source: 'TMDB',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Dune',
    released: Released(2021),
    creator: 'Denis Villeneuve',
    description:
        'The first half of the novel, from Caladan to the deep '
        'desert.',
    tags: ['sci-fi', 'epic', 'adventure'],
    source: 'TMDB',
  ),
  LookupMatch(
    type: MediaType.games,
    title: 'Dune: Awakening',
    released: Released(2025, 6, 10),
    creator: 'Funcom',
    description: 'An open-world survival game set on Arrakis.',
    platforms: ['PC'],
    tags: ['survival', 'sci-fi', 'open-world'],
    source: 'IGDB',
  ),
  LookupMatch(
    type: MediaType.anime,
    title: 'Akira',
    released: Released(1988),
    creator: 'Katsuhiro Otomo',
    description: 'A biker gang, a secret military project and Neo-Tokyo.',
    tags: ['2d', 'scifi', 'cyberpunk', 'classic'],
    source: 'AniList',
  ),
  LookupMatch(
    type: MediaType.books,
    title: 'Akira',
    released: Released(1982),
    creator: 'Katsuhiro Otomo',
    description: 'The manga the film was drawn from.',
    tags: ['manga', 'scifi', 'cyberpunk'],
    source: 'Open Library',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Blade Runner',
    released: Released(1982),
    creator: 'Ridley Scott',
    description: 'A blade runner hunts four replicants in 2019 Los Angeles.',
    tags: ['sci-fi', 'neo-noir', 'classic', 'dark'],
    source: 'TMDB',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Blade Runner 2049',
    released: Released(2017),
    creator: 'Denis Villeneuve',
    description:
        'A new blade runner unearths a secret that could end '
        'everything.',
    tags: ['sci-fi', 'neo-noir', 'melancholic'],
    source: 'TMDB',
  ),
  LookupMatch(
    type: MediaType.anime,
    title: 'Perfect Blue',
    released: Released(1997),
    creator: 'Satoshi Kon',
    description: 'A pop idol turned actress loses her grip on what is real.',
    tags: ['2d', 'thriller', 'psychological', 'dark'],
    source: 'AniList',
  ),
  LookupMatch(
    type: MediaType.music,
    title: 'Hounds of Love',
    released: Released(1985),
    creator: 'Kate Bush',
    description: "Kate Bush's fifth studio album.",
    tags: ['art-pop', 'pop', 'classic'],
    source: 'MusicBrainz',
  ),
  LookupMatch(
    type: MediaType.music,
    title: 'Running Up That Hill',
    released: Released(1985),
    creator: 'Kate Bush',
    album: 'Hounds of Love',
    tags: ['art-pop', 'pop', 'synth'],
    source: 'MusicBrainz',
  ),
  LookupMatch(
    type: MediaType.games,
    title: 'Silent Hill 2',
    released: Released(2024, 10, 8),
    creator: 'Bloober Team',
    description: 'The remake of the 2001 survival horror game.',
    platforms: ['PlayStation 5', 'PC'],
    tags: ['survival-horror', 'horror', 'psychological'],
    source: 'IGDB',
  ),
];
