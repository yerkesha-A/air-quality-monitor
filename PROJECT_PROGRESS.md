# Air Quality Monitor — текущий статус

Актуализировано 16 октября 2026 по уточнённым 13 категориям. **РК1 оценивается по неделям 1–7**. Firebase недели 8 показан дополнительно. [Подробный аудит](docs/REQUIREMENTS_AUDIT.md) содержит исходники и границы подтверждения каждого пункта.

| № | Обязательный пункт полного проекта | Статус |
| --- | --- | --- |
| 1 | Архитектура Dart | Три слоя, Repository/DI; отдельные Dart-задания выполнены |
| 2 | Material 3 | Экраны, обе темы, адаптивность и эскизы подготовлены |
| 3 | Provider + BLoC/Riverpod | Реальные Provider + BLoC; Riverpod не используется |
| 4 | REST API | Open-Meteo, generated JSON DTO, ошибки/timeout/debounce/refresh |
| 5 | SharedPreferences + SQLite | Настройки/кеш/история/избранное, offline-first |
| 6 | GoRouter | Shell branches, параметры, guard и неизвестный маршрут |
| 7 | Firebase | Реальные Auth/Firestore/Rules/FCM; физическая межустройственная приёмка отдельно не проведена |
| 8 | Google Maps + геолокация | Частично: карта ждёт billing/API key и native-проверки; GPS работает отдельно |
| 9 | Производительность | Пагинация и memory ImageCache есть; DevTools-результаты сохранены; slow frames требуют работы, дискового HTTP-кеша нет |
| 10 | Нативные возможности | Камера/GPS/MethodChannel проверены на эмуляторе; физический телефон ещё не принят |
| 11 | Тестирование | 73/73 Flutter, analyze чистый, покрытие 69,62%; Rules 6/6 |
| 12 | CI/CD | Workflow прошёл на GitHub: android + firestore-rules success; [доказательство](docs/rk1/GITHUB.md) |
| 13 | Release + Crashlytics | Подписанные Android APK/AAB и серверное получение non-fatal подтверждены |

## РК1

Темы недель 1–7 имеют реализацию, отдельные задания и доказательства: [RK1_REPORT.md](RK1_REPORT.md). Даты новых учебных материалов указаны честно. [README](README.md) представляет приложение; диагностика и внутренняя история вынесены в отдельные документы.

## Сдача

[GitHub](https://github.com/yerkesha-A/air-quality-monitor) · [Что отправить](docs/rk1/SUBMISSION.md) · [Сценарий защиты](docs/rk1/DEFENSE_5_MIN.md) · [Проверки](docs/rk1/VALIDATION.md).

## Документы

- [Аудит 13 требований и недель 1–8](docs/REQUIREMENTS_AUDIT.md)
- [Профилирование, пагинация и изображения](docs/PERFORMANCE.md)
- [Подготовка Google Maps](docs/GOOGLE_MAPS_SETUP.md)
- [Технические подробности](docs/TECHNICAL_NOTES.md)
- [История этапов](docs/PROJECT_HISTORY.md)

Дизайн, ключ подписи и пользовательские данные сохранены. Billing/Google Play не подключались.
