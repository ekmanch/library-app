import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:library_app/data/net/http_transport.dart';

void main() {
  test('an answer comes back as it is, whatever its status', () async {
    final response = await sendOrOffline(
      () async => http.Response('nope', 404),
    );
    expect(response.statusCode, 404);
    expect(response.body, 'nope');
  });

  test('no connection, a closed client and a timeout are unreachable', () {
    expect(
      sendOrOffline(() => throw const SocketException('unreachable')),
      throwsA(
        isA<NetworkUnreachable>().having(
          (e) => e.message,
          'message',
          'unreachable',
        ),
      ),
    );
    expect(
      sendOrOffline(() => throw http.ClientException('closed')),
      throwsA(isA<NetworkUnreachable>()),
    );
    expect(
      sendOrOffline(
        () => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(
        isA<NetworkUnreachable>().having(
          (e) => e.message,
          'message',
          'timed out',
        ),
      ),
    );
  });

  test('other errors pass through untouched', () {
    expect(
      sendOrOffline(() => throw StateError('bug')),
      throwsA(isA<StateError>()),
    );
  });
}
