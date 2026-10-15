import 'dart:convert';

import '../models/media_type.dart';
import '../models/released.dart';
import 'http_lookup_source.dart';
import 'lookup_failure.dart';
import 'lookup_match.dart';
import 'text_clean.dart';

/// Anime from AniList's GraphQL API. No key. Ids are "anilist:21". The
/// search already carries everything the form needs, so [details] is the
/// match itself. AniList allows about 30 requests a minute, hence the gap.
class AniListSource extends HttpLookupSource {
  AniListSource(super.client, {Uri? baseUrl, super.timeout})
    : _baseUrl = baseUrl ?? Uri.https('graphql.anilist.co'),
      super(minGap: const Duration(seconds: 2));

  final Uri _baseUrl;

  static const _fields = '''
      id
      title { romaji english }
      startDate { year month day }
      description(asHtml: false)
      coverImage { large extraLarge }
      studios(isMain: true) { nodes { name } }
      genres''';

  static const _searchQuery =
      '''
query (\$search: String, \$perPage: Int, \$year: Int) {
  Page(perPage: \$perPage) {
    media(search: \$search, type: ANIME, sort: SEARCH_MATCH, seasonYear: \$year) {
$_fields
    }
  }
}''';

  static const _byIdQuery =
      '''
query (\$id: Int) {
  Media(id: \$id, type: ANIME) {
$_fields
  }
}''';

  @override
  String get id => 'anilist';

  @override
  Set<MediaType> get types => const {MediaType.anime};

  Future<Map<String, Object?>> _query(
    String query,
    Map<String, Object?> variables,
  ) async {
    final response = await send(
      () => client.post(
        _baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': userAgent,
        },
        body: jsonEncode({'query': query, 'variables': variables}),
      ),
    );
    // AniList answers 404 for an unknown id with an errors array; anything
    // else that is not 200 is a real failure.
    check(response, ok: const {200, 404});
    final json = decodeObject(response);
    final errors = json['errors'];
    final data = json['data'] as Map<String, Object?>?;
    if (data == null) {
      throw LookupException(
        LookupFailure.other,
        status: response.statusCode,
        message: errors is List && errors.isNotEmpty
            ? '${(errors.first as Map)['message']}'
            : 'no data',
      );
    }
    return data;
  }

  LookupMatch? _match(Map<String, Object?> media) {
    final id = media['id'];
    final titles = media['title'] as Map<String, Object?>? ?? const {};
    final title = stringAt(titles, 'english') ?? stringAt(titles, 'romaji');
    if (id is! num || title == null) return null;
    final date = media['startDate'] as Map<String, Object?>? ?? const {};
    final year = date['year'];
    final studios =
        (media['studios'] as Map<String, Object?>?)?['nodes'] as List? ??
        const [];
    final creators = [
      for (final s in studios)
        if (s is Map<String, Object?>) ?stringAt(s, 'name'),
    ];
    final cover = media['coverImage'] as Map<String, Object?>? ?? const {};
    return LookupMatch(
      type: MediaType.anime,
      title: title,
      source: 'anilist:${id.toInt()}',
      released: year is num
          ? Released(
              year.toInt(),
              (date['month'] as num?)?.toInt(),
              (date['day'] as num?)?.toInt(),
            )
          : null,
      creator: creators.isEmpty ? null : creators.join(', '),
      description: stripHtml(stringAt(media, 'description') ?? ''),
      tags: [for (final g in media['genres'] as List? ?? const []) '$g'],
      coverUrl: stringAt(cover, 'large'),
      largeCoverUrl: stringAt(cover, 'extraLarge'),
    );
  }

  Future<List<LookupMatch>> _search(
    String query, {
    int? year,
    int limit = 10,
  }) async {
    final data = await _query(_searchQuery, {
      'search': query,
      'perPage': limit,
      'year': ?year,
    });
    final page = data['Page'] as Map<String, Object?>? ?? const {};
    return [for (final media in objectsAt(page, 'media')) ?_match(media)];
  }

  @override
  Future<List<LookupMatch>> search(
    String query, {
    required MediaType type,
    int limit = 10,
  }) => _search(query, limit: limit);

  @override
  Future<LookupMatch?> match(
    String title, {
    required MediaType type,
    int? year,
    String? creator,
  }) async {
    final hits = await _search(title, year: year, limit: 5);
    for (final hit in hits) {
      if (sameTitle(hit.title, title)) return hit;
    }
    return year != null && hits.isNotEmpty ? hits.first : null;
  }

  static int _parse(String source) {
    final parts = source.split(':');
    final id = parts.length == 2 && parts[0] == 'anilist'
        ? int.tryParse(parts[1])
        : null;
    if (id == null) {
      throw LookupException(
        LookupFailure.other,
        message: 'not an AniList id: $source',
      );
    }
    return id;
  }

  @override
  Future<String?> coverUrl(String source, {required MediaType type}) async {
    final data = await _query(_byIdQuery, {'id': _parse(source)});
    final media = data['Media'] as Map<String, Object?>?;
    if (media == null) return null;
    final cover = media['coverImage'] as Map<String, Object?>? ?? const {};
    return stringAt(cover, 'extraLarge') ?? stringAt(cover, 'large');
  }
}
