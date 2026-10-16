# Android: восстановление и проверка после перезагрузки

16 октября 2026. Продолжение [первой диагностики](RECOVERY_2026_10_16.md).

## Резервные копии до установки

Дополнительная копия всех 30 файлов текущего AVD создана через APFS clone в
`.local-backups/avd-recovery-20261016/Medium_Phone-214808.avd/`.
Перед копированием выполнен guest `sync`, виртуальная машина приостановлена
через `avd stop`, после копирования продолжена через `avd start`.
Для userdata, encryption key, SD card и config сохранены SHA-256.
`qemu-img info` читает копии userdata/encryption overlay: `corrupt=false`,
`dirty-flag=false`, backing-файлы разрешаются внутри резервной копии.

Для репетиции создана отдельная рабочая APFS-копия `AQM_Recovery` на порту 5556.
Резервная копия при этом не запускалась и не изменялась. После проверки отдельно
сохранены полные app data до первого запуска; затем такая же копия снята с
восстановленного основного AVD. Все персональные данные и токены остаются
только в игнорируемой `.local-backups/avd-recovery-20261016/`.

## Восстановление основного приложения

Подпись debug APK проверена `apksigner`; hash сертификата совпал с сохранённой
записью Package Manager. Сначала `adb install -r -t` выполнен на рабочей копии,
затем на основном `emulator-5554`. Оба запуска завершились `Success`.
На репетиции сохранились appId 10243 и ceDataInode 549485.
До первого запуска 25 файлов баз, preferences и app documents основного AVD
побайтно совпали с результатом репетиции. Утерянных/изменённых файлов нет.

До восстановления существовала запись пакета с `pkg=null`, но отсутствовал
каталог установленного APK. После замены APK работает `run-as`, приложение
запускается. Причина исчезновения старого APK при сбое не установлена.

| Данные | Результат |
| --- | --- |
| SQLite | `PRAGMA integrity_check`: `ok` до и после запуска/FCM |
| История AQI | Все исходные 5 ключей сохранены; после обычного обновления 6 точек |
| Заметки | Исходная 1 заметка полностью совпала до/после проверок |
| Избранное | 0 до восстановления; совпадает с прежним profile snapshot |
| Настройки | theme/threshold/milligrams/backgroundAlerts/alerts/onboarded совпали с прежним snapshot |
| Выбранный город | Проверен native-тестом по прежнему snapshot; обычное приложение открыло Алматы |
| Firebase/Google-сессия | Native SDK восстановил тот же UID и Google provider без повторного входа |
| Личная локальная фотография | Отсутствовала и в прежнем snapshot; потерю фото это не означает |
| Контрольный файл фото | Прежнее изображение в profile-storage-verification прочитано и проверено native-тестом |
| История уведомлений | Все 3 исходные записи сохранены; добавлена 1 явно тестовая FCM-запись |

Проверка сессии:

```sh
flutter test integration_test/profile_session_test.dart -d emulator-5554 --no-uninstall --dart-define=VERIFY_PROFILE_RESTART=true
```

Результат: 1/1. Logout, смена аккаунта, сброс preferences/SQLite не выполнялись.
После native-тестов обычный debug APK пересобран и установлен через `install -r -t`.
Основной AVD штатно закрыт после `sync` для освобождения памяти release-проверке.

## Firebase, Crashlytics и FCM

- CLI read-only подтвердил зарегистрированные SHA-1 и SHA-256 существующего
  upload-ключа. Новые fingerprints и ключи не создавались.
- Актуальная Android SDK-конфигурация того же Firebase-проекта содержит release
  Android OAuth client, которого не было в локальном файле. `google-services.json`
  обновлён; предыдущий сохранён приватно. Project/app ID, API key и web OAuth
  client побайтно/структурно сохранены. Файл по-прежнему игнорируется Git.
- `crashlytics_test.dart --no-uninstall --dart-define=VERIFY_CRASHLYTICS=true`:
  1/1, контролируемый non-fatal. Read-only API Crashlytics подтвердил **1 новое
  NON_FATAL событие за период текущей проверки** после перезапуска приложения.
  Искусственный fatal crash не выполнялся.
- Настоящий FCM HTTP v1 push отправлен на существующий токен основного AVD.
  Перед отправкой подтверждено отсутствие процесса после Home + `am kill`;
  `force-stop` для этого сценария не использовался. Системный NotificationRecord
  с tag `aqm-recovery-terminated` найден; обработчик создал запись SQLite.
  Нажатие именно этого уведомления открыло «Уведомления» с тестовой записью.
  Это проверка доставки FCM, не серверного мониторинга AQI.

