import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/features/settings/connection_screen.dart';
import 'package:library_app/features/sync/sync_banner.dart';
import 'package:library_app/features/sync/sync_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('nothing is shown without a banner', (tester) async {
    await pumpApp(tester, const Scaffold(body: SyncBannerCard()));
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('each banner has its text and button', (tester) async {
    final container = await pumpApp(
      tester,
      const Scaffold(body: SyncBannerCard()),
    );
    final notifier = container.read(syncBannerProvider.notifier);

    notifier.show(SyncBanner.saving);
    await tester.pumpAndSettle();
    expect(find.text('Saving your change'), findsOneWidget);
    expect(find.text('Sending it to GitHub.'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);

    notifier.show(SyncBanner.offline);
    await tester.pumpAndSettle();
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);

    notifier.show(SyncBanner.couldNotSave);
    await tester.pumpAndSettle();
    expect(find.text('Could not save to GitHub'), findsOneWidget);
    expect(find.text('Your change is kept on this phone.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    notifier.show(SyncBanner.tokenProblem);
    await tester.pumpAndSettle();
    expect(find.text('GitHub refused the token'), findsOneWidget);
    expect(find.text('It may have expired.'), findsOneWidget);
    expect(find.text('Fix'), findsOneWidget);
  });

  testWidgets('Retry clears the banner and Fix opens the connection', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      const Scaffold(body: SyncBannerCard()),
    );
    final notifier = container.read(syncBannerProvider.notifier);
    notifier.show(SyncBanner.couldNotSave);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(container.read(syncBannerProvider), isNull);
    expect(find.text('Could not save to GitHub'), findsNothing);

    notifier.show(SyncBanner.tokenProblem);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fix'));
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionScreen), findsOneWidget);
  });

  test('the SYNC_BANNER dart-define names map to banners', () {
    expect(SyncBanner.fromDemo('saving'), SyncBanner.saving);
    expect(SyncBanner.fromDemo('offline'), SyncBanner.offline);
    expect(SyncBanner.fromDemo('failed'), SyncBanner.couldNotSave);
    expect(SyncBanner.fromDemo('token'), SyncBanner.tokenProblem);
    expect(SyncBanner.fromDemo(''), isNull);
  });
}
