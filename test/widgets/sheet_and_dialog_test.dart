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

  /// A text field with the focus, and a button that opens [open].
  Future<void> pumpFocused(
    WidgetTester tester,
    Future<void> Function(BuildContext context) open,
  ) async {
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => Column(
          children: [
            const TextField(autofocus: true),
            TextButton(
              onPressed: () => open(context),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  bool fieldFocused(WidgetTester tester) => tester
      .widget<EditableText>(find.byType(EditableText).first)
      .focusNode
      .hasFocus;

  testWidgets('a sheet takes the focus off a text field for good', (
    tester,
  ) async {
    await pumpFocused(
      tester,
      (context) => showAppSheet<void>(
        context,
        builder: (context) => SheetFrame(
          title: 'Pick',
          action: AppButton(
            label: 'Done',
            compact: true,
            onPressed: () => Navigator.pop(context),
          ),
          child: const Text('Body'),
        ),
      ),
    );
    expect(fieldFocused(tester), isFalse);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    // The field does not take the focus (and the keyboard) back.
    expect(fieldFocused(tester), isFalse);
  });

  testWidgets('a dialog takes the focus off a text field for good', (
    tester,
  ) async {
    await pumpFocused(
      tester,
      (context) => showAppDialog<void>(
        context,
        builder: (context) => AppDialog(
          title: 'Sure?',
          actions: [
            AppButton(label: 'OK', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
    expect(fieldFocused(tester), isFalse);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(fieldFocused(tester), isFalse);
  });
}
