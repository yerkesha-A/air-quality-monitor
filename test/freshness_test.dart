import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_dependencies.dart';

void main() {
  final now = DateTime.utc(2026, 10, 15, 18, 30);
  AirReport report(Duration modelAge, {Duration fetchedAge = Duration.zero}) =>
      AirReport(
        place: fixturePlace,
        current: AirPoint(time: now.subtract(modelAge), values: {'us_aqi': 70}),
        forecast: [],
        fetchedAt: now.subtract(fetchedAge),
      );
  test('Fresh download does not make old or future model data current', () {
    expect(report(const Duration(minutes: 90)).isStale(now), isFalse);
    expect(report(const Duration(hours: 3)).isStale(now), isTrue);
    expect(report(const Duration(hours: -2)).isStale(now), isTrue);
    expect(
      report(Duration.zero, fetchedAge: const Duration(hours: 2)).isStale(now),
      isTrue,
    );
    expect(
      report(
        Duration.zero,
        fetchedAge: const Duration(minutes: -10),
      ).isStale(now),
      isTrue,
    );
  });
  test(
    'Cached API error preserves model and download time with actual reason',
    () {
      final original = report(Duration.zero);
      final cache = original.asOffline(reason: 'HTTP 429');
      expect(cache.cacheLabel, contains('HTTP 429'));
      expect(cache.cacheLabel, isNot(contains('Нет интернета')));
      expect(cache.current.time, original.current.time);
      expect(cache.fetchedAt, original.fetchedAt);
    },
  );
}
