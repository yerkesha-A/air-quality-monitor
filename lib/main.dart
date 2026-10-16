import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Paint a real first Flutter frame before opening databases/native Firebase.
  // Bootstrap work must not hold the Android launch screen indefinitely.
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.create(Brightness.light),
      darkTheme: AppTheme.create(Brightness.dark),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.air_rounded, size: 56),
                SizedBox(height: 20),
                Text('Air Quality', style: TextStyle(fontSize: 24)),
                SizedBox(height: 24),
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  try {
    final preferences = await SharedPreferences.getInstance();
    final dependencies = await AppDependencies.create(preferences);
    runApp(
      AirQualityApp(
        settings: SettingsController(preferences),
        dependencies: dependencies,
      ),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Не удалось запустить приложение. Проверьте конфигурацию и доступное место на устройстве.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: main,
                    child: const Text('Повторить запуск'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
