import 'package:air_quality_monitor/app.dart';
import 'package:air_quality_monitor/presentation/providers/settings_controller.dart';
import 'package:air_quality_monitor/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_dependencies.dart';

void main() {
  for (final size in [
    const Size(375, 667),
    const Size(393, 852),
    const Size(852, 393),
  ]) {
    testWidgets(
      'iPhone layout $size respects insets, keyboard and both themes',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        final portrait = size.height > size.width;
        tester.view.padding = FakeViewPadding(
          top: portrait ? 59 : 0,
          bottom: 34,
          left: portrait ? 0 : 59,
          right: portrait ? 0 : 59,
        );
        tester.view.viewPadding = tester.view.padding;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        SharedPreferences.setMockInitialValues({'onboarded': true});
        final settings = SettingsController(
          await SharedPreferences.getInstance(),
        );
        await tester.pumpWidget(
          AirQualityApp(
            settings: settings,
            dependencies: testDependencies(selected: true),
          ),
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
        for (final theme in [ThemeMode.light, ThemeMode.dark]) {
          await settings.setTheme(theme);
          for (final route in [
            '/',
            '/map',
            '/history',
            '/profile',
            '/alerts',
            '/notes',
            '/login',
            '/login?mode=register',
          ]) {
            router.go(route);
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$route, $theme, $size',
            );
            if (route.startsWith('/login')) {
              tester.view.viewInsets = FakeViewPadding(
                bottom: portrait ? 300 : 160,
              );
              tester.view.padding = FakeViewPadding(
                top: portrait ? 59 : 0,
                left: portrait ? 0 : 59,
                right: portrait ? 0 : 59,
              );
              await tester.pumpAndSettle();
              await tester.scrollUntilVisible(
                find.widgetWithText(TextFormField, 'Email'),
                100,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.pumpAndSettle();
              await tester.tap(find.widgetWithText(TextFormField, 'Email'));
              await tester.enterText(
                find.widgetWithText(TextFormField, 'Email'),
                'test@example.test',
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: 'keyboard $size');
              tester.testTextInput.hide();
              FocusManager.instance.primaryFocus?.unfocus();
              tester.view.resetViewInsets();
              tester.view.padding = tester.view.viewPadding;
              await tester.pumpAndSettle();
            }
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
