import 'package:air_quality_monitor/app.dart';
import 'package:air_quality_monitor/presentation/providers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_dependencies.dart';

void main() {
  testWidgets('Onboarding persists completion and opens the mobile shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      AirQualityApp(settings: settings, dependencies: testDependencies()),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();
    expect(settings.onboarded, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('AIR'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-city-picker')), findsOneWidget);
    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Тёмная тема').hitTestable(),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Тёмная тема'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.dark);
    await tester.scrollUntilVisible(find.text('О загрязнителях'), 250);
    await tester.tap(find.text('О загрязнителях'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PM₂.₅'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Мелкие взвешенные'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Onboarding fits narrow and landscape screens with large text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(await SharedPreferences.getInstance());
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      AirQualityApp(settings: settings, dependencies: testDependencies()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(740, 360);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
