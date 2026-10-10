import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/widgets/app_buttons.dart';
import 'package:library_app/widgets/app_dialog.dart';
import 'package:library_app/widgets/sheet_frame.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('showAppSheet opens a sheet with a grabber and title', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showAppSheet<void>(
            context,
            builder: (_) =>
                const SheetFrame(title: 'Filters', child: Text('Body')),
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('showAppDialog returns the chosen action', (tester) async {
    bool? result;
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await showAppDialog<bool>(
              context,
              builder: (context) => AppDialog(
                title: 'Delete The Mummy?',
                body: 'It will be removed from your library.',
                actions: [
                  AppButton(
                    label: 'Cancel',
                    kind: AppButtonKind.outline,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  AppButton(
                    label: 'Delete',
                    kind: AppButtonKind.destructive,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete The Mummy?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(Dialog), findsNothing);
  });
}
