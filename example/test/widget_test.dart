// Smoke test: the app builds and lands on the Home screen.
//
// Platform channels are not registered under flutter_test, so the startup
// configure() and Home's isAuthenticated() both fail and are swallowed by
// their own error handling — which is itself worth covering, since a throw
// escaping either one would break launch on a real device too.

import 'package:flutter_test/flutter_test.dart';

import 'package:sahha_flutter_example/main.dart';
import 'package:sahha_flutter_example/services/stress_lab.dart';

void main() {
  testWidgets('App builds and shows the Home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(App(settings: StressLabSettings.defaults()));
    await tester.pump();

    expect(find.text('Sahha Demo'), findsOneWidget);
    expect(find.text('Stress Lab'), findsOneWidget);
  });
}
