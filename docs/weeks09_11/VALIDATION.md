# Проверки недель 9–11

29 октября 2026. Новые изменения локальные; push не выполнялся. Удалённый GitHub Actions для них не запускался. Успешный CI РК1 от 16 октября относится к прежнему коммиту.

| Проверка | Результат |
| --- | --- |
| `flutter analyze` | Без замечаний |
| `flutter test --no-pub --concurrency=1 --coverage` | 87/87 unit/widget |
| `python3 tools/check_coverage.py` | 2363/3382 строк, **69,87%**, выше 40% |
| Open-Meteo / SQLite / offline native regression | 1/1: live API, история, offline fallback, заметка, уведомление и реальная keyset SQLite-пагинация |
| Native integration недели 11 | 1/1, отдельный API 37 AVD, `--no-uninstall` |
| Отдельный native restart | 1/1, прежние Firebase UID и путь к существующему фото без входа |
| Firebase Auth / Firestore / FCM | Реальный email-вход тестового аккаунта, server-чтение своего профиля, HTTP v1 foreground push принят и получен |
| Cached network image | Настоящий disk cache: fixture HTTP server остановлен, memory entry убрана, изображение повторно декодировано, HTTP requests = 1 |
| DevTools | Performance до/после, Memory после и исходные FrameTiming/heap; снимок Memory до утрачен и требует восстановления |
| Cloud | Read-only: billing false, Maps SDK disabled; SHA-1/SHA-256 существующего release-сертификата зарегистрированы |
| Секреты | Рабочие файлы и история: 0 находок; частная конфигурация/ключи/резервные копии игнорируются Git |
| Обычный APK | Debug из lib/main.dart собран; email/password тестового аккаунта отсутствуют в ZIP-содержимом, установка -r и запуск на test AVD успешны |
| Ключ и Firebase-конфигурация | SHA-256 файлов совпадает с начальной копией: key.properties, google-services.json, upload.p12 |

[Главная обычного APK после установки](evidence/android-home-final.png) · [Фактические итоговые строки команд](evidence/test-results.txt) · [Сводка APK](evidence/apk-summary.json).

## Что означают native-результаты

[Обезличенный JSON](evidence/native-summary.json) не содержит UID, email, токены или пути к фотографиям. Оригинальные результаты/логи остаются в исключённой из Git `.local-backups/weeks09-11-20261029/`. Integration APK с тестовыми define-параметрами не предназначен для передачи преподавателю.

В первом native-прогоне обнаружено недостаточное ожидание busy/lifecycle перед открытием галереи; исправлен тест, повторный прогон прошёл. Вспомогательный host-скрипт однажды принял сообщение `cat: No such file` за FCM-токен: сервер ответил NotRegistered. Проверка формата исправлена; настоящий текущий токен получен, push принят и доставлен. Это не выдаётся за ошибку авторизации Firebase.

Первый API-регрессионный тест ожидал onboarding на уже авторизованном устройстве. Он доработан для сохранённой SDK-сессии; принудительный logout не выполнялся. Старые неуспешные логи сохранены рядом с повторными.

## Сохранность

До изменений сохранены исходники, статус Git, дополнительный APFS-клон AVD и tar приватных app data. Основной AVD не использовался для установок и тестовых данных. Эксперименты выполнялись только на новом `AQM_Weeks_09_11` (serial emulator-5560). Не выполнялись uninstall, wipe data, flutter clean, очистка пользовательской SQLite, пересоздание Firebase/ключа и подключение billing.

Дополнительно основной AVD штатно запущен только для чтения и закрыт без установки приложения. Сравнение tar app data до/после: `integrity_check` обеих SQLite — ok, все строки совпали (4 alerts, 2 cache, 2 places, 8 samples, 1 note); SharedPreferences и единственная локальная фотография совпали. Сохранённый зашифрованный Firebase user record также не изменился. Личные значения и фотографии не публикуются. [Обезличенное сравнение](evidence/main-data-preservation.json).

## Границы подтверждения

- Реальные tiles Google Maps не проверены до настройки Cloud; неделя 9 частичная.
- Физический Android не подключён; неделя 11 частичная.
- Новый Google OAuth интерактивный вход, FCM background/terminated, Crashlytics и Security Rules не повторялись в этом прогоне; прежние результаты датированы в материалах РК1. Настройки OAuth/Rules/FCM не менялись.
- Для закрытия недели 10 требуется подтверждённый снимок Memory до; медленные кадры и рост heap отражены честно. Эти измерения не доказывают стабильные 60 FPS или отсутствие утечек на телефоне.
