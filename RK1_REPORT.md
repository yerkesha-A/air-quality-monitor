# Air Quality Monitor — отчёт РК1

Дата подготовки: **16 октября 2026**. Платформа защиты: Android. Язык: Dart/Flutter.

Основание: сохранённый владельцем перечень тем недель 1–8. Дословная методичка преподавателя в доступных документах проекта не найдена. Ранее РК1 обозначался как контроль недель 1–7; Firebase недели 8 включён в этот комплект дополнительно по запросу владельца. Дата подготовки новых учебных материалов указана явно. Это подтверждение реализации, а не заявление о своевременной сдаче каждой прошлой недели.

**Статус:** темы известного перечня недель 1–8 подтверждены реализацией и проверками. [Публичный GitHub](https://github.com/yerkesha-A/air-quality-monitor) опубликован с разрешения владельца; README, отчёт, задания, эскизы и снимки доступны без авторизации. Это не заменяет оценку преподавателя по оригинальной методичке.

## Продукт и демонстрация

Цель — помочь жителям городов, студентам, родителям и спортсменам понимать качество воздуха и выбирать время активности. Аналоги: IQAir AirVisual — AQI, Windy — карта, Plume Labs — планирование. Отличия учебного проекта: локальная история, offline-first, сравнение мест, объяснение загрязнителей и персональные настройки.

Данные — настоящие модельные оценки Open-Meteo / Copernicus CAMS. Они не выдаются за показания физического датчика. Приложение не подставляет фиктивный AQI. Фото декоративные и не определяют загрязнение.

Готовый подписанный APK включает native Firebase-конфигурацию: преподавателю не нужно настраивать Flutter, ключи или Firebase. Для свежего AQI, входа и облака требуется интернет; ранее сохранённый AQI доступен офлайн. Исходники без приватной конфигурации сохраняют гостевой режим; воспроизведение Firebase из исходников требует получить конфигурацию у владельца отдельно.

## Матрица недель

| Неделя | Реализовано и чем доказано | Как показать |
| --- | --- | --- |
| 1 | Flutter/Dart/Android toolchain; [исходный Dart-пример](docs/dart_basics.dart); [отдельные задания](coursework/week01/README.md): null safety, классы, коллекции, async/await, исключения, Stream; Git с локальной историей; README с целью/аудиторией/аналогами/экранами. [GitHub](https://github.com/yerkesha-A/air-quality-monitor) опубликован, публичный доступ проверен. | `dart run coursework/week01/exercises.dart`; открыть README и историю Git |
| 2 | Более 4 экранов; Material 3 в [теме](lib/core/theme/app_theme.dart); светлая/тёмная/системная темы; [эскизы](docs/rk1/wireframes.svg), составленные сегодня по утверждённому интерфейсу; реальные [скриншоты](docs/rk1/SCREENSHOTS.md) | Сегодня → История → Профиль; переключение темы |
| 3 | setState в формах/графике; Provider для настроек/аккаунта/мест; отдельный настоящий InheritedWidget в [учебном примере](docs/state_examples.dart); сравнение подходов в README; [widget-тест](test/coursework_test.dart) проверяет независимые обновления и сохранение модели при rebuild | Открыть пример в исходниках; запускать отдельный target только на учебном AVD, чтобы не заменять основное приложение |
| 4 | [presentation](lib/presentation), [domain](lib/domain), [data](lib/data); Air/Search/History BLoC; Repository interfaces и реализации; constructor DI через [AppDependencies](lib/core/di/app_dependencies.dart); [BLoC-тесты](test/bloc_test.dart) | Показать путь Screen → BLoC → Repository → API/SQLite и внедрение mock в тестах |
| 5 | [REST-клиент](lib/data/remote/open_meteo_api.dart), generated JSON DTO, timeout 18 c; loading/error/empty; debounce 400 мс с защитой от устаревшего ответа; pull-to-refresh. [API-тесты](test/api_test.dart), [BLoC-тесты](test/bloc_test.dart); ранее подтверждён настоящий ответ на Android | Поиск города, текущий AQI, обновление; ошибки/empty воспроизводимы тестами, без выдуманных значений |
| 6 | SharedPreferences: тема/единицы/порог/onboarding/выбор; [SQLite](lib/data/local/local_store.dart): кеш/история/избранное/заметки/уведомления; миграции; [offline-first Repository](lib/data/repositories/open_meteo_repository.dart); [тесты](test/repository_test.dart). Данные основного AVD восстановлены и проверены | История; сохранённый выбранный город; отключение сети после загрузки показывает кеш, а не новые данные |
| 7 | [GoRouter](lib/core/router/app_router.dart): StatefulShellRoute с независимыми ветками; `/city/:id`, query `mode=register`, guard `/account`, error route; SafeArea/scroll/max width; [widget-матрица](test/screens_test.dart) телефонов/планшетов и обеих тем | Переключение вкладок, системный Back; параметры и guard показать кодом/тестом, не выходя из профиля владельца |
| 8 | Настоящие Email/Password и Google Firebase Auth; Firestore profile/favorites/device tokens; [Security Rules](firestore.rules); 6 правил-тестов в demo Emulator; настоящие FCM foreground/background/terminated + tap; release Google-вход и сессия после cold process restart | Открыть профиль; показать подтверждения ниже. Регистрационные тесты используют отдельный тестовый аккаунт, не аккаунт владельца |

## Реальные Firebase-доказательства

- [Этап 2](docs/STAGE2_FIREBASE_ANDROID.md): native Firebase registration/login, неверный/слабый пароль, duplicate email, logout/login, серверное чтение/запись Firestore, запрет чужого доступа; настоящая доставка FCM foreground/background.
- [Профиль](docs/PROFILE_FIREBASE_VERIFICATION.md): Google chooser, прежний UID после повторного входа, route guard и сохранение настроек; реальное письмо восстановления доставлено. Изменение пароля по ссылке отдельно не подтверждено и для известного списка РК1 не требуется.
- [Восстановление](docs/ANDROID_RECOVERY_VERIFICATION.md): отдельный release AVD, SHA-1/SHA-256 существующего upload-ключа зарегистрированы; SDK-конфигурация обновлена без смены проекта/ключа. Resource shrinking исправлен для динамических Firebase/OAuth-строк и notification icon. Владелец подтвердил успешный Google-вход; UID совпал с прежним профилем. После полного завершения процесса профиль восстановлен без повторного входа.
- FCM отправлен через HTTP v1 на существующий токен; перед отправкой процесс отсутствовал, системное уведомление найдено, запись появилась в SQLite, tap открыл «Уведомления». Это настоящий push, не локальная имитация. Серверный ежедневный AQI scheduler не развёрнут и не заявляется работающим.
- Новое контролируемое non-fatal событие Crashlytics подтверждено серверным API. Fatal crash специально не вызывался.

Private logs, UID, токены, app data и личные скриншоты хранятся только в игнорируемых резервных копиях. Публичный отчёт содержит результаты и пути к исходникам, не секреты.

## Финальная проверка

Актуальные команды, результаты и hashes артефактов: [VALIDATION.md](docs/rk1/VALIDATION.md).

Новые материалы 16.10.2026: расширенные самостоятельные Dart-задания, тесты учебных примеров, ретроспективные эскизы, этот отчёт, сценарий защиты и комплект сдачи. Production-дизайн и архитектура сохранены.

## Google Maps и граница РК1

Нативная реализация существует: [MapScreen](lib/presentation/screens/map_screen.dart), [MapAirController](lib/presentation/controllers/map_air_controller.dart), [маркеры AQI](lib/presentation/widgets/aqi_marker.dart). Контроллер покрыт тестами. Настоящие tiles и native gestures пока **не приняты**: billing отключён, API key отсутствует. Официальная [документация Google](https://developers.google.com/maps/documentation/android-sdk/usage-and-billing) требует billing. Подключение без разрешения не выполнялось.

Существующую реализацию можно продолжить сегодня после решения владельца: billing → Maps SDK for Android → ограниченный package/SHA ключ → native-проверки карты. Срок и отсутствие расходов гарантировать нельзя. По предоставленному списку недель 1–8 Google Maps не отдельный критерий РК1; карту не выдаём за готовую и не задерживаем сдачу из-за неё.

## Что отправить

[Памятка сдачи](docs/rk1/SUBMISSION.md) и [сценарий на 5 минут](docs/rk1/DEFENSE_5_MIN.md). [GitHub](https://github.com/yerkesha-A/air-quality-monitor) доступен без авторизации; [проверка публикации](docs/rk1/GITHUB.md). Публикация в Google Play не нужна и не выполнялась.
