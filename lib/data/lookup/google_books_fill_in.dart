import 'package:http/http.dart' as http;

import '../net/http_transport.dart';
import 'http_lookup_source.dart';
import 'lookup_failure.dart';
import 'rate_limiter.dart';
import 'text_clean.dart';

/// What Google Books knows about a book that Open Library may not: a
/// description and a cover. Asked only to fill a gap after a match was made
/// elsewhere; it never produces a match or an id of its own. Works without
/// a key, with a smaller quota.
class GoogleBooksFillIn with LookupHttp {
  GoogleBooksFillIn(
    this.client, {
    this.key = '',
    Uri? baseUrl,
    this.timeout = defaultHttpTimeout,
    this.userAgent = 'Libri',
  }) : _baseUrl =
           baseUrl ?? Uri.https('www.googleapis.com', '/books/v1/volumes'),
       limiter = RateLimiter(const Duration(milliseconds: 500));

  @override
  final http.Client client;
  @override
  final Duration timeout;
  @override
  final String userAgent;
  @override
  final RateLimiter limiter;

  final String key;
  final Uri _baseUrl;

  /// A description and a cover for [title] (by [author] when known), either
  /// null when Google Books has none. Throws [LookupException] on failure.
  Future<({String? description, String? coverUrl})> lookUp(
    String title, {
    String? author,
  }) async {
    final q = [
      'intitle:"$title"',
      if (author != null && author.isNotEmpty) 'inauthor:"$author"',
    ].join(' ');
    final response = await send(
      () => client.get(
        _baseUrl.replace(
          queryParameters: {
            'q': q,
            'printType': 'books',
            'maxResults': '3',
            if (key.isNotEmpty) 'key': key,
          },
        ),
        headers: {'Accept': 'application/json', 'User-Agent': userAgent},
      ),
    );
    check(response);
    String? description;
    String? cover;
    for (final item in objectsAt(decodeObject(response), 'items')) {
      final info = item['volumeInfo'] as Map<String, Object?>? ?? const {};
      description ??= switch (stringAt(info, 'description')) {
        final text? => stripHtml(text),
        null => null,
      };
      final links = info['imageLinks'] as Map<String, Object?>? ?? const {};
      cover ??= switch (stringAt(links, 'thumbnail')) {
        final url? => cleanCoverUrl(url),
        null => null,
      };
      if (description != null && cover != null) break;
    }
    return (description: description, coverUrl: cover);
  }

  /// Google's thumbnails come over http with a page-curl effect baked in.
  static String cleanCoverUrl(String url) => url
      .replaceFirst(RegExp(r'^http://'), 'https://')
      .replaceAll('&edge=curl', '');
}
