import 'package:flutter/material.dart';

import '../../domain/entities/air_quality.dart';

String markerValue(AirReport report, String variable) =>
    report.current.values[variable]?.toStringAsFixed(
      variable == 'us_aqi' ? 0 : 1,
    ) ??
    '—';

/// Native Flutter badge: no raster generation or image decoding on each update.
class AqiMapBadge extends StatelessWidget {
  const AqiMapBadge({
    super.key,
    required this.report,
    required this.variable,
    this.count = 1,
  });
  final AirReport report;
  final String variable;
  final int count;

  @override
  Widget build(BuildContext context) {
    final background = report.current.aqi == null
        ? const Color(0xffbedee9)
        : Color(AirBand.forAqi(report.current.aqi!).color);
    const ink = Color(0xff172e34);
    final luminance = background.computeLuminance();
    final foreground = (luminance + .05) / (ink.computeLuminance() + .05) >= 4.5
        ? ink
        : 1.05 / (luminance + .05) >= 4.5
        ? Colors.white
        : Colors.black;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              markerValue(report, variable),
              maxLines: 1,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          if (count > 1) ...[
            const SizedBox(width: 4),
            Text(
              '+${count - 1}',
              style: TextStyle(fontSize: 11, color: foreground),
            ),
          ],
        ],
      ),
    );
  }
}
