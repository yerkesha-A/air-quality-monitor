# Air Quality Monitor: РК2, недели 8–15

Проверено 23.11.2026. Основной исходный код финальной Android-версии — `9427a22`. Отчёт различает реализацию, реальные проверки и внешние ограничения. РК1 относится к неделям 1–7; [общий аудит охватывает все 15 недель](final_audit/AUDIT_01_15.md).

| Неделя | Что сделано и проверено | Доказательства / ограничения |
|---|---|---|
| 8 | Настоящие Email-регистрация/вход, Firestore server-read/restore и запрет чужого UID; Rules 6/6. Настоящий FCM foreground/background/terminated проверен и в обычном debug, и в подписанном release | [Firebase](final_audit/evidence/firebase-auth-android.json), [release FCM фон](final_audit/evidence/fcm-release-background.json), [запуск](final_audit/evidence/fcm-release-terminated.json), [foreground](final_audit/evidence/fcm-release-foreground.json). SHA и Google provider проверены; свежий Google-вход финальной версии не подтверждён |
| 9 | OSM + настоящие Open-Meteo данные, GPS/разрешение, компактная раскрываемая карточка, группы без пересечений, легенда, light/dark/landscape | [Интерфейс release](final_audit/evidence/release-map-ui.json), [GPS эмулятора](final_audit/evidence/release-location.json), [неделя 9](WEEK_09.md). **OSM не является Google Maps**, нужно согласование преподавателя |
| 10 | Lazy lists, настоящая keyset пагинация SQLite, cached_network_image с дисковым кешем, dispose; реальные DevTools Performance/Memory и FrameTiming до/после | [Новые измерения](WEEK_10.md). Карта выше на 58,71%; raster p95 вырос, доля медленных кадров снизилась. Общее ускорение и стабильные 60 FPS не заявляются |
| 11 | Камера, галерея, Kotlin MethodChannel; HTTP disk cache после остановки сервера; фото/сессия после отдельного перезапуска. Исправлено закрытие UI SQLite фоновым FCM | [Native](final_audit/evidence/native-android.json), [SQLite regression](final_audit/evidence/push-database-android.json). **Физический Android не проверен** |
| 12 | Рабочий GitHub Actions с analyze, форматированием, тестами, coverage, APK/artifacts и Rules job | [Проверенный run приложения](https://github.com/yerkesha-A/air-quality-monitor/actions/runs/45228891410), `79bca13`, success. **Новый код опубликован с разрешения; CI прошёл** |
| 13 | 108/108 тестов, analyze без замечаний, LCOV 2762/3693 = **74,79% >40%**. Rules 6/6, функции 3/3, отдельные Dart target и JSON generation выполнены; нативные сценарии пройдены | [Результаты](final_audit/evidence/RESULTS.json), [неделя 13](WEEK_13.md). Native-тесты используют отдельный AVD и предохранитель от запуска на основном |
| 14 | Подписанные APK/AAB **1.1.0 (3)** существующим ключом, obfuscate/split-debug-info, подписи обоих сверены, установленный APK совпал с обычным артефактом. Новый non-fatal подтверждён SDK, HTTP 200 и владельцем в Console; символы загружены в закрытый Crashlytics | [Release](final_audit/evidence/release-verification.json), [Crashlytics](final_audit/evidence/crashlytics.json), [данные](final_audit/evidence/release-data-preservation.json). App Distribution содержит предыдущий build 2; физическая установка не подтверждена; build 3 не публиковался |
| 15 | PPTX/PDF на 13 слайдов, сценарий на 8 мин 40 с, 13 вопросов, свежие реальные release-скриншоты, матрицы 15 недель и 13 требований, инструкция преподавателю | [Презентация](rk2/RK2_PRESENTATION.pdf), [PowerPoint](rk2/RK2_PRESENTATION.pptx), [сценарий](rk2/DEFENSE.md), [вопросы](rk2/QUESTIONS.md), [что отправить](final_audit/HAND_IN.md) |

## Исправления, подтверждённые проверкой

Карта получила больше места, читаемые не перекрывающиеся группы и легенду. После разрешения GPS в настройках старая ошибка снимается. Firebase notification+data дополнительно сохраняется при нажатии до навигации. Главная причина `database_closed` устранена: background isolate использует отдельное SQLite-соединение, закрытие которого не закрывает UI handle. Это проверено нативным регрессионным тестом и тремя FCM-сценариями подписанной версии.

## Данные и безопасная демонстрация

Работает только облегчённый API 30 / 2048 MiB / 2 CPU; основной пользовательский AVD закрыт. Дополнительные AVD и app-data копии сохранены приватно. До/после обновления: SQLite integrity ok, старые ключи истории/избранное сохранены, настройки/выбранный город и фото совпали, живой экран восстановил тот же аккаунт. После проверок появились три настоящие тестовые push-записи; они не удаляются. На этом test AVD заметок изначально не было — сохранность непустой коллекции этим сравнением не заявляется.

Wipe, uninstall, flutter clean, очистка SQLite, удаление резервных копий, смена Firebase/keystore/паролей и billing не выполнялись. По разрешению владельца удалялась только пересоздаваемая `build/app/intermediates`, когда нехватка диска блокировала AVD. Готовые артефакты и символы предварительно проверены. [Демонстрация на MacBook](rk2/MAC_DEMO.md).

## Что остаётся внешним

- Согласовать замену Google Maps на OSM у преподавателя.
- Проверить настоящие датчики/камеру и установку App Distribution на физическом Android.
- Повторить свежий Google-вход финального release на актуальных Play Services: у лёгкого API 30 они устарели; прежний успешный вход владельца не переименовывается в новую проверку.
- CI новой версии прошёл; отдельно согласовать новую тестовую доставку build 3, если она нужна.
- Дополнительная ручная проверка: получение reset-email и смена пароля в браузере не подтверждены; UI/ошибки покрыты тестами. Это не подменяет уже проверенные регистрацию и вход.

[13 обязательных категорий](REQUIREMENTS_AUDIT.md). Не объявлять весь проект «100%» при этих ограничениях. История прежних проверок сохранена в `docs/archive` и исходных доказательствах с датами.
