import 'package:flutter/foundation.dart';

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
  });

  final MediaType type;
  final String title;
  final Released? released;
  final String? creator;
  final String description;

  /// For a song: the album it is on.
  final String? album;
}

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
    type: MediaType.shows,
    title: 'Carrie',
    released: Released(2026),
    creator: 'Mike Flanagan',
    description: 'A limited series take on the Stephen King novel.',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Carrie',
    released: Released(2013),
    creator: 'Kimberly Peirce',
    description:
        'A shy teenager with telekinetic powers is pushed too far at prom.',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Carrie',
    released: Released(1976),
    creator: 'Brian De Palma',
    description:
        'A sheltered girl discovers her powers after a cruel prank at prom.',
  ),
  LookupMatch(
    type: MediaType.books,
    title: 'Carrie',
    released: Released(1974),
    creator: 'Stephen King',
    description:
        "Stephen King's first novel, told through clippings and "
        'testimony.',
  ),
  LookupMatch(
    type: MediaType.books,
    title: 'Dune',
    released: Released(1965),
    creator: 'Frank Herbert',
    description: 'Paul Atreides and the desert planet Arrakis.',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Dune',
    released: Released(1984),
    creator: 'David Lynch',
    description: "David Lynch's adaptation of the Frank Herbert novel.",
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Dune',
    released: Released(2021),
    creator: 'Denis Villeneuve',
    description:
        'The first half of the novel, from Caladan to the deep '
        'desert.',
  ),
  LookupMatch(
    type: MediaType.games,
    title: 'Dune: Awakening',
    released: Released(2025, 6, 10),
    creator: 'Funcom',
    description: 'An open-world survival game set on Arrakis.',
  ),
  LookupMatch(
    type: MediaType.anime,
    title: 'Akira',
    released: Released(1988),
    creator: 'Katsuhiro Otomo',
    description: 'A biker gang, a secret military project and Neo-Tokyo.',
  ),
  LookupMatch(
    type: MediaType.books,
    title: 'Akira',
    released: Released(1982),
    creator: 'Katsuhiro Otomo',
    description: 'The manga the film was drawn from.',
  ),
  LookupMatch(
    type: MediaType.games,
    title: 'The Last of Us',
    released: Released(2013),
    creator: 'Naughty Dog',
    description: 'Joel and Ellie cross a ruined United States.',
  ),
  LookupMatch(
    type: MediaType.shows,
    title: 'The Last of Us',
    released: Released(2023),
    creator: 'Craig Mazin',
    description: 'The HBO adaptation of the game.',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Blade Runner',
    released: Released(1982),
    creator: 'Ridley Scott',
    description: 'A blade runner hunts four replicants in 2019 Los Angeles.',
  ),
  LookupMatch(
    type: MediaType.movies,
    title: 'Blade Runner 2049',
    released: Released(2017),
    creator: 'Denis Villeneuve',
    description:
        'A new blade runner unearths a secret that could end '
        'everything.',
  ),
  LookupMatch(
    type: MediaType.anime,
    title: 'Perfect Blue',
    released: Released(1997),
    creator: 'Satoshi Kon',
    description: 'A pop idol turned actress loses her grip on what is real.',
  ),
  LookupMatch(
    type: MediaType.music,
    title: 'Hounds of Love',
    released: Released(1985),
    creator: 'Kate Bush',
    description: "Kate Bush's fifth studio album.",
  ),
  LookupMatch(
    type: MediaType.music,
    title: 'Running Up That Hill',
    released: Released(1985),
    creator: 'Kate Bush',
    album: 'Hounds of Love',
  ),
  LookupMatch(
    type: MediaType.games,
    title: 'Silent Hill 2',
    released: Released(2024, 10, 8),
    creator: 'Bloober Team',
    description: 'The remake of the 2001 survival horror game.',
  ),
];
