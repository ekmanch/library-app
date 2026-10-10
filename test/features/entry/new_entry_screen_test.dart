import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/data/library_providers.dart';
import 'package:library_app/data/models/media_type.dart';
import 'package:library_app/data/repository/fixture_library_repository.dart';
import 'package:library_app/features/entry/new_entry_screen.dart';
import 'package:library_app/widgets/chips.dart';

import '../../helpers/pump_app.dart';

class _Opener extends StatelessWidget {
  const _Opener({this.type, this.title});
  final MediaType? type;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            final saved = await openNewEntryScreen(
              context,
              type: type,
              title: title,
            );
            if (saved != null && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Added ${saved.title}')));
            }
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  /// Rows titled [title]; the search field's own text does not count.
  Finder rowTitled(String title) =>
      find.byWidgetPredicate((w) => w is Text && w.data == title);

  /// Scrolls the chip row (lazy, so a far chip is not built yet) and taps.
  Future<void> pickChip(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(PillChip, label);
    final row = find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    );
    await tester.dragUntilVisible(chip, row, const Offset(-80, 0));
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  testWidgets('typing a title lists matches, filtered by the type chips', (
    tester,
  ) async {
    await pumpApp(tester, const _Opener());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('New entry'), findsOneWidget);
    expect(find.text('IS IT ONE OF THESE?'), findsNothing);
    expect(find.text('Fill in the details myself'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Carrie');
    await tester.pumpAndSettle();
    expect(find.text('IS IT ONE OF THESE?'), findsOneWidget);
    expect(rowTitled('Carrie'), findsNWidgets(4));
    expect(find.text('MOVIE · 1976'), findsOneWidget);
    expect(find.text('Brian De Palma'), findsOneWidget);
    expect(find.text('Not listed?'), findsOneWidget);

    await pickChip(tester, 'Books');
    expect(rowTitled('Carrie'), findsOneWidget);
    expect(find.text('BOOK · 1974'), findsOneWidget);

    await pickChip(tester, 'Games');
    expect(find.text('No matches for "Carrie".'), findsOneWidget);
    expect(find.text('Not listed?'), findsNothing);
  });

  testWidgets('a match opens the form prefilled and saving closes both', (
    tester,
  ) async {
    final container = await pumpApp(tester, const _Opener());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'akira');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANIME · 1988'));
    await tester.pumpAndSettle();
    expect(find.text('New entry'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Akira'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Katsuhiro Otomo'), findsOneWidget);
    expect(find.widgetWithText(TextField, '1988'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('New entry'), findsNothing);
    expect(find.text('Added Akira'), findsOneWidget);
    final repo =
        container.read(libraryRepositoryProvider) as FixtureLibraryRepository;
    expect(repo.current!.entries.last.id, 'anime/akira-1988');
  });

  testWidgets('"Fill in the details myself" keeps the title and type', (
    tester,
  ) async {
    await pumpApp(tester, const _Opener(type: MediaType.games, title: 'Zelda'));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('No matches for "Zelda".'), findsOneWidget);
    await tester.tap(find.text('Fill in the details myself'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Zelda'), findsOneWidget);
    expect(find.text('Platform'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Fill in the details myself'), findsOneWidget);
  });
}
