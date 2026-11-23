# Финальный аудит Air Quality Monitor: недели 1–15

Проверка начата 23.11.2026. Основание — присланный владельцем перечень недель 1–8 и 13 категорий, а также сохранённые требования недель 9–15. Проверка использует сохранённые задания и уточнения владельца; дополнительные критерии не приписываются преподавателю.

Статусы ниже различают реализацию, проверку и материалы. «Историческая проверка» означает реально сохранённый предыдущий результат, а не новый запуск. Текущие изменения локальны: push и новая публикация запрещены до разрешения владельца.

## Все 15 недель

| Неделя | Обязательные пункты и реальный код | Проверки и материалы | Итог текущего аудита |
|---|---|---|---|
| 1 | Dart null safety, классы/конструкторы, коллекции, условия, async/await, исключения, Stream: `coursework/week01/exercises.dart`, `docs/dart_basics.dart`. Flutter/Dart/Android toolchain, GitHub, README с целью, аудиторией, аналогами и экранами | Оба Dart target выполнены. `coursework_test.dart` проверяет границы, null, неизменяемость, timeout и Stream. Публичный репозиторий существует; новые учебные материалы честно датированы 16.10 | Реализовано; пропущенных отдельных заданий из известного списка не обнаружено |
| 2 | Более четырёх экранов, Material 3, light/dark/system: `app_theme.dart`, экраны `presentation/screens`; эскизы `docs/rk1/wireframes.svg` | `screens_test.dart` — телефоны, планшеты, крупный текст, обе темы; настоящие скриншоты РК1/РК2 | Реализовано; исходный дизайн сохранён, текущая доработка касается карты |
| 3 | Реальные setState, собственный CounterScope/InheritedWidget и Provider в `docs/state_examples.dart`; производственные Provider для settings/auth/places; сравнение в README | `coursework_test.dart` нажимает три независимых счётчика и проверяет сохранение Provider при rebuild | Реализовано, а не только описано |
| 4 | Air/CitySearch/History BLoC; presentation/domain/data; контракты Repository; конструкторный DI через `AppDependencies` | `bloc_test.dart`, repository tests, внедрение mocktail в test dependencies | Реализовано; рабочая архитектура не переписывалась |
| 5 | Настоящий Open-Meteo HTTP, JSON DTO/генерация, timeout 18 с, HTTP/JSON ошибки, loading/error/empty, debounce 400 мс, stale-response guard и pull-to-refresh | `api_test.dart`, `bloc_test.dart`; build_runner реально выполнен без изменения generated DTO; Android `air_flow_test.dart` получает настоящий AQI | Реализовано; фиктивный AQI в production не добавлен |
| 6 | SharedPreferences; SQLite cache/places/samples/notes/alerts, миграции и индексы; избранное, история, offline-first | repository/freshness/cloud tests; Android тест сохраняет API-ответ в реальную SQLite и проверяет fallback при тестовом сбое клиента. Реальная offline-карта ранее проверена на release | Реализовано; таблицы и данные пользователя не очищаются |
| 7 | GoRouter: StatefulShellRoute, четыре независимые ветки, `/city/:id`, query mode, guard аккаунта, error route; адаптивность | `screens_test.dart`, `widget_test.dart`, account tests: переходы, неизвестный маршрут, параметры, guard и разные размеры | Реализовано |
| 8 | Firebase Auth Email/Password + Google, Firestore, Security Rules, настоящая FCM. Код: `firebase_auth_repository.dart`, `firebase_service.dart`, `cloud_sync.dart`, `firestore.rules` | Rules 6/6; настоящие registration/login/server-read/restore/foreign-UID-denial и FCM foreground/background/terminated проверены на отдельном API 30. Google-вход ранее подтверждён владельцем; сертификат текущего ключа повторно сверен read-only | Реализовано; свежий интерактивный Google-вход новой сборки нельзя заменить проверкой конфигурации |
| 9 | Карта OSM, реальные маркеры/карточки, камера/zoom, города/точки, geolocator, разрешения/ошибки, debounce и bounded cache, атрибуция | Map/controller/location tests и нативные OSM tile/GPS проверки. Добавлены компактная карточка, легенда, группировка, защита от обрезания/пересечений и читаемый текст | Рабочая OSM-реализация; дословное требование Google Maps остаётся частичным до согласования преподавателя |
| 10 | ListView.builder и SliverList.builder, настоящая keyset infinite scroll заметок/уведомлений, paging истории, cached_network_image с placeholder/error и приоритетом локальной фотографии; dispose и ограничение запросов | `infinite_records_test.dart`, `pagination_test.dart`, native SQLite paging и HTTP disk cache; новые парные DevTools карты 23.11 на API 30 / 2048 MiB; FrameTiming/Memory JSON; прежние результаты 16.11 сохранены | Реализовано; [новый замер](../WEEK_10.md) не доказывает общее ускорение: raster p95 вырос, доля медленных кадров снизилась; 60 FPS и отсутствие утечек не обещаются |
| 11 | Камера/галерея/отмена/ошибки/локальный аватар; собственный Kotlin MethodChannel getDeviceInfo и notImplemented | account/location/device unit/widget tests; новый Android camera/gallery/channel/FCM/disk-cache прогон и отдельный перезапуск прошли; [результат](evidence/native-android.json) | Эмулятор подтверждён; обязательное физическое устройство не проверено — частично по этому подпункту |
| 12 | GitHub Actions: pub get, format, analyze, tests, coverage, APK и artifacts, Rules job | Последний опубликованный run 45177924926 для 86e2acd успешен. Workflow дополнен форматированием нового test_driver. Новые изменения не отправлены | Конфигурация и прежний CI подтверждены; новый remote run ждёт разрешения на push |
| 13 | Unit, mocktail, widget, integration, coverage >40%, проверки в CI | 108/108; LCOV 2762/3693 = 74,79%; analyze без замечаний — [результаты](evidence/RESULTS.json). Integration тесты используют отдельный QA-AVD и сохраняют установку; добавлен предохранитель от изменения onboarding на устройстве владельца | Локальные unit/widget и нативные программы пройдены; 3 FCM-сценария повторно проверены на обычной debug-сборке |
| 14 | Существующий keystore, package/версия/icon/splash, APK+AAB, obfuscate/split-debug-info, Crashlytics, пакет Google Play, App Distribution, App Store outline | `android/app/build.gradle.kts`, native ресурсы; новые APK/AAB 1.1.0 (3) собраны, подписи обоих сверены с существующим ключом ([проверка](evidence/release-verification.json)). Старый App Distribution 1.1.0 (2) доступен, новый build 3 не публикуется. Контролируемый non-fatal ранее подтверждён в Console | Новый локальный выпуск собран и подписи проверены без смены ключа. Публикация и свежий интерактивный Google-вход требуют отдельных подтверждений |
| 15 | Демонстрация, архитектура/state, Firebase/offline/native, DevTools, tests/CI/release; презентация 7–10 мин, речь и вопросы; общий отчёт РК2 недель 8–15 | `docs/rk2/RK2_PRESENTATION.pptx/.pdf`, `DEFENSE.md`, `MAC_DEMO.md`; текущая карта и результаты добавлены в комплект | Комплект обновлён: 13 слайдов PPTX/PDF, сценарий 520 с, 13 вопросов, свежие release-скриншоты; ограничения названы прямо |

