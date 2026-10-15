import '../models/media_type.dart';
import '../models/released.dart';
import 'http_lookup_source.dart';
import 'igdb_token_store.dart';
import 'lookup_failure.dart';
import 'lookup_match.dart';
import 'text_clean.dart';

/// Games from IGDB, which sits behind Twitch: a client id and secret turn
/// into an app access token (cached in [tokens]), sent with every query.
/// Ids are "igdb:1009". One search carries everything the form needs:
/// name, release date, summary, developers, platforms, genres and cover.
class IgdbSource extends HttpLookupSource {
  IgdbSource(
    super.client, {
    required this.clientId,
    required this.clientSecret,
    required this.tokens,
    Uri? baseUrl,
    Uri? tokenUrl,
    super.timeout,
  }) : _baseUrl = baseUrl ?? Uri.https('api.igdb.com', '/v4/'),
       _tokenUrl = tokenUrl ?? Uri.https('id.twitch.tv', '/oauth2/token'),
       super(minGap: const Duration(milliseconds: 300));

  final String clientId;
  final String clientSecret;
  final IgdbTokenStore tokens;
  final Uri _baseUrl;
  final Uri _tokenUrl;

  static const _images = 'https://images.igdb.com/igdb/image/upload/';

  /// 264 × 374, enough for a row and the details header on a 3x screen.
  static const coverSize = 't_cover_big';

  static const _fields =
      'name,first_release_date,summary,cover.image_id,platforms.name,'
      'involved_companies.company.name,involved_companies.developer,'
      'genres.name';

  @override
  String get id => 'igdb';

  @override
  Set<MediaType> get types => const {MediaType.games};

  @override
  bool get isConfigured => clientId.isNotEmpty && clientSecret.isNotEmpty;

  String? _token;

  Future<String> _accessToken() async {
    _token ??= await tokens.valid();
    if (_token case final token?) return token;
    final response = await send(
      () => client.post(
        _tokenUrl.replace(
          queryParameters: {
            'client_id': clientId,
            'client_secret': clientSecret,
            'grant_type': 'client_credentials',
          },
        ),
        headers: {'Accept': 'application/json', 'User-Agent': userAgent},
      ),
    );
    check(response);
    final json = decodeObject(response);
    final token = stringAt(json, 'access_token');
    final expiresIn = json['expires_in'];
    if (token == null) {
      throw const LookupException(
        LookupFailure.other,
        message: 'no access token from Twitch',
      );
    }
    await tokens.save(
      token,
      expiresIn: Duration(seconds: expiresIn is num ? expiresIn.toInt() : 3600),
    );
    return _token = token;
  }

  /// Runs an Apicalypse [body] against `games`. A refused token is dropped
  /// and fetched again once.
  Future<List<Map<String, Object?>>> _games(String body) async {
    requireConfigured();
    for (var attempt = 0; ; attempt++) {
      final token = await _accessToken();
      final response = await send(
        () => client.post(
          _baseUrl.resolve('games'),
          headers: {
            'Client-ID': clientId,
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'User-Agent': userAgent,
          },
          body: body,
        ),
      );
      if (response.statusCode == 401 && attempt == 0) {
        _token = null;
        await tokens.clear();
        continue;
      }
      check(response);
      final json = decode(response);
      if (json is! List) {
        throw LookupException(
          LookupFailure.other,
          status: response.statusCode,
          message: 'not a JSON list',
        );
      }
      return [
        for (final item in json)
          if (item is Map<String, Object?>) item,
      ];
    }
  }

  static String _quote(String text) =>
      '"${text.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  /// IGDB says "PC (Microsoft Windows)" and "Nintendo Switch"; the form's
  /// normalizer takes it from there.
  static String _platform(String name) =>
      name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();

  LookupMatch? _match(Map<String, Object?> game) {
    final id = game['id'];
    final name = stringAt(game, 'name');
    if (id is! num || name == null) return null;
    final epoch = game['first_release_date'];
    final date = epoch is num
        ? DateTime.fromMillisecondsSinceEpoch(epoch.toInt() * 1000, isUtc: true)
        : null;
    final developers = [
      for (final c in objectsAt(game, 'involved_companies'))
        if (c['developer'] == true)
          ?stringAt(c['company'] as Map<String, Object?>? ?? const {}, 'name'),
    ];
    final cover = game['cover'] as Map<String, Object?>?;
    final imageId = cover == null ? null : stringAt(cover, 'image_id');
    return LookupMatch(
      type: MediaType.games,
      title: name,
      source: 'igdb:${id.toInt()}',
      released: date == null ? null : Released(date.year, date.month, date.day),
      creator: developers.isEmpty ? null : developers.join(', '),
      description: stringAt(game, 'summary') ?? '',
      platforms: [
        for (final p in objectsAt(game, 'platforms'))
          if (stringAt(p, 'name') case final n?) _platform(n),
      ],
      tags: [for (final g in objectsAt(game, 'genres')) ?stringAt(g, 'name')],
      coverUrl: imageId == null ? null : coverUrlFor(imageId),
    );
  }

  static String coverUrlFor(String imageId) =>
      '$_images$coverSize/$imageId.jpg';

  Future<List<LookupMatch>> _search(String query, int limit) async {
    final games = await _games(
      'search ${_quote(query)}; fields $_fields; '
      'where version_parent = null; limit $limit;',
    );
    return [for (final game in games) ?_match(game)];
  }

  @override
  Future<List<LookupMatch>> search(
    String query, {
    required MediaType type,
    int limit = 10,
  }) => _search(query, limit);

  @override
  Future<LookupMatch?> match(
    String title, {
    required MediaType type,
    int? year,
    String? creator,
  }) async {
    // The same name again is usually a remake or a port; the year tells
    // them apart, and without one the first (IGDB's best) is taken.
    return pickByTitleAndYear(
      await _search(title, 10),
      title,
      year: year,
      titleOf: (m) => m.title,
      yearOf: (m) => m.released?.year,
    );
  }

  static int _parse(String source) {
    final parts = source.split(':');
    final id = parts.length == 2 && parts[0] == 'igdb'
        ? int.tryParse(parts[1])
        : null;
    if (id == null) {
      throw LookupException(
        LookupFailure.other,
        message: 'not an IGDB id: $source',
      );
    }
    return id;
  }

  @override
  Future<String?> coverUrl(String source, {required MediaType type}) async {
    final games = await _games(
      'fields cover.image_id; where id = ${_parse(source)}; limit 1;',
    );
    if (games.isEmpty) return null;
    final cover = games.first['cover'] as Map<String, Object?>?;
    final imageId = cover == null ? null : stringAt(cover, 'image_id');
    return imageId == null ? null : coverUrlFor(imageId);
  }
}
