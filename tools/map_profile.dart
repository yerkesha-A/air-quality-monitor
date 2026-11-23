// QA-only entrypoint for the same real map scenario before/after UI changes.
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:air_quality_monitor/presentation/screens/home_screen.dart';

import 'week10_profile.dart' as profiling;

Element? _find(Element? root, bool Function(Widget) matches) {
  if (root == null) {
    return null;
  }
  if (matches(root.widget)) {
    return root;
  }
  Element? result;
  root.visitChildren((child) => result ??= _find(child, matches));
  return result;
}

Future<void> main() async {
  await profiling.main();
  developer.registerExtension('ext.aqm.map.open', (_, _) async {
    final home = _find(
      WidgetsBinding.instance.rootElement,
      (w) => w is HomeScreen,
    );
    if (home == null) {
      return developer.ServiceExtensionResponse.result('{"ready":false}');
    }
    GoRouter.of(home).go('/map');
    return developer.ServiceExtensionResponse.result('{"ready":true}');
  });
  developer.registerExtension('ext.aqm.map.viewport', (_, _) async {
    final map = _find(
      WidgetsBinding.instance.rootElement,
      (w) => w is FlutterMap,
    );
    final box = map?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return developer.ServiceExtensionResponse.result('{"ready":false}');
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'ready': true,
        'width': box.size.width,
        'height': box.size.height,
        'top': box.localToGlobal(Offset.zero).dy,
      }),
    );
  });
}
