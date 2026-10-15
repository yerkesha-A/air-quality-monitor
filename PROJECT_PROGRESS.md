# Air Quality Monitor — прогресс

Обновлено: 15 октября 2026. Рабочая платформа: Android. iOS отложен по прямому указанию пользователя.
Статус «код готов» не равен подтверждённой облачной интеграции.

Текущий этап: полный редизайн по новому референсу из 10 экранов. Общие AirScaffold/AirBackdrop/AirSurface; обновлены все существующие маршруты, onboarding, четыре вкладки, авторизация и шторка города. Checkpoint перед работой: `b30198e`. API, SQLite, Firebase и iOS не перенастраивались. Подробная приёмка и снимки — docs/DESIGN_REVIEW.md.

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
| 2. Дизайн | Голубой горный стиль, локальные шрифты, интерактивный forecast graph, светлая/тёмная темы. 320 px + large text test пройден; планшет и весь landscape ещё не проверены |
| 3. Основные экраны | Onboarding, Login/Register, Home с CityPickerSheet, Map, History, Health, Alerts, Profile; дополнительно Insights/Compare/Notes/Privacy/Account |
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

Создать Firebase project, добавить Android package `com.example.air_quality_monitor`, положить настоящий `google-services.json` в `android/app`, включить Email/Password. Сообщить Project ID и готовность файла. Пошаговая инструкция — [ANDROID_FIREBASE_SETUP.md](docs/ANDROID_FIREBASE_SETUP.md). Google Sign-In подготовлен, его приёмка будет отдельной; Firestore/Storage/FCM/Maps сейчас не подключаются. Backend deployment и billing не выполнялись.

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

## Среда проверки текущего редизайна

При повторной установке возник сбой графического режима API 37 и системного activity service (Broken pipe/DEAD_OBJECT). Перезапуск первоначально остановился на crash consent dialog SDK. Для приёмки тот же AVD запущен без wipe/snapshots с 4 CPU, SwiftShader, отключённым guest Vulkan, без метрик и отчётов. Системная загрузка подтверждена sys.boot_completed=1. Постоянный config.ini AVD не менялся; данные приложения сохранены. Gradle daemon завершён после сборки для освобождения памяти.

Мобильная приёмка этапа 2: Сегодня/История/Карта/Профиль открываются, city sheet с главной работает. Выбор Алматы загрузил реальный AQI 64 на 22:00 и свежий fetchedAt; затем исходно выбранный Шымкент восстановлен. История Шымкента показала две сохранённые оценки 74/73, среднее 73.5 и максимум 74.0. Форма входа проверена визуально в состоянии отсутствующей Firebase-конфигурации. Фиктивная регистрация не выполнялась. Финальная правка контраста оси прошла analyze и все 41 тест; APK пересобран.

Календарь проверен на Android: нажатие 13 октября открыло настоящий результат `73.5 US AQI`, среднее по 2 сохранённым точкам, «Умеренный». Фиктивные значения не добавлялись. Финальная сборка установлена, Шымкент восстановился после перезапуска; приложение оставлено на «Сегодня». Актуальные снимки — android-atmospheric-home/history, android-history-calendar, android-auth-ready в docs/screenshots.

## Fresh Air UI — 15 октября 2026

Checkpoint перед изменениями: `bbf3b19`. Новая палитра milk/sky/dusty blue/teal, единая типографика, холодные градиентные AirSurface. Главная сохранила структуру; PM₂.₅ выделен, мини-графики показывают только реальные непрерывные прогнозные значения API (до 8 часов), а не искусственный уровень риска. Планы прогулки/пробежки используют прежний AirAdvice. История сохранила структуру и SQLite, лес заменён локальным пейзажем гор/неба и холодным стеклом. Профиль: фотографический верхний блок, аккаунт и группы настроек. Формы авторизации адаптированы под голубой стиль.

В полях имени/email/пароля и поиска отключён Android stylus handwriting; Next переводит фокус, Done закрывает клавиатуру и без Firebase. Android использует Gboard; secure stylus_handwriting_enabled не имеет явно заданного значения. Системные настройки клавиатуры не менялись. Widget-тест: 320 px, текст 150%, клавиатура 280 px, редактирование, Next/Done — пройден.