## Результаты, которые нельзя подменять

- OSM не является Google Maps. Billing остаётся выключенным.
- GPS emulator geo fix и виртуальная камера не являются проверкой реальных датчиков телефона.
- Запись тестировщика и активность App Distribution не доказывают физическую установку APK.
- Успешный старый CI не доказывает успех ещё не отправленной рабочей копии.
- Настоящие прежние DevTools-скриншоты сохранены; они не переименовываются в замеры новой версии.
- Отчёт Crashlytics в DataTransport и видимость события в Console — разные подтверждения.
- Отдельные дополнительные пожелания (ежедневный серверный scheduler, английская локализация, публикация iOS) не выдаются за выполненные и не добавляются произвольно в присланные 13 обязательных категорий.

## Сохранность

Основной AVD закрыт. Release AVD дополнительно скопирован до обновления. QA выполняется на отдельном API 30 / 2048 MiB / 2 CPU. Не выполняются wipe, uninstall, flutter clean, очистка SQLite, удаление резервных копий, смена Firebase/OAuth/keystore, billing или публикация. Новый build — 1.1.0 (3); build 2 и его материалы остаются сохранёнными отдельно.

## Переключение режимов сборки

При последовательном переходе profile → release обнаружен устаревший сгенерированный Android plugin registrant: он ссылался на dev-only integration_test, исключённый из release. Повторная штатная сборка с pub get регенерирует registrant для нужного режима. `flutter clean`, ручное удаление generated-файлов и изменение зависимостей для обхода ошибки не используются. Это ошибка подготовки сборки, а не повреждение пользовательских данных.

## Свежие нативные результаты

- [Карта](evidence/map-android.json): настоящий AQI, 4 сохранённых OSM-тайла, раскрытие карточки, выбор точки из группы, метки внутри карты без пересечений, видимая атрибуция. GPS в этом строгом прогоне отключён флагом; отдельный geo-fix ранее 23.11 зафиксирован приватным результатом и не подменяет физический GPS.
- [Email и Firestore](evidence/firebase-auth-android.json): слабый/неверный пароль и дубликат отклонены; настоящая регистрация и повторный вход, серверное чтение, восстановление избранного/настроек и запрет чужого UID прошли.
- [Native](evidence/native-android.json): настоящий foreground FCM, camera/gallery, MethodChannel и disk cache после остановки HTTP-сервера; тот же UID и фото после полного перезапуска. Первый host-прогон галереи превысил таймаут при ручном выборе; полный повтор с системным DPAD-подтверждением прошёл.
- Google Play Services лёгкого API 30 устарели относительно Google Sign-In SDK. Свежий интерактивный Google-вход на этом стенде не подтверждён; конфигурация проверена read-only, предыдущий успешный release-вход владельца сохранён в исторических материалах. Не скачиваются APK Google Services из сторонних источников и не запускается тяжёлый API 37 ради обхода ограничения.

