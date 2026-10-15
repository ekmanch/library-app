import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:library_app/data/images/image_cache_store.dart';
import 'package:library_app/data/images/image_fetcher.dart';
import 'package:library_app/data/net/http_transport.dart';

/// Answers with the URL's bytes, counts the calls, and can fail.
class _Fetcher implements ImageFetcher {
  final calls = <String>[];
  Object? failure;
  Completer<void>? gate;

  @override
  Future<Uint8List> fetch(Uri url) async {
    calls.add(url.toString());
    if (gate case final gate?) await gate.future;
    if (failure case final failure?) throw failure;
    return Uint8List.fromList(url.toString().codeUnits);
  }
}

void main() {
  late Directory dir;
  late _Fetcher fetcher;
  var now = DateTime(2026, 10, 15, 12);

  ImageCacheStore store() =>
      ImageCacheStore(dir, fetcher: fetcher, now: () => now);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('images');
    fetcher = _Fetcher();
  });
  tearDown(() => dir.delete(recursive: true));

  test('downloads once, then serves the file', () async {
    final cache = store();
    expect(cache.cachedFile('https://x/a.jpg'), isNull);
    final first = await cache.get('https://x/a.jpg');
    expect(first!.downloadedNow, isTrue);
    expect(first.file.path, cache.fileFor('https://x/a.jpg').path);
    expect(
      first.file.path,
      endsWith('${ImageCacheStore.keyFor('https://x/a.jpg')}.img'),
    );
    expect(await first.file.readAsString(), 'https://x/a.jpg');

    final again = await cache.get('https://x/a.jpg');
    expect(again!.downloadedNow, isFalse);
    expect(cache.cachedFile('https://x/a.jpg'), isNotNull);
    expect(fetcher.calls, ['https://x/a.jpg']);

    // A new store over the same folder finds it without a download.
    expect(store().cachedFile('https://x/a.jpg'), isNotNull);
    expect(fetcher.calls.length, 1);
  });

  test('two asks for the same URL at once make one download', () async {
    final cache = store();
    fetcher.gate = Completer<void>();
    final a = cache.get('https://x/a.jpg');
    final b = cache.get('https://x/a.jpg');
    fetcher.gate!.complete();
    final results = await Future.wait([a, b]);
    expect(results[0]!.file.path, results[1]!.file.path);
    expect(fetcher.calls.length, 1);
  });

  test('a failure is remembered, then retried later', () async {
    final cache = store();
    fetcher.failure = const ImageFetchException(404);
    expect(await cache.get('https://x/gone.jpg'), isNull);
    expect(await cache.get('https://x/gone.jpg'), isNull);
    expect(fetcher.calls.length, 1);
    now = now.add(const Duration(hours: 7));
    fetcher.failure = null;
    expect(await cache.get('https://x/gone.jpg'), isNotNull);
    expect(fetcher.calls.length, 2);
  });

  test('offline is retried much sooner', () async {
    final cache = store();
    fetcher.failure = const NetworkUnreachable('down');
    expect(await cache.get('https://x/a.jpg'), isNull);
    now = now.add(const Duration(seconds: 20));
    expect(await cache.get('https://x/a.jpg'), isNull);
    expect(fetcher.calls.length, 1);
    now = now.add(const Duration(seconds: 20));
    fetcher.failure = null;
    expect(await cache.get('https://x/a.jpg'), isNotNull);
  });

  test('prune keeps the wanted files and drops the rest', () async {
    final cache = store();
    await cache.get('https://x/keep.jpg');
    await cache.get('https://x/drop.jpg');
    await File('${cache.imagesDirectory.path}/half.img.tmp').writeAsString('x');
    expect(await cache.prune({'https://x/keep.jpg', 'https://x/never.jpg'}), 2);
    expect(cache.cachedFile('https://x/keep.jpg'), isNotNull);
    expect(cache.cachedFile('https://x/drop.jpg'), isNull);
    expect(await cache.imagesDirectory.list().length, 1);
    expect(
      await ImageCacheStore(
        Directory('${dir.path}/none'),
        fetcher: fetcher,
      ).prune({}),
      0,
    );
  });

  test('HttpImageFetcher wants a 200 with image bytes', () async {
    HttpImageFetcher fetcherFor(http.Response Function(http.Request) handler) =>
        HttpImageFetcher(MockClient((r) async => handler(r)));
    expect(
      await fetcherFor(
        (_) => http.Response.bytes(
          [1, 2, 3],
          200,
          headers: {'content-type': 'image/jpeg'},
        ),
      ).fetch(Uri.parse('https://x/a.jpg')),
      [1, 2, 3],
    );
    await expectLater(
      fetcherFor((_) => http.Response('nope', 404))
          .fetch(Uri.parse('https://x/a.jpg')),
      throwsA(
        isA<ImageFetchException>().having((e) => e.status, 'status', 404),
      ),
    );
    await expectLater(
      fetcherFor(
        (_) => http.Response(
          '<html>',
          200,
          headers: {'content-type': 'text/html'},
        ),
      ).fetch(Uri.parse('https://x/a.jpg')),
      throwsA(isA<ImageFetchException>()),
    );
    await expectLater(
      fetcherFor((_) => throw const SocketException('down'))
          .fetch(Uri.parse('https://x/a.jpg')),
      throwsA(isA<NetworkUnreachable>()),
    );
  });
}
