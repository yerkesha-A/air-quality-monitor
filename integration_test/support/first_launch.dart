import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> requireIsolatedAndroid() async {
  if (!const bool.fromEnvironment('ALLOW_ISOLATED_ANDROID_TEST')) {
    throw StateError(
      'First-launch scenarios require an explicitly isolated QA AVD',
    );
  }
  final docs = await getApplicationDocumentsDirectory();
  if (!await File('${docs.path}/aqm_test_device').exists()) {
    throw StateError(
      'Refuse to change onboarding without the QA device marker',
    );
  }
}

Future<void> prepareFirstLaunch() async {
  await requireIsolatedAndroid();
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
