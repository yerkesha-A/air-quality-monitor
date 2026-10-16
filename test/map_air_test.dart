import 'dart:async';

import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:air_quality_monitor/domain/repositories/air_repository.dart';
import 'package:air_quality_monitor/presentation/controllers/map_air_controller.dart';
import 'package:air_quality_monitor/presentation/widgets/aqi_marker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Air extends Mock implements AirRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 16, 12);
  setUpAll(() => registerFallbackValue(MapAirController.point(43, 76)));
  AirReport report(Place place) => AirReport(
    place: place,
    current: AirPoint(time: now, values: {'us_aqi': 301, 'pm2_5': 12}),
    forecast: [],
    fetchedAt: now,
  );
  late _Air air;
  setUp(() {
    air = _Air();
    when(() => air.cached(any())).thenAnswer((_) async => null);
    when(() => air.fetch(any())).thenAnswer(
      (invocation) async =>
          report(invocation.positionalArguments.first as Place),
    );
  });
  test(
    'Real coordinate sampling is bounded, snaps to model grid and reuses cache',
    () async {
      final model = MapAirController(air, clock: () => now);
      addTearDown(model.dispose);
      await model.select(43.251, 76.951);
      expect(model.reports.length, 5);
      verify(() => air.fetch(any())).called(5);
      await model.select(43.252, 76.952);
      verifyNever(() => air.fetch(any()));
      expect(model.reports.first.place.latitude, 43.25);
      expect(MapAirController.point(90, 181).longitude, -179);
      await model.refresh(43.25, 76.95);
      verify(() => air.fetch(any())).called(5);
    },
  );
  test('Failures are honest empty state, no made-up values', () async {
    when(() => air.fetch(any())).thenThrow(const AirFailure('API error'));
    final model = MapAirController(air, clock: () => now);
    addTearDown(model.dispose);
    await model.refresh(43, 76);
    expect(model.reports, isEmpty);
    expect(model.error, contains('Нет данных'));
    expect(model.loading, isFalse);
  });
  test('Rapid moves debounce and obsolete results do not overwrite the last center', () async {
    final model = MapAirController(
      air,
      debounce: const Duration(milliseconds: 10),
      clock: () => now,
    );
    addTearDown(model.dispose);
    for (var i = 0; i < 100; i++) {
      model.schedule(43 + i * .01, 76);
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verify(() => air.fetch(any())).called(5);
    expect(model.reports.first.place.latitude, 44);
  });
  test('Network fetches are serialized during camera movement and discard stale generation', () async {
    final gate = Completer<AirReport>();
    when(() => air.fetch(any())).thenAnswer((i) async {
      final place = i.positionalArguments.first as Place;
      if (place.id == MapAirController.point(43, 76).id) return gate.future;
      return report(place);
    });
    final model = MapAirController(air, clock: () => now);
    addTearDown(model.dispose);
    final first = model.select(43, 76);
    await Future<void>.delayed(Duration.zero);
    final second = model.select(50, 80);
    gate.complete(report(MapAirController.point(43, 76)));
    expect(await first, isNull);
    expect((await second)!.place.latitude, 50);
  });
  test(
    'Raster marker handles all AQI categories and absent PM values',
    () async {
      for (final value in [0.0, 51.0, 101.0, 151.0, 201.0, 301.0]) {
        final sample = AirReport(
          place: MapAirController.point(43, 76),
          current: AirPoint(time: now, values: {'us_aqi': value}),
          forecast: [],
          fetchedAt: now,
        );
        expect(await aqiMarker(sample, 'us_aqi'), isNotNull);
        expect(await aqiMarker(sample, 'pm10'), isNotNull);
      }
    },
  );
}
