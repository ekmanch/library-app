import 'dart:io' show ZLibEncoder;
import 'dart:typed_data';

import '../data/images/image_fetcher.dart';

/// Serves `fake://cover/poster/<seed>` and `fake://cover/square/<seed>`
/// with a PNG drawn on the spot, for the widget tests and the screenshot
/// walks: no network, no bundled assets, the same picture for the same
/// seed every time. Anything else is a 404. [failing] URLs fail.
class FakeImageFetcher implements ImageFetcher {
  FakeImageFetcher({this.latency = Duration.zero, Set<String>? failing})
    : failing = failing ?? {};

  final Duration latency;
  final Set<String> failing;

  /// Every URL fetched, in order.
  final fetched = <String>[];

  final _bytes = <String, Uint8List>{};

  @override
  Future<Uint8List> fetch(Uri url) async {
    fetched.add(url.toString());
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failing.contains(url.toString())) {
      throw const ImageFetchException(500, message: 'fake failure');
    }
    final segments = url.pathSegments;
    if (url.scheme != 'fake' ||
        url.host != 'cover' ||
        segments.length != 2 ||
        (segments[0] != 'poster' && segments[0] != 'square')) {
      throw const ImageFetchException(404, message: 'not a fake cover');
    }
    return _bytes[url.toString()] ??= fakeCoverPng(
      segments[1],
      square: segments[0] == 'square',
    );
  }
}

/// A 300 px wide PNG (450 tall for a poster, 300 for a square): a base
/// color from [seed], a darker diagonal, and a light band, so a cover is
/// told from the placeholder box at a glance.
Uint8List fakeCoverPng(String seed, {bool square = false}) {
  const width = 300;
  final height = square ? 300 : 450;
  final hash = seed.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff);
  final base = _palette[hash % _palette.length];
  final dark = [for (final c in base) (c * 0.62).round()];
  final light = [for (final c in base) (c + (255 - c) * 0.55).round()];
  final bandTop = (height * 0.62).round();
  final bandBottom = bandTop + (height * 0.08).round();

  final raw = Uint8List(height * (1 + width * 3));
  var i = 0;
  for (var y = 0; y < height; y++) {
    raw[i++] = 0; // filter: none
    for (var x = 0; x < width; x++) {
      final List<int> color;
      if (y >= bandTop && y < bandBottom) {
        color = light;
      } else if (x * height > y * width) {
        color = base;
      } else {
        color = dark;
      }
      raw[i++] = color[0];
      raw[i++] = color[1];
      raw[i++] = color[2];
    }
  }
  final idat = ZLibEncoder().convert(raw);

  final out = BytesBuilder(copy: false);
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final ihdr = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // color type: RGB
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  _chunk(out, 'IHDR', ihdr.buffer.asUint8List());
  _chunk(out, 'IDAT', idat);
  _chunk(out, 'IEND', const []);
  return out.takeBytes();
}

const _palette = [
  [0xC8, 0x5C, 0x5C],
  [0xD8, 0x8A, 0x3C],
  [0xC9, 0xA6, 0x3A],
  [0x5E, 0xA8, 0x6B],
  [0x3F, 0x9C, 0xA6],
  [0x4C, 0x7F, 0xD0],
  [0x8E, 0x6B, 0xD6],
  [0xC5, 0x5C, 0x9C],
];

void _chunk(BytesBuilder out, String type, List<int> data) {
  final typeBytes = type.codeUnits;
  final length = ByteData(4)..setUint32(0, data.length);
  out.add(length.buffer.asUint8List());
  out.add(typeBytes);
  out.add(data);
  final crc = ByteData(4)..setUint32(0, _crc32([...typeBytes, ...data]));
  out.add(crc.buffer.asUint8List());
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
