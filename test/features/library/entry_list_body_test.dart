import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/entry.dart';
import 'package:library_app/data/models/released.dart';
import 'package:library_app/features/library/cover_grid_tile.dart';
import 'package:library_app/features/library/entry_list_body.dart';
import 'package:library_app/features/library/library_sort.dart';
import 'package:library_app/features/settings/entry_view.dart';
import 'package:library_app/theme/app_theme.dart';

import '../../helpers/sample_library.dart';

/// [count] movies spread over the decades from 1950 on, two per year.
List<Entry> longList(int count) => [
  for (var i = 0; i < count; i++)
    mummy.copyWith(
      id: 'movies/m$i',
      title: 'Movie $i',
      released: Released(1950 + i ~/ 2),
      added: DateTime(2026, 1, 1).add(Duration(days: i)),
    ),
];

Future<void> pumpBody(
  WidgetTester tester,
  List<Entry> entries, {
  LibrarySort sort = LibrarySort.yearNewest,
  EntryView view = EntryView.text,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.dark),
      home: Scaffold(
        body: EntryListBody(
          entries: sortEntries(entries, sort),
          sort: sort,
          view: view,
          color: Colors.amber,
          onTap: (_) {},
          today: DateTime(2026, 10, 10),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a short list has no headers and no rail', (tester) async {
    await pumpBody(tester, longList(12));
    expect(find.byKey(EntryListBody.railKey), findsNothing);
    expect(find.text('1950s'), findsNothing);
    expect(find.text('Movie 0'), findsOneWidget);
  });

  testWidgets('one section never gets a rail, however long', (tester) async {
    final sameDecade = [
      for (var i = 0; i < 90; i++)
        mummy.copyWith(
          id: 'movies/m$i',
          title: 'Movie $i',
          released: const Released(1999),
        ),
    ];
    await pumpBody(tester, sameDecade);
    expect(find.byKey(EntryListBody.railKey), findsNothing);
  });

  testWidgets('a long list gets decade headers and a rail that jumps', (
    tester,
  ) async {
    await pumpBody(tester, longList(150));
    expect(find.byKey(EntryListBody.railKey), findsOneWidget);
    expect(find.text('2020s'), findsOneWidget); // Decades keep their "s".
    expect(find.text('20s'), findsOneWidget);
    expect(find.text('Older'), findsOneWidget);
    expect(find.text('1990s'), findsNothing); // Far down, not built yet.

    await tester.tap(find.text('90s'));
    await tester.pumpAndSettle();
    expect(find.text('1990s'), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
    // The 1990s header sits at the top of the list.
    expect(tester.getTopLeft(find.text('1990s')).dy, lessThan(60));
  });

  testWidgets('scrolling moves the highlight to the section at the top', (
    tester,
  ) async {
    await pumpBody(tester, longList(150));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    Color? pillColor(String label) {
      final box = tester.widget<Container>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Container))
            .first,
      );
      return (box.decoration as BoxDecoration?)?.color;
    }

    final selected = LibraryColors.of(
      tester.element(find.byKey(EntryListBody.railKey)),
    ).selectedFill;
    expect(pillColor('20s'), selected);
    expect(pillColor('Older'), Colors.transparent);

    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(pillColor('Older'), selected);
    expect(pillColor('20s'), Colors.transparent);
  });

  testWidgets('the grid keeps no headers; the thumb shows a bubble on drag', (
    tester,
  ) async {
    await pumpBody(tester, longList(150), view: EntryView.grid);
    expect(find.byType(CoverGridTile), findsWidgets);
    expect(find.byKey(EntryListBody.railKey), findsNothing);
    // No header: the only "2020s" is the bubble, hidden until scrolling.
    expect(find.text('2020s'), findsOneWidget);
    final thumb = find.byKey(EntryListBody.thumbKey);
    expect(thumb, findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(of: thumb, matching: find.byType(AnimatedOpacity))
                .first,
          )
          .opacity,
      0,
    );

    // Scrolling the grid shows the thumb and the bubble for a moment.
    await tester.drag(find.byType(CoverGridTile).first, const Offset(0, -300));
    await tester.pump();
    double bubbleOpacity() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.text('2020s'),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    expect(bubbleOpacity(), 1);
    await tester.pump(const Duration(seconds: 2)); // The hide timer runs out.
    await tester.pumpAndSettle();
    expect(bubbleOpacity(), 0);

    // Drag the thumb zone to the bottom: the list follows and the bubble
    // names the last section.
    final gesture = await tester.startGesture(const Offset(370, 30));
    await tester.pump();
    await gesture.moveTo(const Offset(370, 830)); // Past the track's end.
    await tester.pump();
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
    expect(find.text('Older'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the grid does not overflow under a larger text scale', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpBody(tester, longList(30), view: EntryView.grid);
    expect(find.byType(CoverGridTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
