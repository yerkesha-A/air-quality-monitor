import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/air_quality.dart';
import 'aqi_marker.dart';

Size airMapMarkerSize(TextScaler scaler) {
  final scale = scaler.scale(15) / 15;
  return Size(104 * scale, 44 * scale);
}

class ProjectedAirPoint {
  const ProjectedAirPoint(this.report, this.position);
  final AirReport report;
  final Offset position;
}

class AirMarkerGroup {
  AirMarkerGroup(ProjectedAirPoint point, this.bounds) : points = [point];
  final List<ProjectedAirPoint> points;
  final Rect bounds;
}

/// Keep each displayed label entirely inside the viewport, clear of controls.
/// Nearby points share one representative at its real coordinates, never an
/// invented average AQI or a displaced geographic position.
List<AirMarkerGroup> groupAirMarkers(
  Iterable<ProjectedAirPoint> points,
  Size viewport,
  Size markerSize, {
  List<Rect> reserved = const [],
}) {
  final visible = (Offset.zero & viewport).deflate(8);
  final groups = <AirMarkerGroup>[];
  for (final point in points) {
    final rect = Rect.fromCenter(
      center: point.position,
      width: markerSize.width,
      height: markerSize.height,
    );
    if (!visible.contains(rect.topLeft) ||
        !visible.contains(rect.bottomRight) ||
        reserved.any((r) => r.overlaps(rect))) {
      continue;
    }
    final collision = groups
        .where((group) => group.bounds.inflate(6).overlaps(rect))
        .firstOrNull;
    if (collision == null) {
      groups.add(AirMarkerGroup(point, rect));
    } else {
      collision.points.add(point);
    }
  }
  return groups;
}

class AirMapMarkers extends StatelessWidget {
  const AirMapMarkers({
    super.key,
    required this.reports,
    required this.variable,
    required this.selectedId,
    required this.onSelect,
  });
  final List<AirReport> reports;
  final String variable;
  final String? selectedId;
  final void Function(List<AirReport>) onSelect;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final size = airMapMarkerSize(MediaQuery.textScalerOf(context));
    final ordered = [
      ...reports.where((r) => r.place.id == selectedId),
      ...reports.where((r) => r.place.id != selectedId),
    ];
    final groups = groupAirMarkers(
      ordered.map(
        (r) => ProjectedAirPoint(
          r,
          camera.latLngToScreenOffset(
            LatLng(r.place.latitude, r.place.longitude),
          ),
        ),
      ),
      camera.nonRotatedSize,
      size,
      reserved: [Rect.fromLTWH(camera.nonRotatedSize.width - 64, 0, 64, 112)],
    );
    return MarkerLayer(
      markers: [
        for (final group in groups)
          Marker(
            point: LatLng(
              group.points.first.report.place.latitude,
              group.points.first.report.place.longitude,
            ),
            rotate: true,
            width: size.width,
            height: size.height,
            child: Semantics(
              button: true,
              label:
                  '${group.points.first.report.place.name}, '
                  '${group.points.first.report.current.aqi?.round() ?? 'нет данных'} US AQI'
                  '${group.points.length > 1 ? ', точек рядом: ${group.points.length}, открыть список' : ''}',
              child: GestureDetector(
                key: ValueKey(
                  'map-marker-${group.points.first.report.place.id}',
                ),
                onTap: () => onSelect([for (final p in group.points) p.report]),
                child: AqiMapBadge(
                  report: group.points.first.report,
                  variable: variable,
                  count: group.points.length,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
