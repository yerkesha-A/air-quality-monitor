# Аудит 13 обязательных требований

16 октября 2026. Пункты ниже соответствуют уточнённому владельцем перечню из 13 категорий. Приоритет РК1 — **задания недель 1–7**; Firebase недели 8 показан отдельно. Оригинальная методичка в репозитории отсутствует, поэтому дополнительные дословные критерии внутри категорий не подменяются предположениями.

| № | Требование | Подтверждение | Итог |
| --- | --- | --- | --- |
| 1 | Архитектура Dart | presentation/domain/data, Repository interfaces, constructor DI в AppDependencies, async/await; отдельные задания coursework/week01 | Реализовано; задания и тесты доступны |
| 2 | Material 3 | app_theme.dart, light/dark/system, адаптивные экраны, wireframes.svg и скриншоты | Реализовано; телефон/планшет/крупный текст покрыты widget-тестами |
| 3 | Provider + BLoC/Riverpod | app.dart: MultiProvider + MultiBlocProvider; settings/auth/places и Air/Search/History BLoC | Используются реально; Riverpod не используется и не требуется как второй вариант BLoC |
| 4 | REST API | OpenMeteoApi, generated air_dto.g.dart, @JsonSerializable для 3 DTO, timeout/loading/error/empty/debounce/refresh | Реализовано, API/DTO/BLoC проверены; build_runner повторно сгенерировал модели без diff ([результат](rk1/evidence/json-generation.txt)) |
| 5 | SharedPreferences + SQLite | Настройки, кеш, избранное, история, заметки, уведомления; offline-first Repository | Реализовано; unit/native-проверки и сохранность исходного AVD подтверждены |
| 6 | GoRouter | StatefulShellRoute.indexedStack с 4 ветками; `/city/:id`, query mode; redirect `/account` для неавторизованного, неизвестный маршрут | Реализовано; вложенность — shell/branches, а не только набор плоских страниц |
| 7 | Firebase | Реальные Auth Email/Google, Firestore profile/favorites/settings, Security Rules, настоящий FCM foreground/background/terminated + tap | Основные сценарии реализованы и подтверждены; физическая межустройственная приёмка отдельно не выполнена |
| 8 | Google Maps + геолокация | Maps SDK/MapScreen/MapAirController; GPS/reverse geocoding работают отдельно; тесты контроллера | **Частично:** реальные tiles и SDK-приёмка заблокированы отсутствием billing/API key |
| 9 | Производительность | SQLite keyset pagination, memory ImageCache/cacheWidth, WebP, lazy lists; фактические DevTools timeline/memory результаты | **Частично:** профилирование есть, slow frames остаются; отдельного дискового кеша сетевых фото нет |
| 10 | Нативные возможности | Camera intent/image_picker, приватные фото, геолокация/permissions, Kotlin MethodChannel model/sdk/battery | На эмуляторе проверено; физическая камера/GPS ещё требуют отдельной приёмки |
| 11 | Тестирование | 73 unit/widget, analyze, LCOV 69,62%, Security Rules 6/6, Python 3/3 и описанные native-прогоны | Локально успешно; точные команды и границы в VALIDATION |
| 12 | CI/CD | .github/workflows/android.yml, реальные удалённые запуски GitHub Actions | [Запуск #38946181056](https://github.com/yerkesha-A/air-quality-monitor/actions/runs/38946181056) завершился success: оба jobs успешны; подробности в GITHUB.md |
| 13 | Release + Crashlytics | Подписанные APK/AAB существующим ключом, Google release login/session, серверное подтверждение нового non-fatal | Android-артефакты и non-fatal проверены; Play-публикация и принудительный fatal crash не выполнялись |

## РК1: задания недель 1–7

| Неделя | Материалы и работающий код | Проверка |
| --- | --- | --- |
| 1 | Flutter/Dart, null safety, классы, коллекции, async/await; docs/dart_basics.dart и coursework/week01; GitHub/README | coursework_test.dart + запуск обоих Dart entrypoint; публичный репозиторий |
| 2 | Несколько экранов, Material 3, обе темы, эскизы | widget/adaptive matrix, реальные Android-снимки; эскизы честно датированы 16.10 |
| 3 | setState, настоящий CounterScope extends InheritedWidget, Provider; сравнение в README | coursework_test.dart проверяет независимые обновления и сохранение Provider при rebuild |
| 4 | BLoC, три слоя, Repository и DI | bloc_test.dart / repository_test.dart; production AppDependencies |
| 5 | Реальный REST/JSON, loading/error/empty, обновление, timeout/debounce/pull-to-refresh | api_test.dart / bloc_test.dart, live Android API |
| 6 | SharedPreferences/SQLite/избранное/история/кеш/offline-first | repository/local storage tests и ранее выполненный native offline-сценарий; данные AVD сохранены |
| 7 | GoRouter, вложенные ветки, параметры, guard, адаптивность | screens/widget tests, native account guard; обе темы и разные размеры |

По предоставленному перечню **темы недель 1–7 закрыты кодом, материалами и проверками**. Это утверждение о доступном списке, а не обещание 100% оценки по неизвестным подпунктам методички. Новые Dart-материалы/эскизы подготовлены при финальной сдаче, а не задним числом.

Неделя 8: реальные Firebase Auth/Firestore/FCM подтверждены, но она не включается в официальный состав оценки РК1 недель 1–7.

## Что остаётся в полном проекте

- Подключение Google Maps владельцем в Cloud и настоящая native-приёмка.
- Полная проверка производительности на profile build/физическом Android и работа со slow frames. Есть память/trace, но 60 FPS и отсутствие утечек не доказаны.
- Если под кешированием изображений требуется дисковый HTTP-кеш, этот подпункт пока не выполнен: есть memory ImageCache и постоянные локальные фото.
- Физическое устройство: камера/GPS и синхронизация двух устройств; смена пароля по ссылке с последующим входом пока не подтверждена.
- Из ранее сохранённого полного продуктового списка: автоматическая ежедневная AQI push-сводка, визуальная share-карточка, сравнение исторических периодов, английская локализация и публичная privacy policy. Эти функции не выдаются за готовые и не добавляются в РК1 произвольно.
- iOS и Google Play не входят в текущую Android-сдачу; публикация не выполнялась.

Подробнее: [профилирование/кеш/пагинация](PERFORMANCE.md), [Google Maps](GOOGLE_MAPS_SETUP.md), [результаты](rk1/VALIDATION.md), [РК1](../RK1_REPORT.md).
