import 'package:flutter/material.dart';

import '../../domain/entities/air_quality.dart';

String markerValue(AirReport report, String variable) =>
    report.current.values[variable]?.toStringAsFixed(
      variable == 'us_aqi' ? 0 : 1,
    ) ??
    '—';

/// Native Flutter badge: no raster generation or image decoding on each update.
class AqiMapBadge extends StatelessWidget {
  const AqiMapBadge({super.key, required this.report, required this.variable});
  final AirReport report;
  final String variable;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: report.current.aqi == null
          ? const Color(0xffbedee9)
          : Color(AirBand.forAqi(report.current.aqi!).color),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4)],
    ),
    child: Text(
      markerValue(report, variable),
      maxLines: 1,
      style: const TextStyle(
        color: Color(0xff172e34),
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
  );
}
