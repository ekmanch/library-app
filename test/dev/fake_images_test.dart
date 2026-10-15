import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/images/image_fetcher.dart';
import 'package:library_app/dev/fake_images.dart';

void main() {
  testWidgets('a fake cover is a PNG of the right shape, the same each time', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final poster = await decodeImageFromList(fakeCoverPng('igdb:1009'));
      expect((poster.width, poster.height), (300, 450));
      final square = await decodeImageFromList(
        fakeCoverPng('deezer:album:1', square: true),
      );
      expect((square.width, square.height), (300, 300));
      expect(fakeCoverPng('x'), fakeCoverPng('x'));
      expect(fakeCoverPng('x'), isNot(fakeCoverPng('y')));

      // Not one flat color: the diagonal and the band are there.
      final data = await poster.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = data!.buffer.asUint8List();
      int at(int x, int y) => pixels[(y * 300 + x) * 4];
      expect(at(290, 10), isNot(at(10, 440)));
      expect(at(150, 290), isNot(at(150, 100)));
    });
  });

  test('the fetcher serves fake URLs and rejects the rest', () async {
    final fetcher = FakeImageFetcher(failing: {'fake://cover/poster/bad'});
    final bytes = await fetcher.fetch(Uri.parse('fake://cover/poster/igdb:1'));
    expect(bytes, fakeCoverPng('igdb:1'));
    expect(
      fetcher.fetch(Uri.parse('https://real/x.jpg')),
      throwsA(
        isA<ImageFetchException>().having((e) => e.status, 'status', 404),
      ),
    );
    expect(
      fetcher.fetch(Uri.parse('fake://cover/poster/bad')),
      throwsA(
        isA<ImageFetchException>().having((e) => e.status, 'status', 500),
      ),
    );
    expect(fetcher.fetched.length, 3);
  });
}
