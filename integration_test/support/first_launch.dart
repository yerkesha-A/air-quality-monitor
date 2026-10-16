import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> prepareFirstLaunch() async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setBool('onboarded', false);
}

Future<void> completeFirstLaunch(WidgetTester tester) async {
  expect(find.byKey(const ValueKey('welcome-hero')), findsOneWidget);
  await Scrollable.ensureVisible(
    tester.element(find.text('Начать')),
    alignment: .5,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Начать'));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('welcome-choices')), findsOneWidget);
  await Scrollable.ensureVisible(
    tester.element(find.text('Продолжить без аккаунта')),
    alignment: .5,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Продолжить без аккаунта'));
  await tester.pumpAndSettle();
  expect(find.byType(NavigationBar), findsOneWidget);
  expect((await SharedPreferences.getInstance()).getBool('onboarded'), isTrue);
}
