import 'package:flutter/material.dart';

import '../widgets/nature_components.dart';

import '../widgets/primitives.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => AirScaffold(
    appBar: AppBar(title: const Text('Данные и приватность')),
    body: const PageBody(
      children: [
        AirSurface(
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
        SizedBox(height: 24),
        Text(
          'Для загрузки воздуха координаты выбранного места передаются Open-Meteo. Поисковая строка города передаётся его Geocoding API. GPS используется только после вашего запроса; фоновое отслеживание не включено.',
        ),
        SectionTitle('На устройстве'),
        Text(
          'Тема, единицы, пороги, выбранный город, избранное, кеш воздуха, история текущих оценок и заметки сохраняются локально. Фото заметок остаются в приватной папке приложения.',
        ),
        SectionTitle('При подключении аккаунта'),
        Text(
          'Firebase Authentication обрабатывает вход. Профиль, настройки, избранное и выбранное место могут сохраняться в Firestore для синхронизации и серверных предупреждений. При разрешённых push-уведомлениях сохраняется FCM-токен устройства. Crashlytics собирает диагностические сведения только в релизной сборке с подключённым Firebase.',
        ),
        SectionTitle('Карта и камера'),
        Text(
          'Google Maps использует сервисы Google при открытии карты. Камера открывается только по вашей кнопке. Изображения не используются для вычисления AQI.',
        ),
        SectionTitle('О проекте'),
        Text(
          'Это описание обработки данных текущего учебного проекта. Перед публичным релизом нужны опубликованная политика конфиденциальности, контакты разработчика и проверка Google Play Data Safety.',
        ),
      ],
    ),
  );
}
