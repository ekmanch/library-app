import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// The request never reached the server, or the server never answered: no
/// network, a dropped connection, a timeout. Every HTTP client in the app
/// (GitHub, the lookups, the image fetcher) maps this to its own "offline"
/// failure, so the rule for what counts as offline lives in one place.
class NetworkUnreachable implements Exception {
  const NetworkUnreachable(this.message);

  final String message;

  @override
  String toString() => 'NetworkUnreachable: $message';
}

/// The default wait for an answer before a request counts as offline.
const defaultHttpTimeout = Duration(seconds: 20);

/// Runs [request] and turns transport errors into [NetworkUnreachable].
/// HTTP error statuses are not errors here: the caller reads the status.
Future<http.Response> sendOrOffline(
  Future<http.Response> Function() request, {
  Duration timeout = defaultHttpTimeout,
}) async {
  try {
    return await request().timeout(timeout);
  } on SocketException catch (e) {
    throw NetworkUnreachable(e.message);
  } on TimeoutException {
    throw const NetworkUnreachable('timed out');
  } on http.ClientException catch (e) {
    throw NetworkUnreachable(e.message);
  }
}
