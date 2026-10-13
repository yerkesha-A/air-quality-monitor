# Air Quality Monitor — прогресс

Обновлено: 13 октября 2026. Рабочая платформа: Android. iOS отложен по прямому указанию пользователя.
Статус «код готов» не равен подтверждённой облачной интеграции.

| Неделя | Статус и доказательства |
|---|---|
| 1 | Android toolchain/licenses и API 37 emulator подтверждены; Dart-упражнение выполнено; локальный Git создан. GitHub remote ещё отсутствует |
| 2 | Мобильные экраны, Material 3, локальные Manrope/Lora, темы и дизайн-концепция. Onboarding/navigation/theme прошли тест на Android |
| 3 | setState в формах/графике, Provider для настроек; отдельный InheritedWidget/Provider/setState example в docs/state_examples.dart. Анализ пройден |
| 4 | presentation/domain/data, DI, Repository, Air/Search/History BLoC; unit tests состояний и stale requests пройдены |
| 5 | Реальный Open-Meteo API: текущий US AQI/загрязнители/прогноз, geocoding/search/ID routes. Unit/error tests пройдены; live device acceptance пройден на API 37 |
| 6 | SharedPreferences + SQLite, migration, cache fallback, favorites/recent/history/notes/alerts. Репозиторий проверен тестами; SQLite/cache fallback проверен на API 37; cold offline restart проверен на API 37 |
| 7 | GoRouter named routes, StatefulShellRoute, city ID, guarded account, unknown route; widget tests пройдены. Android back и разные устройства требуют дополнительной приёмки |
| 8 | Firebase/Auth/Firestore/Storage/FCM/Crashlytics code и native config подготовлены. Пользователь подтвердил отсутствие Firebase-проекта; реальные подключения и доставку push ещё надо проверить |

## Реестр всех требований

| Раздел ТЗ | Результат / незавершённое |
|---|---|
| 1. Продукт | Код мониторинга выбранного города и GPS на настоящем API |
| 2. Дизайн | Кремовый/лесной стиль, локальные шрифты, custom forecast graph, светлая/тёмная темы. 320 px + large text test пройден; планшет и весь landscape ещё не проверены |
| 3. Основные экраны | Onboarding, Login/Register, Home, Cities, Map, History, Health, Alerts, Profile; дополнительно Insights/Compare/Notes/Privacy/Account |
| 4. Фишки | Activity Advisor, лучший час, сравнение 2 городов, персональный порог, календарь доступной истории, pollutant insights, favorites, cache, share текста. Визуальная share-карточка и автоматический daily push summary ещё не реализованы |
| 5. Архитектура | Три слоя, Repository/DI, бизнес-логика AQI и рекомендации вне screens |
| 6. State | Provider + BLoC, явные statuses, защита от старых ответов; отдельные учебные примеры |
| 7. API/JSON | http, timeout 18 sec, HTTP/JSON validation, json_serializable, null поля, debounce, stale guards, refresh. Единая шкала US AQI |
| 8. Хранение | SQLite/cache/favorites/recent/notes/samples/alerts; SharedPreferences settings/selected. История — сохранённые текущие модельные оценки, прогноз не записывается как прошлое |
| 9. Navigation | Named GoRouter/StatefulShellRoute/city ID/защищённый account/unknown. Основной мониторинг публичен; аккаунт требует Firebase session |
| 10. Firebase | Реальные вызовы SDK подготовлены, без fake credentials. Auth/Firestore/avatar/FCM/Crashlytics не проверены с облаком. Firestore Rules 6 тестов прошли на local Emulator. Облачное восстановление между устройствами требует завершения/приёмки |
| 11. Maps/GPS | GoogleMap SDK, markers, выбор точки/центра, GPS, native permissions. Maps требует ключ с billing/restrictions; tiles пока не проверены. GPS permission + Android LocationManager + reverse geocoding проверены на эмуляторе |
| 12. Performance | Lazy search/hourly lists, ограниченные выборки, const widgets и Flutter image cache. Полный DevTools профиль не измерен |
| 13. Native | Камера + приватные фото заметок; собственный Kotlin MethodChannel getDeviceInfo (battery/model/sdk). Нативный smoke прошёл; MethodChannel проверен в Android live test; фотографирование и GPS проверены на эмуляторе |
| 14. Tests | 28 unit/widget tests, analyze без замечаний, LCOV 63,00% (1362/2162). main.dart bootstrap и interface places_repository не вошли; generated models включены. Android smoke прошёл; live flow (API/SQLite/cache/notes/channel/notification call) прошёл |
| 15. GitHub/CI | .github/workflows/android.yml: deps/format/analyze/tests/coverage/build + rules/Python. Подготовлен локально, на GitHub не запускался |
| 16. Docs | README с экранами/архитектурой/API/offline/setup/tests/ограничениями, отдельные Dart exercises. Реальные скриншоты сохранены в docs/screenshots |
| 17. Release | Native permissions, conditional Firebase/Crashlytics plugins, real-keystore requirement для release. Debug APK собирался. Release APK/AAB не собраны; подписи/Play publication нет |
| 18. Weeks | Этапы фиксируются здесь |
| 19. Правила | Production AQI не содержит mocks. Внешние конфигурации/доставка/performance не выдаются за проверенные |
| 20. Начало | Продолжен существующий проект; Flutter counter заменён продуктом, нативная Android структура сохранена |

