import 'support/first_launch.dart';

import 'package:air_quality_monitor/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('Android onboarding, navigation and theme', (tester) async {
    await prepareFirstLaunch();
    await app.main();
    await tester.pumpAndSettle();
    await completeFirstLaunch(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Тёмная тема').hitTestable(),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Тёмная тема'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Светлая тема')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    expect(find.text('Светлая тема').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Светлая тема'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.light,
    );
    await tester.scrollUntilVisible(
      find.text('О загрязнителях').hitTestable(),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('О загрязнителях'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PM₂.₅'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Мелкие взвешенные'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
