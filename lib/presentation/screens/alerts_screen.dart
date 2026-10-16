import 'package:flutter/material.dart';

import '../widgets/nature_components.dart';

import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/firebase_service.dart';
import '../providers/auth_controller.dart';

import '../../data/local/local_store.dart';
import '../../data/services/notification_service.dart';
import '../providers/settings_controller.dart';
import '../widgets/primitives.dart';
import '../widgets/paged_records.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late double _threshold = context
      .read<SettingsController>()
      .threshold
      .toDouble();
  int _revision = 0;
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final auth = context.watch<AuthController>();
    final firebase = context.read<FirebaseService>();
    return AirScaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            tooltip: 'Обновить историю',
            onPressed: () => setState(() => _revision++),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: PageBody(
        children: [
          const AirSurface(
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined, size: 30),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ваш воздух — под контролем',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Выберите личный порог качества воздуха',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Предупреждать начиная с'),
                const SizedBox(height: 12),
                Text(
                  '${_threshold.round()} US AQI',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Slider(
                  min: 25,
                  max: 300,
                  divisions: 55,
                  value: _threshold,
                  semanticFormatterCallback: (value) =>
                      '${value.round()} US AQI',
                  onChanged: (value) => setState(() => _threshold = value),
                  onChangeEnd: (value) => settings.setThreshold(value.round()),
                ),
                const Text(
                  'Порог — личная настройка, он не меняет категорию качества воздуха.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AirSurface(
            padding: const EdgeInsets.all(12),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('При обновлении в приложении'),
              subtitle: const Text(
                'Уведомление при загрузке свежего AQI выше порога',
              ),
              value: settings.alertsEnabled,
              onChanged: (enabled) async {
                if (enabled) {
                  final granted = await context
                      .read<NotificationService>()
                      .requestPermission();
                  if (!granted) {
                    if (context.mounted) {
                      showMessage(
                        context,
                        'Разрешите уведомления в настройках Android.',
                      );
                    }
                    return;
                  }
                }
                await settings.setAlerts(enabled);
              },
            ),
          ),
          const SectionTitle('В фоне'),
          AirSurface(
            padding: const EdgeInsets.all(12),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Push-уведомления'),
              subtitle: Text(
                firebase.configured && auth.account != null
                    ? 'Получать сообщения на этом устройстве'
                    : 'Войдите в аккаунт, чтобы получать push',
              ),
              value: settings.backgroundAlerts,
              onChanged: !firebase.configured || auth.account == null
                  ? null
                  : (enabled) async {
                      try {
                        if (enabled &&
                            !await firebase.enablePush(auth.account!)) {
                          if (context.mounted) {
                            showMessage(
                              context,
                              'Не удалось разрешить push-уведомления.',
                            );
                          }
                          return;
                        }
                        if (!enabled) await firebase.unregisterDevice();
                        await settings.setBackgroundAlerts(enabled);
                      } catch (_) {
                        if (context.mounted) {
                          showMessage(
                            context,
                            'Не удалось сохранить настройки push.',
                          );
                        }
                      }
                    },
            ),
          ),
          if (auth.account == null)
            TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Перейти к аккаунту'),
            ),
          if (!firebase.schedulerConfigured)
            const Text(
              'Автоматическая проверка при закрытом приложении ещё не активирована. Получение FCM-токена само по себе не запускает проверку AQI.',
            ),
          const SectionTitle('История на устройстве'),
          PagedRecords<Map<String, Object?>>(
            key: ValueKey(_revision),
            load: (after) =>
                context.read<LocalStore>().alertsPage(after: after),
            emptyMessage: 'Предупреждений пока не было.',
            itemBuilder: (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item['title'] as String),
              subtitle: Text(
                '${item['body']}\n${dateLabel(DateTime.fromMillisecondsSinceEpoch(item['created'] as int))}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
