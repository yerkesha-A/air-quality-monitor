# Air Quality Monitor: РК2, недели 8–15

Обновлено **26.11.2026**. РК1 относится к неделям 1–7. Этот отчёт различает реализацию, реальные проверки и открытые требования. Полная матрица всех [15 недель и 13 категорий](full_audit_weeks_1_15.md) содержит ссылки на исходники и доказательства.

Текущая локальная версия — **1.1.1 (4)** на основе опубликованного `552bb11`. **136/136** unit/widget-тестов, `flutter analyze` без замечаний, **3025/3996 = 75,70%** покрытия строк. [Результаты](notification_history_20261126/results.json). Новый код ещё не отправлен на GitHub; последний опубликованный [CI 552bb11](https://github.com/yerkesha-A/air-quality-monitor/actions/runs/45630653658) успешен.

| Неделя | Реализация и реальные проверки | Доказательства и ограничения |
|---|---|---|
| 8 | Android Email/Password, Firestore server read/restore, Security Rules и настоящий FCM в трёх состояниях. Google-вход на физическом iPhone и сохранение сессии release после перезапуска без Mac | [Android Firebase](final_audit/evidence/firebase-auth-android.json), [release FCM](final_audit/evidence/fcm-release-terminated.json), Rules 8/8 от 25.11; [iPhone release](audit_20261126/ios-release.json). Свежая Google-приёмка Android учитывается отдельно |
| 9 | OSM/Open-Meteo, геолокация, компактная карточка, группы маркеров, легенда, темы и адаптивность. GPS iPhone проверен владельцем | [Неделя 9](WEEK_09.md), [release UI](final_audit/evidence/release-map-ui.json). OSM работает, но не равна Google Maps; замену должен согласовать преподаватель |
| 10 | Lazy lists, SQLite keyset pagination, cached_network_image с дисковым кешем, dispose. Настоящие DevTools Performance/Memory и FrameTiming до/после | [Измерения](PERFORMANCE.md). Общее ускорение, стабильные 60 FPS и отсутствие утечек не объявляются доказанными |
| 11 | Android камера/галерея/Kotlin channel и native cache tests; iOS Swift channel/SQLite/API в Simulator. Камера iPhone в заметке, галерея профиля и фото после перезапуска проверены владельцем | [Android native](final_audit/evidence/native-android.json), [iOS native](audit_20261125/ios-integration.json), [ручная проверка iPhone](audit_20261126/ios-physical-owner-check.json). Физического Android нет |
| 12 | GitHub Actions: dependencies, format/analyze/tests/coverage, APK/artifacts, отдельные Rules. Добавлена проверка ссылок документации | CI опубликованного `552bb11` зелёный; для текущей рабочей копии новый run ещё не выполнялся |
| 13 | 136 unit/widget, mocktail, native integration, coverage 75,70%. Rules 8/8 и Python 3/3. Удаление аккаунта покрыто порядком операций, сбоями и повторным запуском | [Результаты](notification_history_20261126/results.json), [неделя 13](WEEK_13.md). [Нативное сквозное удаление прошло](audit_20261126/account-deletion-native/results.json) на локальном demo-проекте: reauth, 405 favorites, четыре подколлекции и Auth; рабочий аккаунт не затрагивался |
| 14 | Существующие подписанные Android APK/AAB 1.1.0 (3), obfuscation/symbols, подтверждённый Crashlytics. Подписанный iPhone Release AOT 1.1.1 (4), обновление без uninstall, самостоятельный запуск без Mac | [Android release](audit_20261125/release-verification.json), [iPhone release](audit_20261126/ios-release.json). App Distribution содержит прежний build 2. iOS APNs/Apple Sign-In/App Store не готовы; бесплатная подпись до 03.12.2026 |
| 15 | Отчёт, матрица, PDF/PPTX, сценарий на 8–10 минут, 13 вопросов, реальные скриншоты и инструкция сдачи | [PDF](rk2/RK2_PRESENTATION.pdf), [PPTX](rk2/RK2_PRESENTATION.pptx), [сценарий](rk2/DEFENSE.md), [вопросы](rk2/QUESTIONS.md), [сдача](final_audit/HAND_IN.md) |

## Исправления текущего этапа

- Реальное удаление аккаунта в приложении: подтверждение и повторная авторизация до удаления четырёх подколлекций Firestore и Auth. Rules блокируют записи старых сеансов; облачные ошибки не выдаются за успех. Общие локальные история/избранное/заметки сохраняются. [Процедура](ACCOUNT_DELETION.md).
- Исправлена iOS-подпись: разрешённый владельцем уникальный Bundle ID, настоящий plist из того же Firebase-проекта и matching Google callback. Рабочая Google-сессия сохранилась при обновлении debug → release. Ограничение Flutter debug/JIT при запуске с главного экрана устранено установкой AOT release.
- iOS-плагины собираются через Swift Package Manager; устранён ошибочный пустой CocoaPods fallback. Неиспользуемые зависимости удалены. Тест карты проверяет сохранение TileLayer при смене темы.
- Обновлены политика/процедура удаления и статические страницы поддержки, исправлен mailto. Эти страницы пока не опубликованы.
- Документация объединена без утраты исторических текстов: оригиналы находятся в Git checkpoint и приватном архиве владельца. Старые комплекты сдачи сохранены.

## Сохранность и демонстрация

Android в этом этапе не собирался и не переустанавливался по просьбе владельца. Прежние APK/AAB, пользовательский AVD, Firebase-проект и release-keystore сохранены; контрольные суммы защищённых Android-файлов не изменились. Новые исходники iOS/общего кода не выдаются за прежний Android APK build 3.

Перед release-обновлением iPhone сохранён контейнер приложения, SQLite integrity `ok`. Bundle ID и Team при обновлении не менялись, uninstall не применялся. Владелец подтвердил запуск без Mac, сохранение имени/email, работу GPS/камеры и сохранение фотографии из галереи. Личные данные и токены в публичные доказательства не включены.

Бесплатный iPhone provisioning истекает **03.12.2026, 15:54 UTC**: после этого требуется повторная подпись через Mac. Это самостоятельная development release-установка, а не публикация в App Store. Billing/платные программы, новый push и доставка новой версии не запускались.

## Что ещё требует участия

1. Согласовать OSM вместо дословного требования Google Maps.
2. Проверить физический Android при доступности устройства; iPhone не подменяет этот пункт.
3. Завершить отдельные ручные permission-denial/reset-email; локальное уведомление и запись в историю iPhone подтверждены владельцем; непройденные сценарии отмечены в протоколах.
4. При необходимости настроить настоящие Apple Sign-In/APNs capabilities и Firebase provider/key. Платные программы без разрешения не подключаются.
5. Разрешить новый push для CI текущего кода и отдельно новую App Distribution delivery/публикацию HTTPS страниц, если это нужно. Магазины не публикуются автоматически.

Весь проект на 100% при этих открытых пунктах не объявляется.

Дополнение интерфейса 26.11: [история уведомлений](notification_history_20261126/README.md) обновлена и принята владельцем на iPhone в обеих темах. Данные/SQLite и настройки сохранены; Android оформлен теми же Flutter-виджетами и проверен платформенными layout-тестами без переустановки AVD. Комплект FINAL_RK1_RK2_2026-11-26 сохраняет снимок предыдущего ec63298.
