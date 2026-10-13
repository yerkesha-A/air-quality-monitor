# Следующий этап: Firebase и Google Maps для Android

Проект Firebase ещё не создан. Ниже реальные значения существующей debug-сборки; это публичные fingerprints сертификата, не private key.

## Firebase Console

1. Откройте https://console.firebase.google.com/ и создайте **Air Quality Monitor**.
2. Добавьте Android application:
   - Package: `com.example.air_quality_monitor`.
   - Nickname: `Air Quality Monitor Android`.
   - Debug SHA-1: `61:BB:E7:FA:D7:9B:52:9A:68:FB:DD:64:A8:F8:E8:B8:6C:00:47:06`.
   - Debug SHA-256: `77:FC:05:D9:D8:6C:51:0D:2A:05:71:D3:E2:B8:66:14:5E:68:C2:9A:B6:32:F5:B3:C6:53:8D:81:C7:50:A3:B5`.
3. Скачайте `google-services.json` и положите в `android/app/google-services.json`.
4. Authentication → Sign-in method: включите **Email/Password** и **Google**, задайте support email. После включения Google и добавления SHA повторно скачайте JSON, чтобы в нём появился OAuth web client.
5. Создайте Firestore database. Не используйте открытые test rules: для проекта подготовлен `firestore.rules`, локально прошедший 6 проверок.
6. Для аватара подключите Storage с `storage.rules`; сначала проверьте требования тарифа в Console.
7. Сообщите Project ID и регион Firestore. Service account/private keys отправлять не нужно.

Gradle автоматически применяет Google Services/Crashlytics plugins при наличии настоящего JSON. Файл исключён из Git. Этот debug-сертификат нужно заменить fingerprint вашего release-сертификата при подготовке production-публикации; package сейчас сохранён от исходного проекта.

## Google Maps

В соответствующем Google Cloud project включите Maps SDK for Android и billing. Создайте API key, ограничьте его **Android application**: package выше + SHA-1 выше. Ограничьте список API: Maps SDK for Android.

Добавьте ключ локально в игнорируемый `android/local.properties`:

```properties
maps.apiKey=ВАШ_РЕАЛЬНЫЙ_КЛЮЧ
```

Не заменяйте остальные строки этого файла. Полная пересборка обязательна: hot reload не обновляет AndroidManifest.

## Приёмка после настройки

```sh
flutter run -d emulator-5554
```

Проверяем email/register/reset/Google/session/logout, запись собственного профиля и favorites, запрет чтения чужих данных, avatar upload, tiles/markers/gestures карты и GPS. После этого отдельно готовим и согласовываем backend deployment, включаем scheduler и проверяем реальную доставку FCM. Флаг `AQI_SCHEDULER_DEPLOYED=true` задаётся только после подтверждённого развёртывания и доставки, а не вместо проверки.

iOS не настраиваем на этом этапе.
