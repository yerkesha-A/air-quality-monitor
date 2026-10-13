import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'presentation/providers/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
