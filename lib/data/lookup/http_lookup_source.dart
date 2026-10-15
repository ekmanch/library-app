import 'dart:convert';

import 'package:http/http.dart' as http;

import '../net/http_transport.dart';
import 'lookup_failure.dart';
import 'lookup_source.dart';
import 'rate_limiter.dart';

/// What the HTTP-backed lookups share: the offline mapping, the status
/// check, JSON decoding, and a [RateLimiter] so a scroll through a photo
/// view never bursts past a provider's limit.
mixin LookupHttp {
  http.Client get client;
  Duration get timeout;
  String get userAgent;
  RateLimiter get limiter;

  /// Runs [request] under the rate limiter; transport errors become
  /// [LookupFailure.offline].
  Future<http.Response> send(Future<http.Response> Function() request) async {
    try {
      return await limiter.run(() => sendOrOffline(request, timeout: timeout));
    } on NetworkUnreachable catch (e) {
      throw LookupException(LookupFailure.offline, message: e.message);
    }
  }

  /// Throws unless the status is in [ok]: 429 is rate limited, anything
  /// else is "other" with the body's message when it has one.
  void check(http.Response response, {Set<int> ok = const {200}}) {
    final status = response.statusCode;
    if (ok.contains(status)) return;
    throw LookupException(
      status == 429 ? LookupFailure.rateLimited : LookupFailure.other,
      status: status,
      message: _message(response),
    );
  }

  /// The decoded JSON body, or [LookupFailure.other] when it is not JSON.
  Object? decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (e) {
      throw LookupException(
        LookupFailure.other,
        status: response.statusCode,
        message: 'not JSON: ${e.message}',
      );
    }
  }

  /// [decode] as an object, or "other" when it is something else.
  Map<String, Object?> decodeObject(http.Response response) {
    final json = decode(response);
    if (json is Map<String, Object?>) return json;
    throw LookupException(
      LookupFailure.other,
      status: response.statusCode,
      message: 'not a JSON object',
    );
  }

  static String _message(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map) {
        for (final key in const ['status_message', 'message', 'error']) {
          final value = json[key];
          if (value is String) return value;
          if (value is Map && value['message'] is String) {
            return value['message'] as String;
          }
        }
      }
    } on Object {
      // Not JSON; fall through.
    }
    return response.reasonPhrase ?? '';
  }
}

/// A [LookupSource] over HTTP, with one client and a rate limiter.
abstract class HttpLookupSource extends LookupSource with LookupHttp {
  HttpLookupSource(
    this.client, {
    required Duration minGap,
    this.timeout = defaultHttpTimeout,
    this.userAgent = 'Libri',
  }) : limiter = RateLimiter(minGap);

  @override
  final http.Client client;
  @override
  final Duration timeout;
  @override
  final String userAgent;
  @override
  final RateLimiter limiter;

  /// Throws [LookupFailure.notConfigured] before any request when a key is
  /// missing; every public method starts here.
  void requireConfigured() {
    if (!isConfigured) {
      throw const LookupException(LookupFailure.notConfigured);
    }
  }
}

/// Reads a JSON list of objects at [key], or an empty list.
List<Map<String, Object?>> objectsAt(Map<String, Object?> json, String key) => [
  for (final item in json[key] as List<Object?>? ?? const [])
    if (item is Map<String, Object?>) item,
];

/// A string at [key], or null when missing or empty.
String? stringAt(Map<String, Object?> json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}
