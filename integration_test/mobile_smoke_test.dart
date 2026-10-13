import 'package:air_quality_monitor/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android onboarding, navigation and theme', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    if (find.text('Продолжить').evaluate().isNotEmpty) {
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Продолжить'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Начать'));
      await tester.pumpAndSettle();
    }
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тёмная тема'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.text('Светлая тема'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('О загрязнителях'), 250);
    await tester.tap(find.text('О загрязнителях'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PM₂.₅'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Мелкие взвешенные'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
