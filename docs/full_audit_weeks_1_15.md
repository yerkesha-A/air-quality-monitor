# Проверка Air Quality Monitor: недели 1–15

Актуализация: **26 ноября 2026**. Основание — сохранённые требования преподавателя, переданные владельцем, задания и исходники проекта. РК1 охватывает недели 1–7, РК2 — недели 8–15. Новым материалам не приписывается выполнение в прошлые недели.

Текущая рабочая копия основана на опубликованном `552bb11` и ещё не отправлена на GitHub. [Локальные проверки 26.11](audit_20261126/results.json): **131/131**, analyze без замечаний, покрытие **2920/3896 = 74,95%**. Android в текущем этапе не собирался и не переустанавливался; прежние артефакты и данные сохранены. [iOS: подпись и установка](audit_20261126/ios-signing.json).

## Все 15 недель

| Неделя | Требование и реализация | Проверки и материалы | Статус / оставшийся пункт |
|---|---|---|---|
| 1 | Flutter/Dart, null safety, классы, коллекции, async/await. Отдельные `coursework/week01/exercises.dart`, `docs/dart_basics.dart`; GitHub и README с целью, аудиторией и аналогами | [Dart-задания](../coursework/week01/README.md), `coursework_test.dart`, запуски Dart targets 25.11, публичный репозиторий | Выполнено по известному списку. Учебные материалы добавлены 16.10, не выдаются за раннюю сдачу |
| 2 | Несколько экранов, Material 3, light/dark/system, адаптивность | `app_theme.dart`, screen/widget/iOS layout tests, [эскизы](rk1/wireframes.svg), настоящие Android screenshots | Выполнено; утверждённый дизайн сохранён |
| 3 | setState, собственный InheritedWidget и Provider; сравнение | [Три работающих примера](state_examples.dart), `coursework_test.dart`, сравнение в README; производственные Provider settings/auth/places | Выполнено |
| 4 | BLoC, presentation/domain/data, Repository, DI | Air/CitySearch/History BLoC, domain-контракты, data-реализации, AppDependencies; BLoC/repository tests | Выполнено; архитектура сохранена |
| 5 | Open-Meteo REST, JSON, timeout 18 с, loading/error/empty, debounce 400 мс, pull-to-refresh | generated DTO `air_dto.g.dart`, API/BLoC tests; [Android live API 25.11](audit_20261125/android-integration.json), [iOS 25.11](audit_20261125/ios-integration.json) | Выполнено. AQI — модель Open-Meteo/CAMS |
| 6 | SharedPreferences, SQLite, история/избранное/кеш, миграции, offline-first | LocalStore schema v3, keyset paging, repository/freshness/pagination tests; настоящая SQLite и сохранность данных | Выполнено; fallback сохраняет исходное время и причину ошибки |
| 7 | GoRouter: параметры, вложенная навигация, guard и адаптивность | StatefulShellRoute, `/city/:id`, query login mode, guard `/account`, error route; навигационные и layout-тесты | Выполнено |
| 8 | Firebase Email/Password + Google, Firestore, Rules, настоящий FCM | [Auth/Firestore 23.11](final_audit/evidence/firebase-auth-android.json), [FCM release](final_audit/evidence/fcm-release-terminated.json), Rules 8/8 от 25.11; SHA/provider подтверждены | Новый Google-вход и release-сессия iPhone подтверждены 26.11. Свежая Android Google-приёмка остаётся отдельным пунктом |
| 9 | Карта, маркеры, карточки, геолокация и разрешения | Реальные OSM tiles/Open-Meteo, grouping/legend/compact details, GPS/errors/debounce/cache; [неделя 9](WEEK_09.md), map/location tests | Частично: бесплатная OSM работает, замену требуемого Google Maps должен согласовать преподаватель |
| 10 | Lazy lists, пагинация, cached_network_image, const/dispose; DevTools Performance/Memory до/после | Настоящая SQLite keyset pagination, HTTP disk cache, dispose; [измерения](PERFORMANCE.md), [FrameTiming/heap](final_audit/evidence/map-profile-summary.json) | Инструменты и реализации выполнены. Slow frames остаются; 60 FPS и отсутствие утечек не доказаны |
| 11 | Камера/галерея, native channel, физическое Android-устройство | [Android native 23.11](final_audit/evidence/native-android.json), camera/avatar/channel tests; Swift-канал и native iOS Simulator проверены отдельно | Частично: обязательная проверка физического Android остаётся открытой. iPhone учитывается отдельным стендом |
| 12 | GitHub Actions: зависимости, format/analyze/tests/coverage, APK и artifacts, Rules | [CI 552bb11: success](https://github.com/yerkesha-A/air-quality-monitor/actions/runs/45630653658). В текущий workflow добавлена проверка ссылок | Выполнено для опубликованной версии; новый remote run ожидает разрешённого push |
| 13 | Unit, mocktail, widget, integration; coverage >40% | [131/131, 74,95%](audit_20261126/results.json), analyze 0; Rules 8/8, Python 3/3 (25.11), реальные native-протоколы | Выполнено для доступных стендов; физические и интерактивные сценарии перечислены отдельно |
| 14 | Подписанные APK/AAB, версии/icon/splash, obfuscation/symbols, Crashlytics, материалы магазинов и App Distribution | [Android release 25.11](audit_20261125/release-verification.json), [symbols](audit_20261125/crashlytics-symbols.json), [iOS signed build/install 26.11](audit_20261126/ios-signing.json) | Частично: новая доставка App Distribution не разрешена, там прежний build 2; iOS Apple/APNs/App Store-публикация не готовы |
| 15 | Отчёт РК2, презентация 7–10 минут, демонстрация, вопросы, доказательства | [РК2](RK2_REPORT.md), [PDF](rk2/RK2_PRESENTATION.pdf), [PPTX](rk2/RK2_PRESENTATION.pptx), [сценарий](rk2/DEFENSE.md), [сдача](final_audit/HAND_IN.md) | Материалы обновлены 26.11; локальный комплект FINAL_RK1_RK2_2026-11-26 подготовлен, новый push/CI требуют разрешения |

РК1 по известному списку недель 1–7 реализован и подтверждён кодом/тестами/материалами. Полную приёмку всего проекта на 100% не заявляем: остаются явные ограничения недель 8, 9, 11 и 14, текущий локальный комплект подготовлен отдельно от опубликованного GitHub.

## Отдельно: 13 обязательных категорий

| № | Категория | Реализация и подтверждение | Открытый пункт |
|---|---|---|---|
| 1 | Архитектура Dart | Три слоя, Repository, DI, реальные Dart-задания и coursework tests | Нет по известному списку |
| 2 | Material 3 | Обе темы, несколько экранов, эскизы, responsive/widget matrix | Аппаратная iOS-приёмка отмечается отдельно |
| 3 | Provider + BLoC/Riverpod | Provider для общего состояния; три BLoC для загрузок/поиска/истории; три учебных state-примера | Riverpod не используется; выбрана допустимая пара Provider + BLoC |
| 4 | REST/JSON | Настоящий Open-Meteo, generated JSON DTO, timeout/errors/debounce/refresh | Нет по известному списку |
| 5 | SharedPreferences + SQLite | Настройки, кеш, история, избранное, заметки, offline-first и paging | Нет по известному списку |
| 6 | GoRouter | Shell branches, path/query параметры, guard, error route; тесты | Нет по известному списку |
| 7 | Firebase | Android Auth/Firestore/Rules/FCM реальны; iOS инициализация и matching OAuth готовы | Google iPhone и release-сессия подтверждены владельцем; свежий Android Google/Apple/APNs iOS учитываются отдельно |
| 8 | Google Maps + геолокация | Рабочая OSM, настоящие модельные AQI, GPS/permissions | Согласование замены SDK у преподавателя |
| 9 | Производительность | Lazy lists, keyset, disk image cache, ограниченные запросы; настоящие DevTools/FrameTiming/Memory | Slow frames требуют дальнейшего измерения; нет обещания 60 FPS |
| 10 | Нативные функции | Android Kotlin/channel/camera/gallery и iOS Swift channel | Физический Android отсутствует; GPS/камера/галерея iPhone подтверждены владельцем; отказы разрешений остаются отдельно |
| 11 | Тестирование | 131 unit/widget, mocks, native integration, LCOV >40% | Непроверенные native-сценарии не закрываются mock-тестами |
| 12 | CI/CD | Опубликованный зелёный pipeline с APK/artifact и Rules | Текущая рабочая копия ещё не отправлена |
| 13 | Release + Crashlytics | Старый Android APK/AAB/symbols сохранены; iPhone Release AOT установлен, самостоятельный запуск и Google-сессия подтверждены | App Distribution новой версии, iOS live Crashlytics/Apple/APNs и магазины остаются отдельными этапами |

## Продуктовые изменения 25–26 ноября

- Добавлены подтверждение удаления аккаунта, повторная авторизация и идемпотентное удаление четырёх подколлекций Firestore перед удалением Auth. Старые сеансы блокируются Rules через минимальную служебную отметку; порядок и сбои покрыты тестами. [Настоящий native SDK-тест на локальном demo Firebase](audit_20261126/account-deletion-native/results.json) прошёл: reauth, 405 favorites, все четыре подколлекции, Auth и изоляция аватаров. Обновлённые Rules развёрнуты после резервного копирования. Рабочие аккаунты не удалялись. [Процедура и сохранение общих локальных данных](ACCOUNT_DELETION.md).
- Реализован native Apple AuthProvider и отзыв grant при удалении связанного Apple identity. Кнопка скрыта до настоящей настройки; текущий profile не содержит Apple/APNs capabilities.
- iOS действительно собран и прошёл первый native Simulator-тест. Для iPhone исправлена регистрация: новый разрешённый ID `kz.erkezhan.airqualitymonitor`, настоящий Firebase plist/callback, Personal Team profile, deep-strict codesign и установка. Google-вход на физическом iPhone подтверждён владельцем. Release AOT установлен поверх debug с тем же ID/Team; холодный запуск с главного экрана без Mac и сохранение профиля подтверждены. Камера/GPS и выбор из галереи проверены владельцем без ошибок; фото сохраняется после перезапуска. [Release-протокол](audit_20261126/ios-release.json).
- Завершён переход уже используемых iOS-плагинов на Swift Package Manager; пустая CocoaPods-интеграция, ломавшая сборку после pub get, удалена с резервным копированием. Неиспользуемые Firebase Storage/Cupertino Icons убраны; локальные фотографии в облако не загружались.
- Из светлой карты убран тождественный цветовой фильтр; стабильный ключ сохраняет TileLayer при смене темы. Regression-тесты карты прошли. Измеренное ускорение этим фактом не объявляется.
- Исправлены реальные mailto-ссылки и добавлена статическая страница поддержки. Политики обновлены под фактическую процедуру удаления; сайт пока не развёрнут.

## Документация и сохранность

14 исторических/дублирующихся Markdown-документов объединены. Полные исходные тексты сохранены в приватном архиве **Documents/AirQualityArchive/product-next-20261125/historical-documents-552bb11.zip** и Git checkpoint `552bb11`; ссылки на исторические тексты ведут к неизменяемой версии. Текущие требования сведены в этот документ, краткий статус — в PROJECT_PROGRESS. Recovery остаётся одним [историческим протоколом](ANDROID_RECOVERY_VERIFICATION.md); измерения — в PERFORMANCE. Скриншоты, JSON-доказательства, тесты и задания не удалялись.

Удалённые дубликаты: root WEEK_09/10/11; docs RECOVERY_2026_10_16, STAGE1_PREPARATION, STAGE2_FIREBASE_ANDROID, DESIGN_REVIEW, SOFT_DESIGN_REVIEW, PROJECT_HISTORY, REQUIREMENTS_AUDIT, TECHNICAL_NOTES; два старых текста docs/archive и прежняя матрица final_audit/AUDIT_01_15. Прежние комплекты submission сохранены со своими версиями.

Android package `com.example.air_quality_monitor`, keystore и его пароли не менялись. Основной Android AVD закрыт. Старое iOS QA-приложение и его данные сохранены: новый Bundle ID использует отдельный sandbox, автоматическая миграция не выполнялась. Wipe/uninstall/очистка SQLite и удаление резервных копий не применялись. Billing, платные подписки, новый Git push, App Distribution delivery и магазины не запускались.

## Осталось с участием владельца или преподавателя

1. Проверить аппаратные отказы разрешений и live iOS Crashlytics. Галерея, сохранение фото и локальное уведомление с записью в историю подтверждены владельцем. Trust, Google-вход и release-перезапуск без Mac уже подтверждены; бесплатную подпись потребуется обновить после 03.12.2026.
2. Согласовать у преподавателя бесплатную OSM вместо Google Maps; физический Android проверить при доступности устройства.
3. Apple Sign-In/APNs включать только при доступных реальных capabilities и настройке владельца. Платные программы самостоятельно не подключаются.
4. После готового локального комплекта отдельно разрешить push для нового CI и, при необходимости, новую тестовую доставку App Distribution. Публичные HTTPS страницы/магазины тоже не публикуются автоматически.
