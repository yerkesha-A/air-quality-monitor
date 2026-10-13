import 'package:air_quality_monitor/app.dart';
import 'package:air_quality_monitor/core/di/app_dependencies.dart';
import 'package:air_quality_monitor/presentation/bloc/air_bloc.dart';
import 'package:air_quality_monitor/presentation/providers/settings_controller.dart';
import 'package:air_quality_monitor/presentation/screens/home_screen.dart';
import 'package:air_quality_monitor/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_dependencies.dart';

Future<(SettingsController, AppDependencies)> start(
  WidgetTester tester, {
  bool selected = true,
}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true});
  final settings = SettingsController(await SharedPreferences.getInstance());
  final dependencies = testDependencies(selected: selected);
  await tester.pumpWidget(
    AirQualityApp(settings: settings, dependencies: dependencies),
  );
  await tester.pumpAndSettle();
  return (settings, dependencies);
}

Future<void> tab(WidgetTester tester, String name) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Dashboard, forecast touch, recommendations, history and comparison',
    (tester) async {
      await start(tester);
      final bloc = tester.element(find.byType(HomeScreen)).read<AirBloc>();
      expect(bloc.state.status, LoadStatus.success);
      await tester.scrollUntilVisible(
        find.text('Коснитесь графика, чтобы увидеть значение'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Коснитесь графика, чтобы увидеть значение'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Все рекомендации →').hitTestable(),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Все рекомендации →'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Чувствительные группы'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Чувствительные группы'), findsOneWidget);
      GoRouter.of(tester.element(find.text('Рекомендации'))).pop();
      await tester.pumpAndSettle();
      await tab(tester, 'История');
      await tester.tap(find.text('7 дней'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PM₂.₅'));
      await tester.pumpAndSettle();
      expect(find.text('Среднее'), findsOneWidget);
      await tab(tester, 'Города');
      await tester.tap(find.byTooltip('Сравнить города'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сравнить воздух'));
      await tester.pumpAndSettle();
      expect(find.text('42 US AQI'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Debounced city search, favorite action and selection load actual repository',
    (tester) async {
      final (_, dependencies) = await start(tester, selected: false);
      await tab(tester, 'Города');
      await tester.enterText(find.byType(TextField), 'Алматы');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('В избранное'));
      await tester.pumpAndSettle();
      verify(() => dependencies.places.setFavorite(fixturePlace, true))
          .called(1);
      await tester.tap(find.widgetWithText(ListTile, 'Алматы'));
      await tester.pumpAndSettle();
      expect(
        tester.element(find.byType(HomeScreen)).read<AirBloc>().state.report,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Alert threshold, consent and persistence work', (tester) async {
    final (settings, _) = await start(tester);
    await tester.tap(find.byTooltip('Предупреждения'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(settings.threshold, greaterThan(100));
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(settings.alertsEnabled, isTrue);
    await tester.scrollUntilVisible(
      find.text('Предупреждений пока не было.'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Предупреждений пока не было.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Protected profile redirects to real login; missing configuration is explicit',
    (tester) async {
      await start(tester);
      await tab(tester, 'Профиль');
      final router = GoRouter.of(tester.element(find.byType(ProfileScreen)));
      router.go('/account');
      await tester.pumpAndSettle();
      expect(find.text('С возвращением'), findsOneWidget);
      expect(
        find.textContaining('Сервис аккаунтов ещё не подключён'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Нет аккаунта? Зарегистрироваться'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Начните с себя'),
        -180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Начните с себя'), findsOneWidget);
      router.go('/does-not-exist');
      await tester.pumpAndSettle();
      expect(find.text('Страница не найдена'), findsOneWidget);
      await tester.tap(find.text('На главную'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Notes persist text via local storage and privacy is reachable', (
    tester,
  ) async {
    final (_, dependencies) = await start(tester);
    when(() => dependencies.store.addNote(fixturePlace, 'Дым у дороги', null))
        .thenAnswer((_) async => 1);
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.push('/notes');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Дым у дороги');
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Сохранить'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    verify(() => dependencies.store.addNote(fixturePlace, 'Дым у дороги', null))
        .called(1);
    router.go('/privacy');
    await tester.pumpAndSettle();
    expect(find.text('На устройстве'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Dashboard fits 320 px and enlarged text, including hourly cards',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await start(tester);
      await tester.scrollUntilVisible(
        find.text('Состав воздуха'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Notification tap preserves a route back to the dashboard', (
    tester,
  ) async {
    final (_, dependencies) = await start(tester);
    dependencies.notifications.onOpen!('/alerts');
    await tester.pumpAndSettle();
    expect(find.text('Будьте в курсе'), findsOneWidget);
    await tester.tap(find.byTooltip('Назад'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