Cloud billing, APIs, пользовательские документы Firestore и ключи проекта
вручную не перенастраивались. Обычное приложение выполняло свою штатную
синхронизацию профиля; release-сборка выполняла штатные Crashlytics mapping tasks.

## Сборки и проверки

- `flutter analyze --no-pub`: без замечаний.
- `flutter test --no-pub --concurrency=1`: 71/71.
- Обычный debug APK собран и установлен с сохранением данных.
- Исправленный обычный release APK: 62 511 677 байт; `apksigner` проверил подпись, DER
  сертификата совпал с существующим upload-keystore.
- Исправленный release AAB: 62 899 386 байт, `build/app/outputs/bundle/release/app-release.aab`.
  `jarsigner -verify` успешен; сертификат подписанта соответствует существующему
  upload-ключу. Keystore и обе конфигурации с паролями не изменились по SHA-256.
- Сборочные Gradle-daemon после проверок остановлены.

Native release-запуск выявил дополнительную ошибку: bootstrap переходил в
общий экран ошибки. Сравнение `aapt2 dump resources` подтвердило, что
`drawable/ic_notification` присутствовал в debug APK и отсутствовал в release.
NotificationService передаёт его имя в flutter_local_notifications при старте;
плагин проверяет ресурс через `getIdentifier` и отклоняет отсутствующую иконку.
Добавлен точечный `android/app/src/main/res/raw/keep.xml` с
`tools:keep="@drawable/ic_notification,@string/google_app_id,@string/default_web_client_id"`. Оптимизация ресурсов не отключалась.
APK/AAB повторно собраны с этим исправлением: Gradle assembleRelease +
bundleRelease offline, `BUILD SUCCESSFUL in 2m 46s`, включая Android Lint.
Новый APK содержит `ic_notification` (проверено `aapt2`), прошёл `apksigner`,
установлен поверх предыдущего release через `install -r` без очистки данных.
В `dumpsys package` отсутствует DEBUGGABLE. Первый экран onboarding открылся
без bootstrap-ошибки. AAB повторно прошёл `jarsigner`, сертификат совпадает с
существующим upload-ключом. Повторная проверка Google Sign-In выявила удалённый resource shrinking параметр
`default_web_client_id`: MainActivity получает его динамически через `getIdentifier`,
поэтому экран ошибочно сообщал, что Google Sign-In не подключён.
В keep.xml также сохранены обе динамически читаемые строки Firebase/OAuth.
Повторная assembleRelease + bundleRelease: `BUILD SUCCESSFUL in 1m 31s`.
Все три ресурса присутствуют в итоговом APK; web client ID совпадает с конфигурацией.
Подписи итоговых APK/AAB проверены повторно, соответствуют прежнему ключу.
APK обновлён через `install -r --no-streaming`; обычный главный экран открылся.
Владелец подтвердил успешный Google-вход. Установленный APK побайтно совпал
с итоговым подписанным артефактом. Native FirebaseAuth UID совпал с прежним
profile snapshot основного AVD. После `am force-stop` подтверждено отсутствие
процесса; при новом запуске создан новый PID и без повторного входа открыт
профиль с теми же именем/email. Сохранение release-сессии подтверждено.

Для native release-приёмки создан отдельный пустой `AQM_Release_Check`:
подпись upload отличается от debug, поэтому release поверх пользовательского
приложения не устанавливается. Первый запуск API 37 сопровождался системными
ANR Google Play services и задержками Package Manager. После штатного перезапуска
с 4 CPU, SwiftShader и выключенным гостевым Vulkan установка release APK
завершилась `Success`. Google Sign-In в итоговом release проверен успешно.
Резервная загрузка API 36 остановлена, когда API 37 начал устанавливать APK и
выявилась отдельная ошибка ресурса самого приложения. Существующие образы не
удалялись. Владелец самостоятельно добавил Google-аккаунт в тестовый Android;
Google Sign-In в исправленном release-приложении подтверждён владельцем
и проверкой профиля после холодного запуска.

## Ограничения

Wipe data, uninstall, flutter clean, очистка SQLite, замена release-ключа,
изменение паролей подписи, подключение billing и публикация не выполнялись.
Все исходные изменения проекта сохранены.

До завершения Android-приёмки остаются смена пароля по полученной ссылке и вход с новым паролем,
камера/GPS на физическом устройстве и синхронизация двух физических устройств.
Google Maps ждёт отдельного решения о billing; серверный AQI-планировщик
не развёрнут. Остальные продуктовые пункты перечислены в README.
