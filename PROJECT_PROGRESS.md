> Проверка 25.11.2026 и подготовка iOS: [актуальный аудит всех недель и 13 категорий](docs/full_audit_weeks_1_15.md), [инструкция iOS](docs/ios_setup.md). Полная готовность iOS и физический Android не заявляются.

# Air Quality Monitor — текущий статус

Актуализировано 23 ноября 2026 по уточнённым 13 категориям. **РК1 оценивается по неделям 1–7**. Firebase недели 8 показан дополнительно. [Подробный аудит](docs/REQUIREMENTS_AUDIT.md) содержит исходники и границы подтверждения каждого пункта.

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
| 9 | Производительность | Infinite scroll заметок/уведомлений, cached_network_image, реальные DevTools карты до/после на API 30 / 2 ГБ; raster p95 вырос, доля slow frames снизилась ([неделя 10](docs/WEEK_10.md)) |
| 10 | Нативные возможности | Камера/GPS/MethodChannel проверены на эмуляторе; физическая проверка отложена: Android-телефона нет |
| 11 | Тестирование | 23.11: 108 тестов, coverage 74,79%, Rules 6/6, функции 3/3; [результаты](docs/final_audit/evidence/RESULTS.json) |
| 12 | CI/CD | Опубликованный CI 45228891410 для 79bca13 success; новый код опубликован с разрешения; оба jobs прошли; [результат текущего этапа](docs/final_audit/evidence/github-actions.json) |
| 13 | Release + Crashlytics | APK/AAB 1.1.0+3 подписаны и проверены 23.11; новый non-fatal подтверждён в Console, symbols загружены. App Distribution содержит предыдущий build 2, физическая установка не подтверждена |

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

## Финальная проверка перед защитой

[Матрица всех 15 недель](docs/final_audit/AUDIT_01_15.md) · [13 требований](docs/REQUIREMENTS_AUDIT.md) · [Комплект и инструкция](docs/final_audit/HAND_IN.md).

Карта: +58,71% видимой высоты, группы, раскрытие, легенда, light/dark/landscape и эмуляторный GPS. Исправлена реальная ошибка закрытия UI SQLite фоновым FCM: отдельный native handle, тест integrity_check, три FCM-состояния в debug и подписанном release. Исходники и материалы опубликованы с разрешения; новые APK/AAB не публиковались.
