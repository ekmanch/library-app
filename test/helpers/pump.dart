import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/theme/app_theme.dart';

/// Whether the semantics node under [finder] is marked selected.
bool isSelected(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).flagsCollection.isSelected == Tristate.isTrue;

/// Pumps [child] inside a MaterialApp with the app theme.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: brightness),
      home: Scaffold(body: child),
    ),
  );
}
