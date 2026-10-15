import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/services/device_service.dart';
import '../providers/auth_controller.dart';
import '../providers/places_controller.dart';
import '../providers/settings_controller.dart';
import '../widgets/primitives.dart';
import '../widgets/nature_components.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final auth = context.watch<AuthController>();
    final places = context.watch<PlacesController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: PageBody(
        children: [
          AtmosphereHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('ВАШЕ ПРОСТРАНСТВО', color: Colors.white70),
                const SizedBox(height: 14),
                const Text(
                  'В вашем ритме',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ваши места. Ваши привычки.\nСвежий взгляд на каждый день.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.6,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AirSurface(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                auth.account?.name.isNotEmpty == true
                    ? auth.account!.name
                    : auth.account == null
                    ? 'Без аккаунта'
                    : 'Ваш аккаунт',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                auth.account?.email ?? 'Мониторинг доступен без входа',
              ),
              trailing: const Icon(Icons.arrow_outward_rounded),
              onTap: () =>
                  context.push(auth.account == null ? '/login' : '/account'),
            ),
          ),
          const SectionTitle('Оформление'),
          AirSurface(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: ThemeMode.values
                  .map(
                    (mode) => ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: settings.themeMode == mode
                          ? Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: .6)
                          : Colors.transparent,
                      leading: Icon(switch (mode) {
                        ThemeMode.system => Icons.brightness_auto_outlined,
                        ThemeMode.light => Icons.light_mode_outlined,
                        ThemeMode.dark => Icons.dark_mode_outlined,
                      }),
                      title: Text(switch (mode) {
                        ThemeMode.system => 'Как в системе',
                        ThemeMode.light => 'Светлая тема',
                        ThemeMode.dark => 'Тёмная тема',
                      }),
                      trailing: settings.themeMode == mode
                          ? const Icon(Icons.check_circle_outline)
                          : null,
                      onTap: () => settings.setTheme(mode),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SectionTitle('Единицы концентрации'),
          AirSurface(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Миллиграммы на м³'),
              subtitle: Text(
                settings.milligrams
                    ? 'мг/м³ · состав воздуха на главной'
                    : 'мкг/м³',
              ),
              value: settings.milligrams,
              onChanged: settings.setMilligrams,
            ),
          ),
          const SectionTitle('Ваши места'),
          AirSurface(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bookmark_outline),
                  title: const Text('Избранные города'),
                  subtitle: Text(
                    '${places.favorites.length} сохранено · выбор на главной',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Предупреждения'),
                  subtitle: Text('Порог ${settings.threshold} US AQI'),
                  onTap: () => context.push('/alerts'),
                ),
              ],
            ),
          ),
          const SectionTitle('Полезно знать'),
          AirSurface(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('О загрязнителях'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/insights'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Данные и приватность'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/privacy'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Об устройстве'),
                  subtitle: const Text('Системная информация'),
                  onTap: () async {
                    try {
                      final info = await DeviceService().info();
                      if (context.mounted) {
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Устройство'),
                            content: Text(
                              '${info['model']}\nAndroid API ${info['sdk']}\nБатарея: ${info['battery'] ?? '—'}%',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Закрыть'),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        showMessage(
                          context,
                          'Сведения об устройстве недоступны.',
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Air Quality Monitor · 1.0.0\nИсточник: Open-Meteo / Copernicus CAMS\nЕдиная шкала: US AQI',
            style: TextStyle(fontSize: 11, height: 1.6),
          ),
        ],
      ),
    );
  }
}
