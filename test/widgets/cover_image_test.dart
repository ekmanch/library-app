import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/dev/fake_lookup_overrides.dart';
import 'package:library_app/widgets/artist_photo.dart';
import 'package:library_app/widgets/cover_image.dart';
import 'package:library_app/widgets/cover_placeholder.dart';

import '../helpers/pump_app.dart';
import '../helpers/sample_library.dart';

/// Lets the resolver, the fake fetcher and the file write run (they work
/// off the real clock) until an image is in the tree, or 2 seconds pass.
Future<void> settleImages(WidgetTester tester) async {
  for (var i = 0; i < 40 && find.byType(Image).evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('shows the placeholder, then the fetched cover', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Center(child: CoverImage(entry: mummy, width: 60)),
      ),
    );
    expect(find.byType(CoverPlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await settleImages(tester);
    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 60);
    expect(image.height, 90);
    expect(image.excludeFromSemantics, isTrue);

    // Decoded, the cover replaces the placeholder.
    for (
      var i = 0;
      i < 40 && find.byType(CoverPlaceholder).evaluate().isNotEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(CoverPlaceholder), findsNothing);
  });

  testWidgets('a cover that cannot be fetched keeps the placeholder', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Center(child: CoverImage(entry: mummy, width: 60)),
      ),
      lookupOverrides: fakeLookupOverrides(
        failingImages: {'fake://cover/poster/fake:the-mummy'},
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.byType(CoverPlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('the details header names its cover', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Center(child: CoverImage(entry: mummy, width: 84, labeled: true)),
      ),
    );
    await settleImages(tester);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.semanticLabel, 'The Mummy');
    expect(image.excludeFromSemantics, isFalse);
  });

  testWidgets('an artist photo is round and skips Various Artists', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: Column(
          children: [
            ArtistPhoto(name: 'Alice in Chains', initials: 'AC', size: 48),
            ArtistPhoto(name: 'Various Artists', initials: 'VA', size: 48),
          ],
        ),
      ),
    );
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('VA'), findsOneWidget);
    await settleImages(tester);
    expect(find.byType(ClipOval), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('VA'), findsOneWidget);
  });
}