`flutter analyze`: чисто. `flutter test`: 42/42. Debug APK собран.

Финальный APK установлен поверх существующего приложения на Android 17 / API 37 с сохранением данных. Снимки главной, состава воздуха, планов, истории, профиля и обычной клавиатуры сохранены как `docs/screenshots/android-fresh-*.png`; ссылки собраны в docs/DESIGN_REVIEW.md. Недельная история в финальной сборке показывает корректную подпись «4 точки».

Firebase CLI 15.33.0 уже был локально установлен в tools/firebase-tests; авторизованных аккаунтов нет. FlutterFire CLI 1.4.1 установлен и версия проверена. По уточнению пользователя «Пока закончить только редизайн» браузерный вход не запускался, список облачных проектов не проверялся, проект/платные ресурсы не создавались. Подключение через FlutterFire и реальная auth-приёмка ждут отдельного продолжения. Maps/iOS не изменялись.

Проверка клавиатуры на Android: в email открылась обычная QWERTY Gboard, боковой панели стилуса нет. Ввод/удаление тестовых символов и Next перевели фокус с email на пароль; после ввода abc и Backspace остались две маскированные позиции, Done скрыл клавиатуру. Форма не отправлялась, аккаунт не создавался; тестовый текст удалён закрытием формы. Снимок обычной клавиатуры: docs/screenshots/android-fresh-keyboard.png.


## Полный редизайн по референсу — 15 октября 2026

Перед изменениями сохранён checkpoint `b30198e`. Обновлены все существующие экраны:
Today, Map, History, Profile, Login/Register, Onboarding, Alerts, Health, Insights,
Compare, Notes, Privacy, Account, CityLink и нижняя шторка CityPicker. Новых
дублирующих страниц города/вкладки городов нет. Общая система прозрачных поверхностей,
фотографические фоны, компактный AQI и сетка загрязнителей, новая группировка профиля.
Источники/лицензии изображений записаны в assets/images/CREDITS.md; два новых WebP
в сумме 110,492 байта. API, база, auth backend и разрешения не менялись.

Финальные flutter analyze — без замечаний, flutter test — 43/43, debug APK собран.
Добавлен проход дополнительных экранов при 320 px и шрифте 150% в обеих темах;
сохранены проверки формы, keyboard inset, onboarding и landscape.
APK установлен поверх приложения на Android 17 / API 37 без удаления данных.

Уточнение по клавиатуре: выключенный stylusHandwritingEnabled в Flutter сам по себе
не устраняет боковой режим Gboard. На этом AVD подключены физическая клавиатура
и виртуальные стилусы. Для обычного экранного ввода настроены только secure settings
эмулятора: show_ime_with_hard_keyboard 0 → 1, stylus_handwriting_enabled null → 0,
Gboard перезапущена без очистки данных. Повторно подтверждена QWERTY снизу,
набор abc + Backspace дал ab, Next передал фокус паролю; пароль после такого же
редактирования содержал две маскированные позиции. Done скрывает клавиатуру.
Форма не отправлялась, тестовый текст удалён закрытием экрана. Приложение не пишет
эти системные настройки на пользовательских телефонах. Тема после native проверки
тёмного оформления возвращена в исходную «Как в системе».

Firebase/Maps/iOS по-прежнему отложены. Текущая карта проверяется только в честном
состоянии отсутствующего API-ключа; реальная авторизация и подключённая карта
не объявлены прошедшими приёмку.

Итоговые реальные снимки: docs/screenshots/android-reference-home/history/profile,
profile-dark/login/register/keyboard/alerts/map.png. Ссылки — docs/DESIGN_REVIEW.md.
Дополнительная команда native-проверки шторки и планов отклонена пользователем;
повтор не выполнялся. Открытая шторка не попала в итоговый снимок, вместо неё
сохранён только проверенный кадр главной. Соответствующие сценарии покрыты тестами.
