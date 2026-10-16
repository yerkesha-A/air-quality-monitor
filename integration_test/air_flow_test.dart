import 'support/first_launch.dart';
import 'support/sqlite_pagination.dart';

import 'package:air_quality_monitor/main.dart' as app;
import 'package:air_quality_monitor/data/local/local_store.dart';
import 'package:air_quality_monitor/data/remote/open_meteo_api.dart';
import 'package:air_quality_monitor/data/repositories/open_meteo_repository.dart';
import 'package:air_quality_monitor/data/services/device_service.dart';
import 'package:air_quality_monitor/data/services/location_service.dart';
import 'package:air_quality_monitor/data/services/notification_service.dart';
import 'package:air_quality_monitor/presentation/bloc/air_bloc.dart';
import 'package:air_quality_monitor/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';

Future<void> until(WidgetTester tester, bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (!predicate() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  expect(
    predicate(),
    isTrue,
    reason: 'Timed out waiting for real Android data',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'Live Android API, SQLite offline fallback, notes and native channel',
    (tester) async {
      await prepareFirstLaunch();
      await app.main();
      await tester.pumpAndSettle();
      await completeFirstLaunch(tester);
      await tester.tap(find.byKey(const ValueKey('home-city-picker')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Алматы');
      await until(
        tester,
        () => find.widgetWithText(ListTile, 'Алматы').evaluate().isNotEmpty,
      );
      await tester.tap(find.widgetWithText(ListTile, 'Алматы').first);
      await tester.pump();
      final home = tester.element(find.byType(HomeScreen));
      final bloc = home.read<AirBloc>();
      await until(tester, () => !bloc.state.busy && bloc.state.report != null);
      final report = bloc.state.report!;
      expect(
        report.offline,
        isFalse,
        reason: 'This acceptance test must load the live API',
      );
      expect(report.current.aqi, greaterThanOrEqualTo(0));
      expect(report.forecast, isNotEmpty);
      final store = home.read<LocalStore>();
      final samples = await store.history(report.place, 1);
      expect(samples.any((p) => p.time == report.current.time), isTrue);
      final cached = await store.cached(report.place);
      expect(cached!.current.aqi, report.current.aqi);
      final offlineRepository = OpenMeteoRepository(
        api: OpenMeteoApi(
          MockClient(
            (_) async => throw http.ClientException('Test network outage'),
          ),
        ),
        store: store,
        location: LocationService(),
      );
      final offline = await offlineRepository.fetch(report.place);
      expect(offline.offline, isTrue);
      expect(offline.fetchedAt, report.fetchedAt);
      final device = await DeviceService().info();
      expect(device['sdk'], greaterThanOrEqualTo(24));
      expect(device['model'], isNotEmpty);
      expect(device['firebaseConfigured'], isA<bool>());
      final router = GoRouter.of(home);
      router.push('/notes');
      await tester.pumpAndSettle();
      final text =
          'Проверка заметки на Android ${DateTime.now().millisecondsSinceEpoch}';
      await tester.enterText(find.byType(TextField), text);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Сохранить').hitTestable(),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(
        (await store.notes(report.place)).any((row) => row['text'] == text),
        isTrue,
      );
      router.pop();
      await tester.pumpAndSettle();
      await home.read<NotificationService>().show(
        id: 'android-acceptance-test',
        title: 'Проверка Air Quality',
        body:
            'Нативное уведомление Android. ${report.place.name}: ${report.current.aqi!.round()} US AQI.',
        source: 'test',
      );
      expect(
        (await store.alerts()).any((row) => row['source'] == 'test'),
        isTrue,
      );
      await verifySqlitePagination();
      expect(tester.takeException(), isNull);
    },
  );
}
