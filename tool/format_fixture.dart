// Rewrites assets/fixtures/library.json in the app's canonical encoding, so
// the "decode then encode is byte-identical" test holds after hand edits.
//
// Run from the project root: dart run tool/format_fixture.dart
import 'dart:io';

import 'package:library_app/data/library_codec.dart';

void main() {
  final file = File('assets/fixtures/library.json');
  final library = decodeLibrary(file.readAsStringSync());
  file.writeAsStringSync(encodeLibrary(library));
  stdout.writeln(
    'Formatted ${file.path}: ${library.entries.length} entries, '
    '${library.plans.length} plans.',
  );
}
