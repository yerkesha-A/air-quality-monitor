import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/air_quality.dart';
import '../local/local_store.dart';

class NotificationService {
  NotificationService(this.store, this.preferences);
  final LocalStore store;
  final SharedPreferences preferences;
  final _plugin = FlutterLocalNotificationsPlugin();
  void Function(String route)? onOpen;
  String? initialRoute;
  bool _checking = false;
  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) => onOpen?.call('/alerts'),
    );
    final launched = await _plugin.getNotificationAppLaunchDetails();
    if (launched?.didNotificationLaunchApp == true) initialRoute = '/alerts';
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'air_quality_alerts',
        'Качество воздуха',
        description: 'Предупреждения о качестве воздуха',
        importance: Importance.high,
      ),
    );
  }

  Future<bool> requestPermission() async =>
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      false;
  Future<void> show({
    required String id,
    required String title,
    required String body,
    String source = 'local',
  }) async {
    await _plugin.show(
      id: id.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'air_quality_alerts',
          'Качество воздуха',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      payload: '/alerts',
    );
    await store.recordAlert(id: id, title: title, body: body, source: source);
  }

  Future<void> check(
    AirReport report, {
    required bool enabled,
    required int threshold,
  }) async {
    if (_checking ||
        !enabled ||
        report.offline ||
        report.isStale(DateTime.now().toUtc()) ||
        report.current.aqi == null ||
        report.current.aqi! < threshold) {
      return;
    }
    _checking = true;
    try {
      final key =
          'alert:${report.place.id}:${report.current.time.millisecondsSinceEpoch ~/ 3600000}:$threshold';
      if (preferences.getBool(key) == true) return;
      await show(
        id: key,
        title: 'Воздух в ${report.place.name}',
        body:
            '${report.current.aqi!.round()} US AQI — выше вашего порога $threshold. Оценка модели.',
      );
      await preferences.setBool(key, true);
    } finally {
      _checking = false;
    }
  }
}
