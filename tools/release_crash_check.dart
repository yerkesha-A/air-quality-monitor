// Explicit QA entry point. Never use this target for the submitted APK/AAB.
import 'package:air_quality_monitor/main.dart' as application;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await application.main();
  if (!kReleaseMode || Firebase.apps.isEmpty) return;
  final preferences = await SharedPreferences.getInstance();
  const marker = 'rk2_nonfatal_20261116';
  if (preferences.getBool(marker) ?? false) return;
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCustomKey('verification', marker);
  await crashlytics.recordError(
    StateError('AQM intentional RK2 nonfatal verification 20261116'),
    StackTrace.current,
    reason: 'Explicit isolated release QA; no user data in this event',
    fatal: false,
  );
  await preferences.setBool(marker, true);
  await crashlytics.sendUnsentReports();
}
