import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_codec.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/dev/long_lists.dart';

import '../helpers/pump_app.dart';

void main() {
  test('pads every type, keeps ids unique and the result encodable', () {
    final fixture = loadFixture();
    final padded = padForLongLists(fixture, perType: 50);
    for (final type in MediaType.values) {
      expect(
        padded.entriesOfType(type).length,
        fixture.entriesOfType(type).length + 50,
      );
    }
    expect(
      padded.entries.map((e) => e.id).toSet().length,
      padded.entries.length,
    );
    expect(
      decodeLibrary(encodeLibrary(padded)).entries.length,
      padded.entries.length,
    );
    expect(longListsEnabled, isFalse);
  });
}
