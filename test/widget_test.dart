// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wask_app/main.dart';
import 'package:wask_app/features/shared/providers/app_state_provider.dart';

void main() {
  testWidgets('Wask app loads tracking screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final appStateProvider = await AppStateProvider.create();

    // Build our app and trigger a frame.
    await tester.pumpWidget(WaskApp(appStateProvider: appStateProvider));

    expect(find.text('INICIAR SESION'), findsOneWidget);
    expect(find.text('WAS-K'), findsOneWidget);
  });
}