## Подтверждённые проверки

- flutter doctor: Android toolchain и licenses ✓; emulator-5554 Android 17/API 37 обнаружен. iOS intentionally deferred.
- flutter analyze: No issues found (последний прогон).
- flutter test --coverage: 28 passed; LCOV 63,00%.
- mobile_smoke_test: Android onboarding, navigation, light/dark — passed.
- Firestore Emulator: 6/6 правил owner isolation/anonymous/validation/server-only writes — passed.
- Python pure server logic: 3/3 tests — passed; main.py syntax compiled, весь cloud job не проверен.
- Android debug APK несколько раз собран. Финальный app-debug.apk собран из lib/main.dart и установлен; это продуктовая debug-сборка, не integration-test runner.

## Приёмка эмулятора

На исходном AVD с 1 CPU появились process attach timeout и ANR, в том числе задержки системных сервисов. Live API test не запускался до бизнес-проверок. Эмулятор перезапущен без wipe; выполнен cold start с 4 CPU и прежними 2 GB RAM. API 37 требует software GLES в этом окружении. Это ограничение среды, но качество/performance приложения без повторной приёмки не заявляется.

## Внешний следующий шаг

Создать Firebase project, добавить Android package com.example.air_quality_monitor, положить google-services.json в android/app, включить Email/Password + Google, добавить SHA fingerprints, создать Firestore/Storage и опубликовать rules. Отдельно подготовить restricted Google Maps key. Инструкция — README. Backend deployment и billing не выполнялись.

## Обновление мобильной приёмки

После cold start с 4 CPU live Android flow прошёл (22 sec после старта теста): настоящий поиск Алматы, текущий AQI/прогноз, SQLite текущий sample и кеш, кеш при тестовом сетевом сбое, getDeviceInfo, текстовая заметка, вызов native notification и запись истории. Это ещё не подтверждает отображение уведомления в шторке без разрешения, реальную FCM-доставку или камеру.

Нормализовано время получения до миллисекунд, совпадающих с точностью SQLite. Повторный analyze и 28 unit/widget tests прошли. Добавлены Android adaptive launcher icon и branded native splash.

## Финальная Android-приёмка

- GPS: системный permission dialog пройден; Android LocationManager вернул 43.25249 / 76.9115; выбранное место сохранено с GPS ID и reverse-geocoded Almaty. Эмулятор получил координаты через geo fix; физический телефон пока не проверен.
- Camera: настоящий Android camera intent → shutter → Done → Flutter preview → Save. JPEG 28146 bytes сохранён в app_flutter/note_1791901499589529.jpg, запись отображается в заметках. Это фотография виртуальной сцены эмулятора.
- Local notification: включён тестовый порог 25, обновлён реальный US AQI 65; NotificationManager зарегистрировал posted notification, в шторке отображается предупреждение. Это не FCM push. Исходные threshold 100 и alerts=false восстановлены.
- Offline cold start: Wi-Fi и mobile data временно выключены в эмуляторе; после force-stop/start отображается кеш AQI 65 с «Офлайн» и исходным временем 19:44. Оба соединения восстановлены.
- Notification navigation: заменён go на push для сохранения Back stack; новый widget test прошёл. Физическое нажатие/FCM tap требует отдельной приёмки после подключения облака.
- Финальные flutter analyze и 28 unit/widget tests — passed. LCOV 1362/2162 (63,00%). Firestore Rules 6/6 и Python logic 3/3 — passed ранее; исходники этих проверок не изменялись.
- Финальный native Android APK пересобран/установлен. Debug APK поддерживает тестирование; release keystore/AAB и публикация ещё не готовы.

Все тестовые изменения сети эмулятора восстановлены (Wi-Fi/mobile data enabled); персональный порог возвращён к 100, локальные alerts выключены. Приложение оставлено открытым на главной.
