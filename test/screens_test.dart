import 'package:air_quality_monitor/app.dart';
import 'package:air_quality_monitor/core/di/app_dependencies.dart';
import 'package:air_quality_monitor/presentation/bloc/air_bloc.dart';
import 'package:air_quality_monitor/presentation/providers/settings_controller.dart';
import 'package:air_quality_monitor/presentation/screens/home_screen.dart';
import 'package:air_quality_monitor/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_dependencies.dart';

import 'package:air_quality_monitor/presentation/widgets/air_chart.dart';

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
      final chart = find.descendant(
        of: find.byType(AirChart),
        matching: find.byType(CustomPaint),
      );
      await tester.scrollUntilVisible(
        chart.hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(chart);
      await tester.pump();
      expect(
        find.text('Коснитесь графика, чтобы увидеть значение'),
        findsNothing,
      );
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
      await tab(tester, 'Сегодня');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-city-picker')).hitTestable(),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('home-city-picker')));
      await tester.pumpAndSettle();
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
      await tab(tester, 'Сегодня');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-city-picker')).hitTestable(),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('home-city-picker')));
      await tester.pumpAndSettle();
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
  testWidgets(
    'Home city sheet searches, saves favorite, selects and resets on reopen',
    (tester) async {
      final (_, dependencies) = await start(tester, selected: false);
      await tester.tap(find.byKey(const ValueKey('home-city-picker')));
      await tester.pumpAndSettle();
      expect(find.text('Выберите город'), findsOneWidget);
      expect(find.byType(NavigationBar).hitTestable(), findsNothing);
      expect(find.text('Моё местоположение'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Алматы');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('В избранное'));
      await tester.pumpAndSettle();
      verify(() => dependencies.places.setFavorite(fixturePlace, true))
          .called(1);
      await tester.tap(find.widgetWithText(ListTile, 'Алматы'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(
        tester
            .element(find.byType(HomeScreen))
            .read<AirBloc>()
            .state
            .report
            ?.place
            .id,
        fixturePlace.id,
      );
      await tester.tap(find.byKey(const ValueKey('home-city-picker')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.tap(find.byTooltip('Закрыть выбор города'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'City sheet fits narrow screen with large text and keyboard inset',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);
      await start(tester);
      await tester.tap(find.byKey(const ValueKey('home-city-picker')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Алматы');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(ListTile, 'Алматы'), findsOneWidget);
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
  testWidgets(
    'Four tabs, removed cities route and real empty history fit narrow large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const channel = MethodChannel('air_quality_monitor/device');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => {'mapsConfigured': false},
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final (_, dependencies) = await start(tester);
      expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .destinations
            .length,
        4,
      );
      expect(find.text('Города'), findsNothing);
      await tab(tester, 'Карта');
      await tab(tester, 'История');
      expect(find.text('Первая точка уже сохранена'), findsOneWidget);
      await tester.tap(find.text('30 дней'));
      await tester.pumpAndSettle();
      verify(() => dependencies.air.history(fixturePlace, 30)).called(1);
      await tester.scrollUntilVisible(
        find.text('Календарь воздуха').hitTestable(),
        140,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tab(tester, 'Профиль');
      final router = GoRouter.of(tester.element(find.byType(ProfileScreen)));
      router.go('/cities');
      await tester.pumpAndSettle();
      expect(find.text('Страница не найдена'), findsOneWidget);
    },
  );
  testWidgets(
    'Auth form validates email, required name and registration password before SDK submission',
    (tester) async {
      await start(tester);
      GoRouter.of(tester.element(find.byType(HomeScreen))).go('/login');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalid-email',
      );
      expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Введите корректный email'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Нет аккаунта? Зарегистрироваться').hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Пароль'),
        'short',
      );
      expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Минимум 8 символов'), findsOneWidget);
      expect(find.text('Введите имя'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Имя'), 'Имя');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'person@example.test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Пароль'),
        'a-password',
      );
      expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Registration fields accept edits, Next changes focus and Done dismisses keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);
      await start(tester);
      GoRouter.of(tester.element(find.byType(HomeScreen))).go('/login');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Нет аккаунта? Зарегистрироваться').hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.enterText(find.widgetWithText(TextFormField, 'Имя'), 'Имя');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      final email = find.descendant(
        of: find.widgetWithText(TextFormField, 'Email'),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(email).focusNode.hasFocus, isTrue);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'person@example.test',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), '');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'person@example.test',
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      final password = find.descendant(
        of: find.widgetWithText(TextFormField, 'Пароль'),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(password).focusNode.hasFocus, isTrue);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Пароль'),
        'a-password',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(password).focusNode.hasFocus, isFalse);
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
