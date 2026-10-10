import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/features/shell/app_shell.dart';
import 'package:library_app/features/shell/floating_nav_bar.dart';
import 'package:library_app/theme/app_theme.dart';

import '../../helpers/pump.dart';

class _Home extends StatelessWidget {
  const _Home(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  Scaffold(body: Center(child: Text('$name detail'))),
            ),
          ),
          child: Text('$name home'),
        ),
      ),
    );
  }
}

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    void Function(BuildContext)? onAddEntry,
    void Function(BuildContext)? onAddPlan,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.dark),
        home: AppShell(
          libraryHome: const _Home('Library'),
          plansHome: const _Home('Plans'),
          onAddEntry: onAddEntry,
          onAddPlan: onAddPlan,
        ),
      ),
    );
  }

  testWidgets('starts on Library and switches to Plans', (tester) async {
    await pumpShell(tester);
    expect(find.text('Library home'), findsOneWidget);
    expect(find.text('Plans home').hitTestable(), findsNothing);
    expect(isSelected(tester, find.text('Library')), isTrue);

    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    expect(find.text('Plans home').hitTestable(), findsOneWidget);
    expect(isSelected(tester, find.text('Plans')), isTrue);
  });

  testWidgets('the + button changes label and callback per tab', (
    tester,
  ) async {
    final calls = <String>[];
    await pumpShell(
      tester,
      onAddEntry: (_) => calls.add('entry'),
      onAddPlan: (_) => calls.add('plan'),
    );
    expect(find.byTooltip('New entry'), findsOneWidget);
    await tester.tap(find.byType(AddButton));
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('New plan'), findsOneWidget);
    await tester.tap(find.byType(AddButton));
    expect(calls, ['entry', 'plan']);
  });

  testWidgets('the navigation stays visible on pushed screens', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('Library home'));
    await tester.pumpAndSettle();
    expect(find.text('Library detail'), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });

  testWidgets('back pops inside the tab, then returns to Library', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plans home'));
    await tester.pumpAndSettle();
    expect(find.text('Plans detail'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Plans detail'), findsNothing);
    expect(find.text('Plans home').hitTestable(), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Library home').hitTestable(), findsOneWidget);
  });

  testWidgets('tapping the current tab pops to its root', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('Library home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Library detail'), findsNothing);
    expect(find.text('Library home'), findsOneWidget);
  });
}
