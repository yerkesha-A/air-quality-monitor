// Isolated profiling entrypoint. Production continues to start at lib/main.dart.
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:air_quality_monitor/main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final frames = <Map<String, int>>[];
  var recording = false;
  WidgetsBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
    if (!recording) return;
    for (final frame in timings) {
      if (frames.length >= 20000) break;
      frames.add({
        'buildUs': frame.buildDuration.inMicroseconds,
        'rasterUs': frame.rasterDuration.inMicroseconds,
        'totalUs': frame.totalSpan.inMicroseconds,
      });
    }
  });
  developer.registerExtension('ext.aqm.frames.start', (_, _) async {
    frames.clear();
    recording = true;
    return developer.ServiceExtensionResponse.result(
      jsonEncode({'recording': true}),
    );
  });
  developer.registerExtension('ext.aqm.frames.stop', (_, _) async {
    recording = false;
    return developer.ServiceExtensionResponse.result(
      jsonEncode({'frames': frames}),
    );
  });
  await app.main();
}
