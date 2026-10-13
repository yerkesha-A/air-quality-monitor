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
