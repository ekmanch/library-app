import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/app_info.dart';

void main() {
  test('appVersion matches the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final line = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!;
    expect(line.split('+').first, appVersion);
  });
}
