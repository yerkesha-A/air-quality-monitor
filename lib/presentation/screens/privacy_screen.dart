import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/support/contact.dart';
import '../widgets/nature_components.dart';
import '../widgets/primitives.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => AirScaffold(
    appBar: AppBar(title: const Text('Данные и приватность')),
    body: PageBody(
      children: [
        const AirSurface(
          child: Row(
            children: [
              Icon(Icons.shield_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ваши данные. Ваш выбор.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Для загрузки воздуха координаты выбранного места передаются Open-Meteo. Поисковая строка города передаётся его Geocoding API. GPS используется только после вашего запроса; фонового отслеживания нет.',
        ),
        const SectionTitle('На устройстве'),
        const Text(
          'Тема, единицы, пороги, выбранный город, избранное, кеш воздуха, история и заметки сохраняются локально. Фото заметок и профиля остаются в приватной папке приложения.',
        ),
        const SectionTitle('При подключении аккаунта'),
        const Text(
          'Firebase Authentication обрабатывает вход. Профиль, настройки, избранное и выбранное место могут сохраняться в Firestore. При разрешённых push сохраняется FCM-токен. Crashlytics собирает диагностику в release-сборке с подключённым Firebase. Пароли не записываются в Firestore или журналы приложения.',
        ),
        const SectionTitle('Карта и камера'),
        const Text(
          'OpenStreetMap получает запросы тайлов видимой области карты; сетевым сервисам доступен IP-адрес. На устройстве сохраняется ограниченный кеш тайлов. Камера открывается только по вашей кнопке. Фотографии не используются для вычисления AQI и не загружаются в Firebase Storage.',
        ),
        const SectionTitle('Удаление аккаунта и данных'),
        const Text(
          'Войдя в аккаунт, можно подтвердить повторный вход и удалить учётную запись, облачные данные и фото профиля на этом устройстве. Общая локальная история, заметки, избранное и настройки сохраняются для гостевого режима. Другие устройства не очищаются дистанционно. Для защиты от старых сессий сохраняется служебная запись без имени и email: поддержка удаляет её не ранее чем через 2 часа. Выход сам по себе ничего не удаляет. Также доступен запрос через поддержку.',
        ),
        OutlinedButton.icon(
          onPressed: () => context.push('/delete-account'),
          icon: const Icon(Icons.person_remove_outlined),
          label: const Text('Удаление аккаунта'),
        ),
        const SizedBox(height: 12),
        const SelectableText('Контакт разработчика: $supportEmail'),
        const SizedBox(height: 16),
        const Text(
          'Политика обновлена 25 ноября 2026. Это учебный проект; рекламных SDK и платежей в приложении нет.',
        ),
      ],
    ),
  );
}
