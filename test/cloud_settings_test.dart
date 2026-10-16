import 'package:air_quality_monitor/presentation/providers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Cloud restores validated settings without granting local notification consent', () async {
    SharedPreferences.setMockInitialValues({
      'alerts': false,
      'theme': 1,
      'threshold': 100,
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsController(prefs);
    await settings.restoreCloud({
      'theme': 2,
      'threshold': 150,
      'milligrams': true,
      'backgroundAlerts': true,
    });
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.threshold, 150);
    expect(settings.milligrams, isTrue);
    expect(settings.alertsEnabled, isFalse);
    await settings.restoreCloud({
      'theme': 99,
      'threshold': -1,
      'milligrams': 'bad',
    });
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.threshold, 150);
    expect(settings.milligrams, isTrue);
    final restored = SettingsController(prefs);
    expect(restored.threshold, 150);
  });
}