## Исправление истории фоновых push

Обнаружено 23.11: системный notification+data push появился и открыл `/alerts`, но его уникальная запись отсутствовала в истории. На Android отображение notification payload системой не гарантирует выполнение Dart background callback. Поэтому сообщение дополнительно сохраняется при `onMessageOpenedApp` и `getInitialMessage`, **до** навигации. Первичный ключ `messageId` и `ConflictAlgorithm.ignore` защищают от дублирования с background handler.

Коммит `8651180`; два новых теста проверяют ожидание завершения SQLite-записи перед переходом и data-only payload. После исправления **108/108**, analyze без замечаний, **74,79%**. Прежние бинарники и символы сохранены отдельно; новые артефакты и нативная приёмка фиксируются в итоговых доказательствах.

С разрешения владельца удалена **только** пересоздаваемая `build/app/intermediates` (3,4 ГБ): эмулятор отказывался запускаться при 1,7 ГБ свободного места. Готовые артефакты и символы проверены до удаления, исходники, ключи, AVD, приложения и резервные копии сохранены. `flutter clean` не выполнялся.

### Причина `database_closed` в фоне

Нативная трассировка подтвердила вызов обработчика нажатия Firebase, затем logcat показал `DatabaseException(database_closed 1)`. `LocalStore.open()` по умолчанию использовал общий native singleton sqflite. Background isolate открывал этот же handle и закрывал его в `finally`, делая UI-соединение непригодным. Фоновое открытие теперь использует `singleInstance: false`, обычный UI оставляет прежний singleton. Схема базы не изменяется, записи не удаляются.

Добавлен настоящий Android-тест `integration_test/push_database_test.dart`: отдельное фоновое соединение пишет запись и закрывается, UI-соединение после этого читает её и выполняет `PRAGMA integrity_check`. Нативный регрессионный тест прошёл. На обычной сборке прошли foreground, background и terminated delivery, переходы и история. Тестовая ADB-обвязка также приведена к launcher Intent, как запуск по значку Android.

### Окончательная FCM-приёмка исправления

Коммит `9427a22`. [Регрессионный SQLite-тест](evidence/push-database-android.json) пройден. [Foreground](evidence/fcm-foreground-final.json) записан один раз, ошибок `database_closed` в текущем процессе нет. [Background](evidence/fcm-background.json): 6,85 с до отображения, tap открыл историю с уникальной записью. [Terminated](evidence/fcm-terminated.json): процесс отсутствовал без force-stop; 4,46 с до отображения, tap запустил приложение и открыл историю с записью. Это результаты эмулятора, не телефона.

## Финальный release и сохранность данных

[Подписанный APK установлен через -r](evidence/release-install.json); хеш установленного base.apk совпадает с обычным финальным APK, QA entrypoint возвращён на production. [Сравнение данных](evidence/release-data-preservation.json): integrity_check до/после — ok, все старые ключи истории и избранное сохранены, настройки/выбранный город совпали, фото не изменилось. На тестовом release AVD изначально не было заметок; это не выдаётся за проверку непустой коллекции. Основной пользовательский AVD оставался закрытым.

[Аккаунт](evidence/release-account-identity.json) восстановлен на живом экране. Native Firebase хранит запись зашифрованно: токены не расшифровывались; идентичность проверена по тому же email, ранее проверенному SDK UID и UID-каталогу локального фото.

[Crashlytics](evidence/crashlytics.json): однократный non-fatal build 3, SDK DataTransport + HTTP 200, **владелец подтвердил новое событие в Console**. [QA и normal symbols](evidence/crashlytics-symbols.json) загружены в существующий закрытый Firebase для расшифровки. APK/AAB не отправлялись в App Distribution или Play.

[Свежие release-скриншоты](../rk2/screenshots): главная, компактная/раскрытая карта, легенда, landscape и dark. [Подтверждение UI](evidence/release-map-ui.json), [эмуляторный GPS](evidence/release-location.json). Это модельные данные Open-Meteo/CAMS, не показания физического датчика.

Дополнительно три FCM-состояния проверены в **обычном подписанном release**: [foreground](evidence/fcm-release-foreground.json), [background](evidence/fcm-release-background.json), [terminated](evidence/fcm-release-terminated.json). В итоговой базе ровно три новые тестовые записи; прежние данные сохранены.
