import 'dart:convert';
import 'dart:io';

import 'package:air_quality_monitor/main.dart' as app;
import 'package:air_quality_monitor/data/services/device_service.dart';
import 'package:air_quality_monitor/data/services/location_service.dart';
import 'package:air_quality_monitor/presentation/screens/home_screen.dart';
import 'package:air_quality_monitor/presentation/widgets/aqi_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

Future<void> waitFor(WidgetTester tester, bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 90));
  while (!condition() && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  expect(condition(), isTrue, reason: 'Native map/API operation timed out');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Real Android OSM tiles, report marker, attribution, disk cache and GPS',
    (tester) async {
      expect(const bool.fromEnvironment('ALLOW_ISOLATED_RK2_TEST'), isTrue);
      final docs = await getApplicationDocumentsDirectory();
      expect(
        await File('${docs.path}/rk2_isolated').exists(),
        isTrue,
        reason:
            'Refuse to run on a primary AVD without an isolated-test marker',
      );
      await app.main();
      await waitFor(
        tester,
        () => find.byType(HomeScreen).evaluate().isNotEmpty,
      );
      final context = tester.element(find.byType(HomeScreen));
      GoRouter.of(context).go('/map');
      await waitFor(
        tester,
        () => find.byType(AqiMapBadge).evaluate().isNotEmpty,
      );
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        find.text('© OpenStreetMap contributors').hitTestable(),
        findsOneWidget,
      );
      final badge = tester
          .widgetList<AqiMapBadge>(find.byType(AqiMapBadge))
          .first;
      expect(badge.report.current.aqi, greaterThanOrEqualTo(0));
      await tester.tap(
        find.byKey(ValueKey('map-marker-${badge.report.place.id}')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('${badge.report.current.aqi!.round()} US AQI'),
        findsOneWidget,
      );
      final cache = Directory(
        '${(await getApplicationCacheDirectory()).path}/fm_cache',
      );
      var tileCount = 0;
      await tester.runAsync(() async {
        for (var i = 0; i < 30; i++) {
          if (await cache.exists()) {
            final tiles = await cache
                .list()
                .where((f) => f is File && !f.path.endsWith('sizeMonitor.bin'))
                .toList();
            for (final file in tiles) {
              final bytes = await (file as File).readAsBytes();
              if (bytes.length > 30 &&
                  bytes.take(6).join(',') == '70,77,66,73,67,84') {
                tileCount++;
              }
            }
          }
          if (tileCount > 0) return;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      });
      expect(
        tileCount,
        greaterThan(0),
        reason: 'Actual downloaded OSM tile files must exist',
      );
      final device = await const DeviceService().info();
      expect(device['available'], isTrue);
      Map<String, Object?>? gps;
      if (const bool.fromEnvironment('VERIFY_EMULATOR_GPS')) {
        final position = await tester.runAsync(
          () => LocationService().locate(),
        );
        expect(position, isNotNull);
        expect(position!.latitude, closeTo(43.25249, .02));
        expect(position.longitude, closeTo(76.9115, .02));
        gps = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'source': 'emulator geo fix',
        };
      }
      await File('${docs.path}/rk2-map-verification.json').writeAsString(
        jsonEncode({
          'mapWidget': true,
          'attributionVisible': true,
          'tileCacheFiles': tileCount,
          'aqi': badge.report.current.aqi,
          'pm25': badge.report.current.values['pm2_5'],
          'pm10': badge.report.current.values['pm10'],
          'fetchedAt': badge.report.fetchedAt.toIso8601String(),
          'source': 'Open-Meteo/CAMS',
          'sdk': device['sdk'],
          'gps': gps,
          'physicalDevice': false,
        }),
      );
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
