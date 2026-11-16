# Air Quality Monitor — текущий статус

Актуализировано 16 ноября 2026 по уточнённым 13 категориям. **РК1 оценивается по неделям 1–7**. Firebase недели 8 показан дополнительно. [Подробный аудит](docs/REQUIREMENTS_AUDIT.md) содержит исходники и границы подтверждения каждого пункта.

| № | Обязательный пункт полного проекта | Статус |
| --- | --- | --- |
| 1 | Архитектура Dart | Три слоя, Repository/DI; отдельные Dart-задания выполнены |
| 2 | Material 3 | Экраны, обе темы, адаптивность и эскизы подготовлены |
| 3 | Provider + BLoC/Riverpod | Реальные Provider + BLoC; Riverpod не используется |
| 4 | REST API | Open-Meteo, generated JSON DTO, ошибки/timeout/debounce/refresh |
| 5 | SharedPreferences + SQLite | Настройки/кеш/история/избранное, offline-first |
| 6 | GoRouter | Shell branches, параметры, guard и неизвестный маршрут |
| 7 | Firebase | Реальные Auth/Firestore/Rules/FCM; физическая межустройственная приёмка отдельно не проведена |
| 8 | Google Maps + геолокация | Работает flutter_map / OpenStreetMap: реальные тайлы, AQI и GPS проверены на Android. Замена Google Maps требует согласования преподавателя; billing не подключён |
| 9 | Производительность | Infinite scroll заметок/уведомлений, cached_network_image, реальные DevTools до/после; p95 сократился, slow frames остаются ([неделя 10](docs/WEEK_10.md)) |
| 10 | Нативные возможности | Камера/GPS/MethodChannel проверены на эмуляторе; физический телефон ещё не принят |
| 11 | Тестирование | 16.11: 96 тестов, coverage 72,83%, Rules 6/6, функции 3/3; [результаты](docs/rk2/evidence/validation.json) |
| 12 | CI/CD | Workflow прошёл на GitHub: android + firestore-rules success; [доказательство](docs/rk1/GITHUB.md) |
| 13 | Release + Crashlytics | Подписанные Android APK/AAB и non-fatal подтверждены 16.10; изменения 29.10 проверены в debug/profile |

## РК1

Темы недель 1–7 имеют реализацию, отдельные задания и доказательства: [RK1_REPORT.md](RK1_REPORT.md). Даты новых учебных материалов указаны честно. [README](README.md) представляет приложение; диагностика и внутренняя история вынесены в отдельные документы.

## Сдача

[GitHub](https://github.com/yerkesha-A/air-quality-monitor) · [Что отправить](docs/rk1/SUBMISSION.md) · [Сценарий защиты](docs/rk1/DEFENSE_5_MIN.md) · [Проверки](docs/rk1/VALIDATION.md).

## Документы

- [Неделя 9](WEEK_09.md), [неделя 10](WEEK_10.md), [неделя 11](WEEK_11.md)
- [Аудит 13 требований и недель 1–8](docs/REQUIREMENTS_AUDIT.md)
- [Профилирование, пагинация и изображения](docs/PERFORMANCE.md)
- [Подготовка Google Maps](docs/GOOGLE_MAPS_SETUP.md)
- [Технические подробности](docs/TECHNICAL_NOTES.md)
- [История этапов](docs/PROJECT_HISTORY.md)

Дизайн, ключ подписи и пользовательские данные сохранены. Billing/Google Play не подключались.

Текущие отчёты недель 9–15 и ограничения: [РК2](docs/RK2_REPORT.md). Документы WEEK_09/10/11 в корне сохраняют историю предыдущей проверки.
