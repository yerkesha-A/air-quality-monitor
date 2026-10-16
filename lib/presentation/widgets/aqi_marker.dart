import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/air_quality.dart';

/// Small immutable raster badge. Bounded by caller to currently visible points.
Future<BitmapDescriptor> aqiMarker(AirReport report, String variable) async {
  final value = report.current.values[variable];
  final label = value == null
      ? '—'
      : value.toStringAsFixed(variable == 'us_aqi' ? 0 : 1);
  final color = variable == 'us_aqi' && report.current.aqi != null
      ? Color(AirBand.forAqi(report.current.aqi!).color)
      : const Color(0xffbedee9);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 3, 90, 50),
      const Radius.circular(25),
    ),
    Paint()..color = color,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 3, 90, 50),
      const Radius.circular(25),
    ),
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
  final text = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Color(0xff172e34),
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 86);
  text.paint(canvas, Offset((96 - text.width) / 2, (56 - text.height) / 2));
  final picture = recorder.endRecording();
  final image = await picture.toImage(96, 56);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 48,
      height: 28,
    );
  } finally {
    image.dispose();
    picture.dispose();
  }
}
