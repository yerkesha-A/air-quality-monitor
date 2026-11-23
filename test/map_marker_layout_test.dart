import 'package:air_quality_monitor/presentation/widgets/map_marker_layout.dart';
import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:flutter/material.dart';
import 'package:air_quality_monitor/presentation/widgets/aqi_marker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_dependencies.dart';

void main() {
  ProjectedAirPoint point(String id, Offset at) => ProjectedAirPoint(
    fixtureReport(
      place: Place(id: id, name: id, latitude: 43, longitude: 76),
    ),
    at,
  );
  const viewport = Size(360, 320);
  const badge = Size(104, 38);

  test('Dense labels group without inventing or moving their AQI data', () {
    final a = point('selected', const Offset(150, 150));
    final b = point('nearby', const Offset(180, 150));
    final c = point('separate', const Offset(160, 240));
    final groups = groupAirMarkers([a, b, c], viewport, badge);
    expect(groups, hasLength(2));
    expect(groups.first.points, [a, b]);
    expect(groups.first.points.first.report, same(a.report));
    expect(groups.first.bounds.center, a.position);
    expect(groups.first.bounds.overlaps(groups.last.bounds), isFalse);
  });

  test('Partial edge labels are hidden, never clamped to fake coordinates', () {
    final groups = groupAirMarkers(
      [
        point('left', const Offset(15, 150)),
        point('top', const Offset(150, 12)),
        point('right', const Offset(350, 150)),
        point('bottom', const Offset(150, 315)),
        point('visible', const Offset(150, 150)),
      ],
      viewport,
      badge,
    );
    expect(groups.single.points.single.report.place.id, 'visible');
  });

  test('Map controls reserve space and a larger viewport reveals points', () {
    final p = point('under-zoom', const Offset(300, 60));
    expect(
      groupAirMarkers(
        [p],
        viewport,
        badge,
        reserved: [const Rect.fromLTWH(290, 0, 70, 112)],
      ),
      isEmpty,
    );
    expect(groupAirMarkers([p], const Size(700, 400), badge), hasLength(1));
  });

  test('Large text preserves non-overlapping, fully visible groups', () {
    final groups = groupAirMarkers(
      [
        point('first', const Offset(150, 150)),
        point('second', const Offset(200, 150)),
        point('third', const Offset(180, 260)),
      ],
      viewport,
      const Size(208, 76),
    );
    expect(groups, hasLength(2));
    expect(groups.first.points, hasLength(2));
    expect(groups.first.bounds.overlaps(groups.last.bounds), isFalse);
  });
  testWidgets('AQI labels retain readable contrast in every category', (
    tester,
  ) async {
    for (final aqi in [25.0, 75.0, 125.0, 175.0, 250.0, 350.0]) {
      final base = fixtureReport();
      final report = AirReport(
        place: base.place,
        current: AirPoint(
          time: base.current.time,
          values: {...base.current.values, 'us_aqi': aqi},
        ),
        forecast: base.forecast,
        fetchedAt: base.fetchedAt,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 104,
              height: 44,
              child: AqiMapBadge(report: report, variable: 'us_aqi'),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text(aqi.toStringAsFixed(0)));
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AqiMapBadge),
              matching: find.byType(Container),
            )
            .first,
      );
      final background = (container.decoration! as BoxDecoration).color!
          .computeLuminance();
      final ink = text.style!.color!.computeLuminance();
      final contrast =
          (background > ink ? background + .05 : ink + .05) /
          (background > ink ? ink + .05 : background + .05);
      expect(contrast, greaterThanOrEqualTo(4.5), reason: 'AQI $aqi');
    }
  });
}
