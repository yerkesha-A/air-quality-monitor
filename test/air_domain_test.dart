import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:air_quality_monitor/domain/usecases/air_advice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('US AQI category boundaries never mix European bands', () {
    final values = <double, AirBand>{
      0: AirBand.good,
      50: AirBand.good,
      51: AirBand.moderate,
      100: AirBand.moderate,
      101: AirBand.sensitive,
      150: AirBand.sensitive,
      151: AirBand.unhealthy,
      200: AirBand.unhealthy,
      201: AirBand.veryUnhealthy,
      300: AirBand.veryUnhealthy,
      301: AirBand.hazardous,
      600: AirBand.hazardous,
    };
    for (final entry in values.entries) {
      expect(AirBand.forAqi(entry.key), entry.value);
    }
    for (final invalid in [-1.0, double.nan, double.infinity]) {
      expect(() => AirBand.forAqi(invalid), throwsArgumentError);
    }
  });
  test(
    'Advisor handles missing and polluted data; best hour ignores null AQI',
    () {
      expect(AirAdvice.summary(null), contains('Данных пока нет'));
      for (final aqi in [20.0, 75.0, 120.0, 175.0, 250.0, 350.0]) {
        expect(AirAdvice.summary(aqi), isNotEmpty);
      }
      expect(AirAdvice.activity(null), 'Нужны данные');
      expect(AirAdvice.activity(180), 'Лучше в помещении');
      expect(AirAdvice.activity(80, intense: true), 'Снизьте нагрузку');
      expect(AirAdvice.activity(40), 'Подходящие условия');
      final now = DateTime.utc(2026, 10, 13);
      final points = [
        AirPoint(time: now, values: {'us_aqi': null}),
        AirPoint(
          time: now.add(const Duration(hours: 1)),
          values: {'us_aqi': 80},
        ),
        AirPoint(
          time: now.add(const Duration(hours: 2)),
          values: {'us_aqi': 35},
        ),
      ];
      expect(AirAdvice.bestHour(points), points.last);
      expect(AirAdvice.bestHour([]), isNull);
      expect(AirAdvice.average([null, double.nan]), isNull);
      expect(AirAdvice.average([2, null, 4]), 3);
    },
  );
  test(
    'Forecast uses absolute instants; city clock and stale cache stay explicit',
    () {
      const place = Place(
        id: '1',
        name: 'Алматы',
        latitude: 43.2,
        longitude: 76.9,
      );
      final now = DateTime.utc(2026, 10, 13, 5);
      final points = [
        for (final offset in [-1, 1, 23, 24, 25])
          AirPoint(
            time: now.add(Duration(hours: offset)),
            values: {'us_aqi': 30},
          ),
      ];
      final report = AirReport(
        place: place,
        current: points.first,
        forecast: points,
        fetchedAt: now,
        utcOffsetSeconds: 18000,
      );
      expect(report.upcoming(now).length, 2);
      expect(report.cityTime(now).hour, 10);
      expect(report.isStale(now.add(const Duration(minutes: 59))), isFalse);
      expect(report.isStale(now.add(const Duration(hours: 2))), isTrue);
      expect(report.asOffline().fetchedAt, now);
      expect(report.asOffline().offline, isTrue);
    },
  );
}
