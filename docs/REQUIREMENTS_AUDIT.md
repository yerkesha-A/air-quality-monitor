# Проверка 13 обязательных требований

Актуализация перед защитой: 23.11.2026. Основание — предоставленные преподавательские категории и задания недель 1–15. Подробная матрица недель, проверок и ограничений: [финальный аудит](final_audit/AUDIT_01_15.md). РК1 оценивается по неделям 1–7; РК2 включает недели 8–15.

| № | Требование | Реализация в исходниках | Проверка и доказательства | Статус |
|---|---|---|---|---|
| 1 | Dart и архитектура | `coursework/week01`, null safety, коллекции, классы, async/await; presentation/domain/data, Repository, AppDependencies | Отдельные Dart target запущены; coursework/repository/BLoC tests | Реализовано |
| 2 | Material 3 | `app_theme.dart`, light/dark/system, адаптивные экраны, эскизы SVG | Widget-тесты размеров, тем и крупного текста; реальные скриншоты | Реализовано |
| 3 | Provider + BLoC/Riverpod | MultiProvider + MultiBlocProvider; settings/auth/places и Air/Search/History BLoC | Реальные счётчики setState/InheritedWidget/Provider в `docs/state_examples.dart`, тесты независимых обновлений, сравнение в README | Реализовано через Provider + BLoC; Riverpod не заявляется |
| 4 | REST/JSON | OpenMeteoApi, три generated DTO json_serializable, timeout, debounce, загрузка/ошибка/пусто/refresh | API/BLoC tests, повторный build_runner без diff, Android air_flow с настоящим ответом API | Реализовано |
| 5 | SharedPreferences + SQLite | Настройки, избранное, история, кэш, заметки, offline-first и миграции | Repository/freshness/pagination tests, настоящая Android SQLite; сохранённое время не подменяется временем чтения кэша | Реализовано |
| 6 | GoRouter | StatefulShellRoute.indexedStack, четыре ветки, `/city/:id`, query mode, guard аккаунта, error route | Навигационные widget-тесты параметров/redirect/вложенных веток/неизвестного маршрута | Реализовано |
| 7 | Firebase | Настоящие Email/Google Auth, Firestore, Rules, FCM | Rules 6/6; новые native Firebase/FCM foreground/background/terminated результаты; release SHA-1/SHA-256 и Google provider повторно подтверждены read-only | Реализовано; ошибка закрытия общей SQLite из FCM исправлена и проверена; свежий интерактивный Google-вход новой сборки требует участия владельца |
| 8 | Google Maps + геолокация | Бесплатная OSM/flutter_map, реальные модельные AQI, GPS, обработка разрешений, тайлы и атрибуция | Map/location tests, Android GPS и настоящий тайловый кэш; новая легенда, группировка и раскрываемая карточка | **Частично по требованию SDK:** согласовать замену Google Maps у преподавателя |
| 9 | Производительность | Lazy lists, настоящая keyset пагинация SQLite, cached_network_image, dispose и ограничение запросов | Pagination/infinite-records tests, native disk cache; реальные исторические DevTools Performance/Memory/FrameTiming до/после | Реализовано; 60 FPS и отсутствие утечек не гарантируются |
| 10 | Нативные возможности | image_picker камера/галерея, локальные фото, geolocator, Kotlin MethodChannel | Android-эмулятор: camera/gallery/permissions/channel и перезапуск; сценарии отмены/ошибок в тестах | **Частично:** физический Android ещё не проверен |
| 11 | Тестирование | Unit, mocktail, widget, integration; защита тестов от запуска на основном AVD | 108/108, analyze без замечаний; LCOV 2762/3693 = 74,79% >40%; Rules 6/6, Functions 3/3 | Локальные тесты подтверждены; не подменяют физическую приёмку |
| 12 | CI/CD | `.github/workflows/android.yml`: зависимости, формат, analyze, тесты, покрытие, APK/artifact, Rules job | [Опубликованный run 45177924926](https://github.com/yerkesha-A/air-quality-monitor/actions/runs/45177924926), commit 86e2acd, success | Старый CI подтверждён; новый run возможен после разрешения push |
| 13 | Release + Crashlytics | Существующий ключ, APK/AAB, obfuscate/split-debug-info, Crashlytics; privacy/store/Data Safety/App Distribution | Исторический build 2 опубликован с разрешения; non-fatal 16.11 подтверждён в Console; build 3 собран, обе подписи проверены, новый non-fatal подтверждён в Console | Новая публикация не выполняется; установка App Distribution на телефоне не подтверждена |

## Что нужно от владельца или преподавателя

- Согласование OpenStreetMap вместо требуемого Google Maps. Billing не подключается.
- Физический Android для настоящей проверки камеры, GPS и установки тестовой доставки.
- Разрешение push для проверки новой рабочей копии GitHub Actions. Старый зелёный запуск не является проверкой нового кода.
- Интерактивный вход Google, если требуется новая приёмка именно финального build 3. Предыдущий успешный вход и сохранение сессии уже зафиксированы; пароли в чат не нужны.

Новые материалы и проверки датируются фактическим выполнением. Дополнительные продуктовые идеи не добавляются к преподавательским требованиям: ежедневная серверная сводка, iOS-публикация и английская локализация не объявляются завершёнными.
