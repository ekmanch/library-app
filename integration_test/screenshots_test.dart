// Captures the app for a visual check against the design canvas. Writes
// screenshots/<name>.png (git-ignored) from the app process. Run on the
// Linux dev target:
//
//   flutter test integration_test/screenshots_test.dart -d linux
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:library_app/features/settings/display_preferences.dart';
import 'package:library_app/main.dart' as app;

Future<void> capture(WidgetTester tester, String name) async {
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary),
  );
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('screenshots/$name.png');
  await file.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint('Wrote ${file.absolute.path}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shell in dark and light', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await capture(tester, 'shell-library-dark');

    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    await capture(tester, 'shell-plans-dark');

    final container = ProviderScope.containerOf(
      tester.element(find.text('Plans').first),
    );
    container
        .read(displayPreferencesProvider.notifier)
        .setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    await capture(tester, 'shell-plans-light');
  });
}
