import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:library_app/main.dart' as app;

// Run on the Linux dev target: flutter test integration_test -d linux
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches and loads the bundled fixture', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.textContaining('entries'), findsOneWidget);
  });
}
