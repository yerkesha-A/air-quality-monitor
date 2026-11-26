import 'dart:io';

import 'package:air_quality_monitor/data/local/local_store.dart';
import 'package:air_quality_monitor/data/remote/open_meteo_api.dart';
import 'package:air_quality_monitor/data/repositories/open_meteo_repository.dart';
import 'package:air_quality_monitor/data/services/device_service.dart';
import 'package:air_quality_monitor/data/services/location_service.dart';
import 'package:air_quality_monitor/main.dart' as app;
import 'package:air_quality_monitor/presentation/bloc/air_bloc.dart';
import 'package:air_quality_monitor/presentation/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'support/first_launch.dart' show completeFirstLaunch;
import 'support/sqlite_pagination.dart';

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  expect(ready(), isTrue, reason: 'Timed out waiting for live iOS data');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'iOS Swift channel, live API, SQLite, guest navigation and offline fallback',
    (tester) async {
      if (!Platform.isIOS ||
          !const bool.fromEnvironment('ALLOW_ISOLATED_IOS_TEST')) {
        throw StateError('Requires an explicitly isolated iOS QA Simulator');
      }
      final docs = await getApplicationDocumentsDirectory();
      if (!await File('${docs.path}/aqm_ios_test_device').exists()) {
        throw StateError('QA marker missing; refusing to change app state');
      }
      await app.main();
      await tester.pumpAndSettle();
      if (find.byType(HomeScreen).evaluate().isEmpty) {
        await completeFirstLaunch(tester);
      }
      final device = await const DeviceService().info();
      expect(device['platform'], 'iOS');
      expect(device['available'], isTrue);
      expect(device['model'], isNotEmpty);
      expect(device['firebaseConfigured'], isTrue);
      expect(device['googleIosClientId'], isNotEmpty);
      expect(Firebase.apps, isNotEmpty);
      await expectLater(
        const MethodChannel('air_quality_monitor/device')
            .invokeMethod<void>('unsupportedQaMethod'),
        throwsA(isA<MissingPluginException>()),
      );
      await tester.tap(find.byKey(const ValueKey('home-city-picker')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Алматы');
      await waitFor(
        tester,
        () => find.widgetWithText(ListTile, 'Алматы').evaluate().isNotEmpty,
      );
      await tester.tap(find.widgetWithText(ListTile, 'Алматы').first);
      await tester.pump();
      final home = tester.element(find.byType(HomeScreen));
      final bloc = home.read<AirBloc>();
      await waitFor(
        tester,
        () => !bloc.state.busy && bloc.state.report != null,
      );
      final report = bloc.state.report!;
      expect(report.offline, isFalse);
      expect(report.current.aqi, greaterThanOrEqualTo(0));
      final store = home.read<LocalStore>();
      expect(
        (await store.cached(report.place))?.current.aqi,
        report.current.aqi,
      );
      final offline = await OpenMeteoRepository(
        api: OpenMeteoApi(
          MockClient(
            (_) async => throw http.ClientException('QA network failure'),
          ),
        ),
        store: store,
        location: LocationService(),
      ).fetch(report.place);
      expect(offline.offline, isTrue);
      expect(offline.fetchedAt, report.fetchedAt);
      await binding.takeScreenshot('ios-home');
      final router = GoRouter.of(home);
      router.push('/notes');
      await tester.pumpAndSettle();
      final text = 'iOS QA ${DateTime.now().millisecondsSinceEpoch}';
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
      await tester.tap(find.text('Карта'));
      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      await binding.takeScreenshot('ios-map');
      await tester.tap(find.text('История'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('ios-history');
      await verifySqlitePagination();
      expect(
        (await store.database.rawQuery('PRAGMA integrity_check'))
            .first
            .values
            .first,
        'ok',
      );
      binding.reportData = {
        ...?binding.reportData,
        'platform': 'iOS Simulator',
        'liveApi': true,
        'nativeSwiftChannel': true,
        'nativeFirebaseInitialization': true,
        'googleCallbackConfigured': true,
        'sqliteIntegrity': 'ok',
        'offlineFallback': 'simulated network outage with real SQLite cache',
        'notesSaved': true,
        'sqlitePagination': true,
        'physicalCamera': 'not tested',
        'apns': 'not tested',
      };
      expect(tester.takeException(), isNull);
    },
  );
}
