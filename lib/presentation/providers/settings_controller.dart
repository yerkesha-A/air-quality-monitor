import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this.preferences);
  final SharedPreferences preferences;
  ThemeMode get themeMode => ThemeMode.values[preferences.getInt('theme') ?? 0];
  bool get onboarded => preferences.getBool('onboarded') ?? false;
  int get threshold => preferences.getInt('threshold') ?? 100;
  bool get alertsEnabled => preferences.getBool('alerts') ?? false;
  bool get backgroundAlerts => preferences.getBool('backgroundAlerts') ?? false;
  Future<void> setBackgroundAlerts(bool value) async {
    await preferences.setBool('backgroundAlerts', value);
    notifyListeners();
  }

  /// Cloud preferences are restored before any upload. Notification permission
  /// remains device-local; restoring a preference never requests it.
  Future<void> restoreCloud(Map<String, dynamic> data) async {
    final theme = data['theme'];
    if (theme is int && theme >= 0 && theme < ThemeMode.values.length) {
      await preferences.setInt('theme', theme);
    }
    final threshold = data['threshold'];
    if (threshold is int && threshold >= 25 && threshold <= 300) {
      await preferences.setInt('threshold', threshold);
    }
    for (final key in ['milligrams', 'backgroundAlerts']) {
      if (data[key] is bool) await preferences.setBool(key, data[key] as bool);
    }
    notifyListeners();
  }

  bool get milligrams => preferences.getBool('milligrams') ?? false;
  Future<void> setTheme(ThemeMode mode) async {
    await preferences.setInt('theme', mode.index);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await preferences.setBool('onboarded', true);
    notifyListeners();
  }

  Future<void> setThreshold(int value) async {
    await preferences.setInt('threshold', value.clamp(25, 300));
    notifyListeners();
  }

  Future<void> setAlerts(bool value) async {
    await preferences.setBool('alerts', value);
    notifyListeners();
  }

  Future<void> setMilligrams(bool value) async {
    await preferences.setBool('milligrams', value);
    notifyListeners();
  }
}
