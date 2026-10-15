import '../models/media_type.dart';
import '../models/released.dart';
import 'http_lookup_source.dart';
import 'lookup_failure.dart';
import 'lookup_match.dart';
import 'text_clean.dart';

/// Movies and shows from TMDB. Ids are "tmdb:movie:603" and "tmdb:tv:1399".
/// The search gives title, date, overview and poster; the director or the
/// show's creators and the genres come with [details], fetched when a
/// match is picked.
class TmdbSource extends HttpLookupSource {
  TmdbSource(super.client, {required this.token, Uri? baseUrl, super.timeout})
    : _baseUrl = baseUrl ?? Uri.https('api.themoviedb.org', '/3/'),
      super(minGap: const Duration(milliseconds: 50));

  /// The API read access token (a Bearer), empty when not set up.
  final String token;
  final Uri _baseUrl;

  static const _images = 'https://image.tmdb.org/t/p/';

  /// Poster widths: rows show a 44 dp thumbnail, the cache keeps the list
  /// and details size.
  static const rowPosterWidth = 'w185';
  static const coverPosterWidth = 'w342';

  @override
  String get id => 'tmdb';

  @override
  Set<MediaType> get types => const {MediaType.movies, MediaType.shows};

  @override
  bool get isConfigured => token.isNotEmpty;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'User-Agent': userAgent,
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      _baseUrl.resolve(path).replace(queryParameters: query);

  static String _kind(MediaType type) =>
      type == MediaType.shows ? 'tv' : 'movie';

  Future<Map<String, Object?>> _get(
    String path, [
    Map<String, String>? q,
  ]) async {
    requireConfigured();
    final response = await send(
      () => client.get(_uri(path, q), headers: _headers),
    );
    check(response);
    return decodeObject(response);
  }

  Future<List<LookupMatch>> _search(
    String query,
    MediaType type, {
    int? year,
  }) async {
    final kind = _kind(type);
    final json = await _get('search/$kind', {
      'query': query,
      'include_adult': 'false',
      if (year != null)
        (kind == 'tv' ? 'first_air_date_year' : 'primary_release_year'):
            '$year',
    });
    return [for (final item in objectsAt(json, 'results')) ?_match(item, type)];
  }

  LookupMatch? _match(Map<String, Object?> item, MediaType type) {
    final tv = type == MediaType.shows;
    final title = stringAt(item, tv ? 'name' : 'title');
    final id = item['id'];
    if (title == null || id is! num) return null;
    final date = stringAt(item, tv ? 'first_air_date' : 'release_date');
    final poster = stringAt(item, 'poster_path');
    return LookupMatch(
      type: type,
      title: title,
      source: 'tmdb:${_kind(type)}:${id.toInt()}',
      released: date == null ? null : Released.tryParse(date),
      description: stringAt(item, 'overview') ?? '',
      coverUrl: poster == null ? null : '$_images$rowPosterWidth$poster',
    );
  }

  @override
  Future<List<LookupMatch>> search(
    String query, {
    required MediaType type,
    int limit = 10,
  }) async => (await _search(query, type)).take(limit).toList();

  @override
  Future<LookupMatch?> match(
    String title, {
    required MediaType type,
    int? year,
    String? creator,
  }) async {
    final hits = await _search(title, type, year: year);
    final exact = hits.where((m) => sameTitle(m.title, title));
    if (exact.isNotEmpty) return exact.first;
    // With the year narrowing the search, TMDB's first hit is the title
    // under another spelling or language; without one, a different title
    // is a different work.
    return year != null && hits.isNotEmpty ? hits.first : null;
  }

  /// "tmdb:movie:603" -> ("movie", "603"); anything else is "other".
  static (String kind, String id) _parse(String source) {
    final parts = source.split(':');
    if (parts.length != 3 ||
        parts[0] != 'tmdb' ||
        (parts[1] != 'movie' && parts[1] != 'tv')) {
      throw LookupException(
        LookupFailure.other,
        message: 'not a TMDB id: $source',
      );
    }
    return (parts[1], parts[2]);
  }

  @override
  Future<LookupMatch> details(LookupMatch match) async {
    final (kind, id) = _parse(match.source);
    final json = await _get(
      '$kind/$id',
      kind == 'movie' ? const {'append_to_response': 'credits'} : null,
    );
    final tv = kind == 'tv';
    final creators = tv
        ? [for (final c in objectsAt(json, 'created_by')) ?stringAt(c, 'name')]
        : [
            for (final c in objectsAt(
              json['credits'] as Map<String, Object?>? ?? const {},
              'crew',
            ))
              if (c['job'] == 'Director') ?stringAt(c, 'name'),
          ];
    final date = stringAt(json, tv ? 'first_air_date' : 'release_date');
    final poster = stringAt(json, 'poster_path');
    return match.copyWith(
      creator: creators.isEmpty ? null : creators.join(', '),
      released: date == null ? null : Released.tryParse(date),
      description: stringAt(json, 'overview'),
      tags: [for (final g in objectsAt(json, 'genres')) ?stringAt(g, 'name')],
      coverUrl: poster == null ? null : '$_images$rowPosterWidth$poster',
    );
  }

  @override
  Future<String?> coverUrl(String source, {required MediaType type}) async {
    final (kind, id) = _parse(source);
    final poster = stringAt(await _get('$kind/$id'), 'poster_path');
    return poster == null ? null : '$_images$coverPosterWidth$poster';
  }
}
