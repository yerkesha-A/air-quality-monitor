# Аудит Air Quality Monitor: недели 1–15 и подготовка iOS

Дата: **25.11.2026**. Основа до изменений — опубликованный коммит `b82e52b`. Код и материалы опубликованы до `70cda03`; [CI 45628248353](https://github.com/yerkesha-A/air-quality-monitor/actions/runs/45628248353) прошёл успешно. Последующие изменения протокола не меняют код приложения `7cfbb9b`. App Distribution и публикация магазинов не выполнялись.

## Источник требований и границы проверки

Отдельного оригинального университетского PDF/документа с дословными заданиями всех 15 недель в репозитории **нет**. Для недель 1–8 использован ранее присланный пользователем список и `RK1_REPORT.md`. В предыдущих приложенных пользователем текстах найдены подробные требования недель 9–11 и 9–15; это сообщения пользователя с разделами «Требования преподавателя», не независимо проверенный университетский оригинал. Их содержание сопоставлено с `docs/WEEK_09.md` — `WEEK_15.md`, `PROJECT_PROGRESS.md` и `docs/REQUIREMENTS_AUDIT.md`. Новые условия преподавателю не приписываются.

Проверены исходники `lib`, Android/iOS, `coursework`, `test`, `integration_test`, workflow и материалы. Запись «Выполнено» относится к **известному перечню**, а не гарантирует совпадение с отсутствующим оригиналом или оценку преподавателя. Исторические нативные результаты 16/23.11 сохранены с их датами и не выдаются за новый запуск. Документ сам по себе не является доказательством работы.

## Все 15 недель

| Неделя | Требования | Реализация | Проверка | Статус | Что исправить |
|---|---|---|---|---|---|
| 1 | Flutter/Dart; null safety, классы, коллекции, async/await; отдельные задания, GitHub, README | `coursework/week01/exercises.dart`, `docs/dart_basics.dart`, README; цель, аудитория, аналоги и экраны | Оба Dart target; `test/coursework_test.dart`; существующий публичный GitHub | Выполнено | Дословного задания преподавателя нет; учебные материалы добавлены 16.10, не выдаются за раннюю сдачу |
| 2 | Несколько экранов, Material 3, светлая/тёмная темы, эскизы | `core/theme/app_theme.dart`, `presentation/screens`, `docs/rk1/wireframes.svg` | `screens_test.dart`, `widget_test.dart`, скриншоты Android; новые iPhone layout tests | Выполнено | Нативный iOS ещё не проверен; это отдельная адаптация, не доказательство недели 2 на iPhone |
| 3 | setState / InheritedWidget / Provider, сравнение | `docs/state_examples.dart`: три работающих примера; production Provider настроек/auth/places; сравнение README | `coursework_test.dart` нажимает счётчики, проверяет rebuild/сохранение Provider | Выполнено | Примеры учебные, архитектура приложения не подменена искусственными счётчиками |
| 4 | BLoC, presentation/domain/data, Repository, DI | `AirBloc`, `HistoryBloc`, `CitySearchBloc`; domain-контракты, data-реализации, `AppDependencies` | `bloc_test.dart`, `repository_test.dart`, mocktail/инъекция зависимостей | Выполнено | Переписывание архитектуры не требуется |
| 5 | REST/JSON, timeout, loading/error/empty, debounce, refresh | `open_meteo_api.dart`, generated `air_dto.g.dart`; 18 с timeout; 400 мс debounce; pull-to-refresh | `api_test.dart`, BLoC tests; свежий настоящий HTTP Open-Meteo и Android integration | Выполнено | API — модель Open-Meteo/CAMS, не датчик телефона или ближайшая станция |
| 6 | SharedPreferences + SQLite, избранное, история, кэш, offline-first | `local_store.dart` schema v3; настройки/selected place, кеш ответов, история только current, заметки/alerts; `OpenMeteoRepository` | repository/freshness/pagination/cloud tests; настоящая SQLite/offline integration; сверка данных release AVD | Выполнено | Fallback использует сохранённый ответ с отметкой offline/stale; старые записи не очищались вручную |
| 7 | GoRouter: параметры, вложенная навигация, guard, адаптивность | `/city/:id`, query login mode, `StatefulShellRoute` с четырьмя ветками, guard `/account`, error route | `screens_test.dart`, account/widget tests; разные размеры и темы, новый iPhone keyboard/inset matrix | Выполнено | Настоящие iOS-переходы/жесты проверить после установки Xcode |
| 8 | РК1 по 1–7; Firebase Auth Email/Password + Google, Firestore, Security Rules, FCM | `firebase_auth_repository.dart`, `firebase_service.dart`, `cloud_sync.dart`, `firestore.rules`; исправление SQLite background handle сохранено | SDK mocks + Rules; настоящие Auth/server reads/FCM 23.11; свежая read-only SHA/provider проверка 25.11 | Частично выполнено | Свежий интерактивный Google-вход текущей версии не повторён: Play Services лёгкого AVD устарели. Прежний успешный release-вход подтверждён пользователем, но не заменяет новую приёмку |
| 9 | Google Maps, маркеры/камера/инфокарточка, GPS, разрешения/отказ, тематические данные | Реальная **OpenStreetMap/flutter_map**, Open-Meteo AQI/PM, marker grouping, легенда, компактная карточка, debounce/ограниченный кеш; `map_air_controller.dart`, `map_screen.dart`, `location_service.dart` | Map/controller/layout/location tests; реальные OSM tiles/GPS 23.11, текущий release smoke | Частично выполнено | Требуется согласование OSM вместо Google Maps. Billing не включается. Физический GPS ещё не принят |
| 10 | ListView.builder, infinite pagination, cached_network_image, const/dispose, DevTools Performance/Memory до/после | `infinite_records.dart`, keyset SQLite pagination; cached avatar с placeholder/error, local photo приоритетен; ограничение запросов и cleanup контроллеров | `infinite_records_test.dart`, pagination/map tiles/avatar tests; настоящие native cache/paging результаты 23.11; DevTools 16/23.11 | Выполнено | Slow frames остаются. Есть реальные парные измерения, но стабильные 60 FPS/отсутствие утечек не доказаны; сравнение карты смешанное, не объявляется общим ускорением |
| 11 | Камера/датчики, собственный Kotlin MethodChannel, физический Android | `image_picker`, `local_avatar_store.dart`, Kotlin `MainActivity`, Dart `DeviceService`; iOS Swift-эквивалент подготовлен отдельно | Unit/widget отмены/ошибок; камера/галерея/channel и сохранение фото на Android-эмуляторе 23.11 | Частично выполнено | Физического Android нет. iPhone не закрывает требование физического Android. Свежая Android-сборка и проверка данных не заменяют аппаратную камеру |
| 12 | GitHub Actions: pub get, format/analyze/test/build apk, APK artifact | `.github/workflows/android.yml`; Android и отдельный Rules job; ограниченные permissions, без credentials в CI | Последний опубликованный `70cda03`: run **45628248353 success**, оба jobs; APK artifact проверен read-only | Выполнено | Код приложения проверен новым CI 45628248353; iOS native build в этом Android workflow не выполняется |
| 13 | Unit, mocktail, widget, integration, coverage >40%, тесты в CI | Полный `test/`, защищённые `integration_test/`; новые iOS APNs/permissions/layout tests | Свежие analyze, flutter test --coverage, native air_flow; прежние нативные протоколы; CI опубликованной версии | Выполнено | Widget platform override — не доказательство нативного запуска iOS. Итоговые числа — в протоколе ниже |
| 14 | Подписанные APK/AAB, icon/splash/version, obfuscate/symbols, Crashlytics, материалы магазинов, App Distribution | Существующий keystore; `1.1.0+3`; подписанные новые Android APK/AAB; docs/store; Crashlytics; App Store outline | Подписи сверены с существующим сертификатом; non-fatal build 3 подтверждён в Console 23.11; read-only App Distribution 25.11 | Частично выполнено | App Distribution содержит прежний build 2; свежий Google-вход и доставка последней сборки остаются. Новую доставку/публикацию без разрешения не выполнять |
| 15 | РК2 по 8–15, презентация 7–10 минут, архитектура, демо, tests/DevTools/release | `docs/rk2/RK2_PRESENTATION.pptx/.pdf`, DEFENSE, QUESTIONS, MAC_DEMO, RK2_REPORT; материалы РК1 сохранены | Реальные скриншоты Android; 13 слайдов, сценарий 520 с; комплект `submission/FINAL_RK1_RK2_2026-11-23` сохранён | Выполнено | Это готовность материалов, не заявление о выполнении открытых пунктов 8/9/11/14. Старый комплект имеет дату/свои бинарники и не переименован в новый |

**Итого по известному списку: 11 недель — «Выполнено», 4 — «Частично выполнено» (8, 9, 11, 14).** Нет основания называть весь проект полностью принятым. Отдельные iOS-функции пока имеют статус «Невозможно проверить» из-за окружения.

## Отдельно: 13 обязательных категорий

| № | Требование | Проверенное основание | Статус / ограничение |
|---|---|---|---|
| 1 | Архитектура Dart | Domain entities/contracts, data implementations, presentation, DI; отдельные Dart targets/tests | Выполнено |
| 2 | Material 3 | ThemeData/useMaterial3, обе темы, responsive widget matrix | Выполнено на Flutter/Android; iOS native pending |
| 3 | Provider + BLoC/Riverpod | Provider settings/auth/places + реальные три BLoC; не требуется одновременно Riverpod | Выполнено |
| 4 | REST API / JSON | Реальный Open-Meteo, json_serializable DTO, timeout/errors/debounce/refresh | Выполнено |
| 5 | SharedPreferences + SQLite | Настройки, кеш, samples/places/notes/alerts, offline-first и paging | Выполнено |
| 6 | GoRouter | StatefulShellRoute, параметры, query, guard, error route | Выполнено |
| 7 | Firebase | Auth/Firestore/Rules/FCM исходники + реальные Android результаты | Частично по повторной Google-приёмке; iOS Firebase ещё не настроен |
| 8 | Google Maps + геолокация | OSM + geolocator работают; данные/маркеры настоящие | Частично: согласование замены SDK отсутствует |
| 9 | Производительность | Lazy lists/paging/cache, const/dispose, реальные DevTools пары | Требование инструментов выполнено; slow frames остаются открытым ограничением |
| 10 | Нативные функции | image_picker, локальный аватар, Kotlin channel и ошибки | Частично: нет физического Android; Swift пока только подготовлен |
| 11 | Тестирование | Unit/widget/mocktail/native integration + LCOV >40% | Выполнено для доступного Android/Flutter стенда |
| 12 | CI/CD | Реальный green run с APK artifact и Rules | Выполнено опубликованным 70cda03; iOS native build не проверяется Android CI |
| 13 | Release + Crashlytics | Существующая подпись, obfuscate/symbols, Android Console event, store package | Частично по свежей доставке/Google; iOS release не существует |

## Найденные проблемы и исправления 25.11

1. **iOS native-канала не было:** `DeviceService` возвращал unavailable, поэтому bootstrap не включал Firebase даже при настоящем iOS plist. В существующий AppDelegate добавлен Swift MethodChannel; валидируется bundle ID/идентификаторы plist, отсутствие файла честно возвращает false.
2. **Локальные уведомления были только Android:** добавлены Darwin initialize/show/request permissions. При старте запрос разрешений не показывается; он вызывается действием пользователя.
3. **Google-конфигурация предполагала только Android web client:** добавлен отдельный iOS client ID с проверкой callback scheme на native стороне; Android-путь сохранён. Без настоящего OAuth/plist Google не объявляется подключённым.
4. **FCM мог запрашивать token раньше APNs регистрации:** добавлена проверка APNs на Apple platforms; нет APNs — push пока недоступен, UI/cloud sync не должны падать из-за этого состояния.
5. **GPS использовал AndroidSettings и Android-тексты на всех платформах:** для iOS добавлен AppleSettings с timeout, тексты разрешений стали общими. Схема SQLite и данные не меняются.
6. **В Info.plist не было privacy descriptions:** добавлены камера, photo library и foreground location; подготовлен remote-notification background mode. APNs entitlement/Apple credentials ещё не созданы и не подменяются plist-записью.
7. **iOS зависимости/иконки:** подготовлен CocoaPods fallback с iOS 15, xcconfig includes, foreground geolocator flag. Flutter template icons заменены экспортом существующего знака приложения; `render_ios_icons.py` воспроизводит размеры каталога. Финальное разрешение/линковка зависимостей требует Xcode.
8. **Сохранность конфигурации:** `GoogleService-Info.plist` исключён из Git и добавлен в secret scanner. Настоящие iOS-конфигурации и ключи не создавались.
9. **Документы расходились по датам/числу тестов:** актуальный протокол выделен здесь; старые доказательства не удалены и не переписаны как новые.

10. **Продуктовый UI/UX-аудит:** исправлены категории/цвета/рекомендации дробного AQI относительно показанного целого индекса, выбранное значение графика и порог предупреждений. Исходные API values/SQLite сохранены. В заметках убран вызов Android-only recovery на iOS, перехвачена ошибка recovery, защищено завершение save после ухода со страницы. [UI/UX](UI_UX_AUDIT.md).
11. **Подготовка Google Play:** подтверждены target/compile 36, статические 16-КБ ELF/ZIP проверки; подготовлены feature graphic, скриншоты с честным provenance, статические HTML страниц политики/удаления и [план ID](store/APPLICATION_ID_PLAN.md). Текущий ID не менялся, HTML не опубликован, письмо на удаление не отправлялось. [Статус магазина](store/PLAY_RELEASE_READINESS.md).
12. **Полный новый прогон:** 122/122, LCOV 2815/3718 = 75,71%, analyze без замечаний. Результат 117 тестов до продуктовых исправлений остаётся только в приватной истории, а не выдаётся за текущую рабочую копию.

## Реальные проверки и доказательства

Машиночитаемый итог текущего этапа: [results.json](audit_20261125/results.json). Личные подробные логи, app data и подписанные бинарники находятся только в игнорируемой `.local-backups/audit-ios-20261125/`.

- Новый `flutter pub get` выполнен без обновления версий зависимостей; upgrade не запускался.
- `flutter doctor -v`, `flutter devices`, `xcodebuild -version`, `xcrun simctl` выполнены: Android toolchain доступен; полного Xcode/CocoaPods/Simulator нет. На Mac запускается только один лёгкий Android AVD 2048 MiB / 2 CPU; перед сборкой он закрывается штатно.
- Новые iPhone widget-тесты и notification/APNs проверки используют mocks/platform override. Первые версии новых тестов потребовали исправления test harness (platform reset, регистрация Dart-плагина, поиск ещё не построенных lazy form-полей); это не объявляется найденным сбоем нативного iPhone.
- Реальные серверные read-only проверки: [Firebase](audit_20261125/firebase-readonly.json), [Open-Meteo](audit_20261125/open-meteo.json), [CI](audit_20261125/github-actions.json). На iOS существующий Bundle ID ещё не зарегистрирован в Firebase.
- Сохранены исторические [Firebase/Auth](final_audit/evidence/firebase-auth-android.json), [camera/gallery/channel](final_audit/evidence/native-android.json), [release FCM](final_audit/evidence/fcm-release-terminated.json), [Crashlytics](final_audit/evidence/crashlytics.json), [DevTools](final_audit/evidence/map-profile-summary.json). Новые события в Console/физические проверки этим запуском не имитировались.

## Актуальность замечаний предыдущей проверки

| Замечание | Состояние 25.11 |
|---|---|
| Повторный Google Sign-In | Остаётся: SHA/provider исправны; требуется интерактивный вход на совместимом Google Play стенде. Пароли в чат не нужны |
| Slow frames | Остаются: реальные 23.11 raster p95 70,137 мс, slow frames 51,85% на лёгком AVD. Старые числа не выдаются за измерения нового iOS-кода и не обещают 60 FPS |
| Физический Android | Не выполнено: пользователь располагает iPhone/Mac. Аппаратную приёмку требуется провести на доступном Android позже |
| Следующая App Distribution сборка | Последняя доступная — 1.1.0 (2); свежий APK не отправлен. Нужны отдельное разрешение на доставку и следующий versionCode при выпуске новой версии |
| Успех последнего CI | Подтверждён: 45628248353, 70cda03, success; код приложения 7cfbb9b |

## Готовность Android

Рабочая существующая Android-версия сохранена. Новые общие изменения проверяются тестами, подписанной сборкой и обновлением только тестового AVD через `adb install -r` с остановкой при ошибке, без fallback uninstall. Основной AVD не открывается. До/после сравниваются отдельные приватные снимки SQLite, настроек и фотографий; результат вынесен в свежий протокол. [Установка](audit_20261125/release-install.json), [сохранность](audit_20261125/data-preservation.json), [сквозной тест](audit_20261125/android-integration.json).

Наличие APK/AAB не закрывает Google-приёмку, физический Android или согласование OSM. Предыдущий комплект сдачи и резервные копии сохранены отдельно.

## Готовность iOS

**Подготовлена общая кодовая база и native-конфигурация; iOS не собран и не запущен.** Синтаксис Swift/plist/Podfile и Flutter layout tests проходят, но UIKit type checking, native plugin linking, разрешения, APNs, OAuth, камера, реальная SQLite и Keychain на iPhone остаются непроверенными. Настоящего `GoogleService-Info.plist`, Apple Team/APNs provisioning и Firebase iOS app пока нет. Ни одна из этих возможностей не отмечается готовой по Android-доказательствам.

Подробная инструкция: [ios_setup.md](ios_setup.md).

## Оставшиеся ручные действия

1. Установить полный Xcode, один iOS runtime и CocoaPods; потребуется место на диске. Самостоятельное удаление резервных копий/AVD ради места не выполняется.
2. Добавить iOS app в существующий Firebase, скачать настоящий plist и включить его в Runner resources; добавить настоящий Google URL scheme. Затем реальный вход и сохранение сессии.
3. Выбрать Apple Team, подключить iPhone/Developer Mode и провести физическую iOS-приёмку. Для APNs нужны Apple capabilities и ключ; платная программа без согласия не подключается.
4. На Android повторить Google-вход на совместимом стенде и физическую камеру/GPS/permission/lifecycle проверку, когда будет устройство.
5. Получить согласование преподавателя на OpenStreetMap вместо Google Maps.
6. Исходники уже обновлены в GitHub и прошли CI. Доставка новой версии в App Distribution, магазины и размещение HTML сайта остаются отдельными действиями с разрешения владельца.

## Итоговая подготовка продукта и сдачи

[Google Play: готовность и ручные шаги](store/PLAY_RELEASE_READINESS.md), [UI/UX-аудит](UI_UX_AUDIT.md), [iPhone](ios_setup.md). Финальная презентация обновлена 25.11: 122 теста и 75,71%; DevTools по-прежнему датирован 23.11. GitHub обновлён и новый CI прошёл; магазины, App Distribution и HTML сайт не публиковались. Новые APK/AAB имеют отдельные наборы symbols; оба набора по три ABI успешно загружены в существующий закрытый Crashlytics 25.11. [Протокол](audit_20261125/crashlytics-symbols.json). Приложения этим действием не распространялись.

Окончательный локальный комплект: `submission/FINAL_RK1_RK2_2026-11-25`. Предыдущий комплект 23.11 сохранён. Содержимое и checksums описаны в START_HERE.md этого комплекта; архив исходников не включает ключи, Firebase-конфигурации и пользовательские данные.
