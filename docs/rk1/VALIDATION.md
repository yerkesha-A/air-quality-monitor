# Финальные проверки РК1

16 октября 2026. Команды выполнены локально на Mac, Android API 37 arm64. Репозиторий опубликован; [GitHub Actions](https://github.com/yerkesha-A/air-quality-monitor/actions) запущен. Локальные результаты ниже не выдаются за результат удалённого CI.

| Проверка | Фактический результат |
| --- | --- |
| `flutter analyze --no-pub` | No issues found, 6,8 с |
| `dart format --output=none --set-exit-if-changed lib test integration_test docs coursework` | 82 файла, 0 изменений |
| `dart run coursework/week01/exercises.dart` | Завершился: grade A, частоты dart=2/flutter=1, Future Flutter, Stream [1,3,6] |
| `dart run docs/dart_basics.dart` | Завершился: null safety, коллекции и Future |
| `flutter test --coverage --no-pub --concurrency=1` | **73 passed, 0 failed**, 1 мин 48 с |
| `python3 tools/check_coverage.py` | **2218/3186 = 69,62%**, порог >40% пройден |
| `python3 -m unittest discover -s functions -p 'test_*.py'` | 3/3; только чистая логика, не развёрнутый сервер |
| Firestore Emulator `demo-air-quality-monitor` + `rules.test.mjs` | **6/6**, настоящая облачная база не очищалась |
| `flutter build apk --debug` | Успешно, Gradle assembleDebug 29,9 с; APK не устанавливался ради тестов |
| Release APK/AAB | Ранее сегодня повторно собраны после исправления ресурсов: assembleRelease + bundleRelease offline, 1 мин 31 с; production-исходники с тех пор не менялись |
| Подписи release | apksigner / jarsigner успешны, сертификаты совпали с существующим upload-ключом |
| Release Google login | Подтверждён владельцем на отдельном AQM Release Check; установленный APK совпал по hash с итоговым артефактом, UID совпал с прежним профилем |
| Сессия release | Подтверждено отсутствие процесса после force-stop; после нового процесса тот же профиль с именем/email без входа |
| Firebase/FCM | Реальная регистрация/Firestore/foreground/background проверены ранее сегодня; terminated-process FCM + notification tap подтверждены отдельно |
| Crashlytics | Новый контролируемый non-fatal подтверждён read-only серверным API |
| Основной AVD после полного закрытия | Пакет присутствует, дополнительная app data backup 117 МБ, SQLite integrity ok; приложение загрузило Алматы и новый ответ API; прежний профиль подтверждён после запуска AVD |
| Сохранность данных | Все прежние 6 строк samples сохранены, теперь 7; notes 1/1, alerts 4/4; id/place/favorite сохранены, изменилось лишь время viewed; постоянный контрольный файл фото совпал по SHA-256 |
| Подпись/секреты | Keystore и обе signing-конфигурации не изменились по hash; private files исключены из Git; scanner истории: 404 blobs, 0 findings |

Полные диагностические логи и персональные app data — только в `.local-backups/`. Для преподавателя оставлены [краткие результаты](evidence/results.json), [analyze](evidence/analyze.txt), [форматирование](evidence/format.txt), [Dart](evidence/dart-exercises.txt), [Flutter](evidence/flutter-tests-summary.txt), [Security Rules](evidence/firestore-rules-summary.txt). История реальных native-проверок: [Android recovery](../ANDROID_RECOVERY_VERIFICATION.md), [Firebase](../STAGE2_FIREBASE_ANDROID.md), [профиль](../PROFILE_FIREBASE_VERIFICATION.md).

## Повторить безопасно

```sh
flutter analyze
flutter test --coverage --concurrency=1
python3 tools/check_coverage.py
dart run coursework/week01/exercises.dart
python3 -m unittest discover -s functions -p 'test_*.py'
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
  node tools/firebase-tests/node_modules/firebase-tools/lib/bin/firebase.js \
  emulators:exec --only firestore --project demo-air-quality-monitor \
  'node --test tools/firebase-tests/rules.test.mjs'
flutter build apk --debug
python3 tools/secret_scan.py --history
```

Для Rules требуются Node и Java 21+, `npm ci --prefix tools/firebase-tests`. JAVA_HOME выше — путь только для данного Mac, на другой машине указать собственный JDK. Unit/widget tests не устанавливают приложение на Android. Integration-тесты на устройстве с данными запускать только с `--no-uninstall` после резервной копии; login/registration тесты — на отдельном тестовом AVD/аккаунте.

Предупреждение сборки о будущем переходе некоторых Firebase plugins на Built-in Kotlin не мешает текущей сборке. Обновление версий перед сдачей без необходимости не выполняется.

## Границы подтверждения

Физический Android преподавателя, Google Maps с настоящим API key, новое изменение пароля по ссылке, серверный ежедневный AQI scheduler и iOS не прошли эту приёмку. Они не объявляются работающими. По известному списку недель 1–8 эти дополнительные функции не блокируют техническую сдачу РК1; обязательная [GitHub-ссылка](https://github.com/yerkesha-A/air-quality-monitor) опубликована с разрешения владельца, доступ к README и материалам подтверждён без авторизации.
