import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/models/entry_status.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/data/models/music_kind.dart';
import 'package:library_app/data/models/released.dart';
import 'package:library_app/widgets/app_icons.dart';
import 'package:library_app/widgets/entry_row.dart';

import '../helpers/pump.dart';
import '../helpers/sample_library.dart';

void main() {
  final today = DateTime(2026, 10, 10);

  group('entrySubtitle', () {
    test('is the year for movies, shows, games and anime', () {
      expect(entrySubtitle(mummy, today: today), '1999');
      expect(
        entrySubtitle(mummy.copyWith(type: MediaType.anime), today: today),
        '1999',
      );
    });

    test('is creator and year for books and albums', () {
      final book = mummy.copyWith(type: MediaType.books, creator: 'Anne Rice');
      expect(entrySubtitle(book, today: today), 'Anne Rice · 1999');
      expect(entrySubtitle(dirt, today: today), 'Alice in Chains · 1992');
    });

    test('is album and year for a song, falling back to the artist', () {
      final song = dirt.copyWith(kind: MusicKind.song, album: 'Facelift');
      expect(entrySubtitle(song, today: today), 'Facelift · 1992');
      final single = dirt.copyWith(kind: MusicKind.song, album: null);
      expect(entrySubtitle(single, today: today), 'Alice in Chains · 1992');
    });

    test('says Not released yet while the date is ahead', () {
      final coming = mummy.copyWith(released: const Released(2027));
      expect(entrySubtitle(coming, today: today), 'Not released yet');
      expect(entrySubtitle(coming, today: DateTime(2028)), '2027');
    });

    test('leaves out missing parts', () {
      expect(entrySubtitle(mummy.copyWith(released: null), today: today), '');
      final book = mummy.copyWith(type: MediaType.books, creator: null);
      expect(entrySubtitle(book, today: today), '1999');
    });
  });

  group('StatusMark', () {
    testWidgets('Done shows an accent check with a label', (tester) async {
      await pumpThemed(tester, const StatusMark(EntryStatus.done));
      expect(find.bySemanticsLabel('Done'), findsOneWidget);
      final icon = tester.widget<StrokeIcon>(find.byType(StrokeIcon));
      expect(icon.data, AppIcons.check);
      expect(
        icon.color,
        Theme.of(tester.element(find.byType(StrokeIcon))).colorScheme.primary,
      );
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('other statuses show the word in a pill', (tester) async {
      await pumpThemed(tester, const StatusMark(EntryStatus.inProgress));
      expect(find.text('In progress'), findsOneWidget);
      await pumpThemed(tester, const StatusMark(EntryStatus.dnf));
      expect(find.text('DNF'), findsOneWidget);
      expect(find.byType(StrokeIcon), findsNothing);
    });
  });

  testWidgets('EntryRow.forEntry shows title, italic subtitle and mark', (
    tester,
  ) async {
    var taps = 0;
    await pumpThemed(
      tester,
      EntryRow.forEntry(mummy, today: today, onTap: () => taps++),
    );
    expect(find.text('The Mummy'), findsOneWidget);
    final subtitle = tester.widget<Text>(find.text('1999'));
    TextSpan? yearSpan;
    subtitle.textSpan!.visitChildren((span) {
      if (span is TextSpan && span.text == '1999') yearSpan = span;
      return true;
    });
    expect(yearSpan?.style?.fontStyle, FontStyle.italic);
    expect(
      find.byWidgetPredicate(
        (w) => w is StrokeIcon && w.semanticLabel == 'Done',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('The Mummy'));
    expect(taps, 1);
  });
}
