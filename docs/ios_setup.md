# Запуск Air Quality Monitor на iOS

Подготовлено 25.11.2026 для существующего проекта. Android и iOS используют одну кодовую базу. **iOS пока не собран и не запущен:** на этом Mac есть Command Line Tools, но нет полного Xcode, iOS Simulator и CocoaPods. `flutter build ios --simulator --debug --no-pub` завершился `Application not configured for iOS`; `xcodebuild -version` и `xcrun simctl` также не работают. Проверка синтаксиса Swift не заменяет сборку с UIKit/Flutter.

## Что подготовлено

- Существующий Runner, Swift AppDelegate/SceneDelegate, bundle ID `com.example.airQualityMonitor`, deployment target **iOS 15.0** (требование установленного Firebase SDK).
- Native MethodChannel `air_quality_monitor/device`: модель, версия iOS, батарея, наличие настоящей Firebase-конфигурации. Неизвестный метод возвращает notImplemented.
- Описания камеры, фотографий и геолокации в `ios/Runner/Info.plist`. Фоновый GPS не используется; камера снимает только фото, поэтому разрешение микрофона не добавлено.
- Локальные уведомления iOS без запроса разрешения при старте; запрос только при включении функции. FCM ожидает APNs token.
- Отдельный iOS Google client ID; Android web client ID и существующая Android-подпись сохранены.
- CocoaPods fallback: `ios/Podfile`, optional xcconfig includes; foreground-only geolocator flag для CocoaPods. При SwiftPM флаги плагина необходимо сверить на настоящей сборке.
- Иконки Runner и центрированный launch screen со светлым/тёмным фоном экспортированы из существующего знака приложения, дизайн не менялся.
- Widget-проверки 375×667, 393×852 и 852×393, iOS theme/platform, insets, крупный текст, клавиатура, обе темы. Это модельные проверки layout, а не снимки работающего iPhone.

SQLite/sqflite, SharedPreferences, path_provider, image_picker, geolocator, Google Sign-In и Firebase имеют iOS-реализации среди установленных зависимостей. Open-Meteo и OSM используют HTTPS; отключение App Transport Security не требуется. Фото сохраняется в каталоге приложения, не в общей галерее. GoRouter и Provider/BLoC общие.

## 1. Установить окружение

На MacBook свободно около 6 ГБ перед новыми сборками — для Xcode и runtime этого недостаточно. Освободите место самостоятельно либо перенесите ненужные личные файлы на внешний диск. Не удаляйте AVD, резервные копии, keystore и папку проекта ради установки.

1. Установите полный Xcode из App Store или [Apple Developer](https://developer.apple.com/xcode/), совместимый с macOS и версией iOS вашего iPhone. Запустите его, примите лицензию и установите необходимые компоненты.
2. Выберите developer directory и завершите первичную настройку:

   ```sh
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   xcodebuild -version
   ```

3. В Xcode → Settings → Components установите **один** iOS runtime. Не скачивайте несколько симуляторов на Mac с 8 ГБ RAM.
4. Установите CocoaPods по [официальной инструкции](https://guides.cocoapods.org/using/getting-started.html#installation). Если Homebrew уже установлен, обычно используется `brew install cocoapods`. Не запускайте `sudo pod install`.
5. В корне существующего проекта:

   ```sh
   flutter doctor -v
   flutter pub get
   ```

Flutter поддерживает SwiftPM; в этом проекте присутствуют и зависимости, которым может потребоваться CocoaPods. Не удаляйте Runner и не выполняйте `flutter create .` для обхода ошибки. После установки Xcode повторно проверьте разрешение нативных зависимостей.

## 2. Первый запуск без Firebase

Пока настоящего `GoogleService-Info.plist` нет в bundle, мониторинг/карта/локальные данные должны работать без аккаунта; вход честно отображается неподключённым. Это ожидаемое поведение, которое ещё нужно подтвердить запуском iOS.

Полностью закройте Android-эмулятор штатно; запускайте только один Simulator:

```sh
open -a Simulator
flutter devices
flutter build ios --simulator --debug
flutter run -d <ID_симулятора_из_flutter_devices>
```

В Simulator выберите один iPhone в File → Open Simulator, если устройство ещё не открыто. При ошибке сборки сохраните лог и остановитесь: не удаляйте приложение/данные, не сбрасывайте симулятор и не запускайте `flutter clean`.

У симулятора нет настоящей камеры; выбор фото и модельная геолокация не подтверждают физические датчики. Для тестового GPS используйте Features → Location. Для галереи импортируйте безопасное тестовое фото.

## 3. Настоящий Firebase для iOS

Read-only проверка 25.11: Bundle ID `com.example.airQualityMonitor` ещё **не зарегистрирован** среди iOS apps существующего Firebase-проекта. Android-приложение остаётся прежним.

1. Откройте существующий проект **air-quality-monitor-erkezhan** в Firebase Console → Project settings → General → Your apps → Add app → iOS. Не создавайте новый Firebase-проект и не подключайте billing.
2. Укажите **точно** `com.example.airQualityMonitor` — текущий PRODUCT_BUNDLE_IDENTIFIER Runner. Если Xcode Personal Team потребует другой уникальный ID, сначала согласуйте его и используйте тот же ID в Firebase; Android applicationId не меняйте.
3. Скачайте настоящий **GoogleService-Info.plist**, поместите в `ios/Runner/GoogleService-Info.plist`.
4. Откройте `ios/Runner.xcworkspace` в Xcode, добавьте файл в группу Runner, target membership **Runner**; убедитесь, что он есть в Build Phases → Copy Bundle Resources. Наличие файла на диске без включения в bundle недостаточно.
5. Файл исключён из Git; APNs `.p8` и `firebase_app_id_file.json` также игнорируются. Не подставляйте Android `google-services.json`, чужой plist или фиктивные значения. Проверьте `git check-ignore ios/Runner/GoogleService-Info.plist`.
6. Повторите сборку и проверьте Email/Password, чтение Firestore с сервера, отказ чужому UID, offline/online, выход/вход и сохранение сессии после полного закрытия. Не используйте личные данные в публичных логах.

Инициализация остаётся общей: `FirebaseService.create` вызывает `Firebase.initializeApp()` только при наличии native-конфигурации. Настоящий plist содержит публичные идентификаторы конфигурации, но по правилам проекта хранится локально.

## 4. Google Sign-In

Используйте iOS OAuth-конфигурацию из **настоящего iOS plist**, а не Android SHA/web client вместо iOS client:

1. Проверьте включённый Google provider в Firebase Authentication (он уже включён для проекта).
2. В `ios/Runner/Info.plist` добавьте URL type с единственным нужным scheme из `REVERSED_CLIENT_ID` настоящего plist. Скопируйте значение, не придумывайте его. Сохраните уже существующие URL types, если они появились.
3. Native-канал прочитает `CLIENT_ID` из plist и передаст в `GoogleSignIn.initialize(clientId: ...)`. Кнопка активируется только при наличии Firebase и соответствующего callback URL scheme.
4. Для этой Firebase ID-token схемы серверный client ID не задан на iOS. Если позже понадобится отдельный backend OAuth, настройте настоящий web/server client ID отдельно; Android-настройки не меняйте.
5. Выполните интерактивный вход самостоятельно, без передачи пароля в чат; затем полностью закройте и запустите приложение и проверьте тот же аккаунт.

## 5. FCM и Crashlytics

Наличие Dart-кода **не означает**, что Apple push уже подключён.

- В Xcode Runner → Signing & Capabilities потребуются **Push Notifications** и **Background Modes → Remote notifications**. `remote-notification` в Info.plist уже подготовлен, но подписанные APNs entitlements и provisioning ещё отсутствуют.
- В Firebase → Project settings → Cloud Messaging → iOS app настройте настоящий APNs auth key `.p8`, Key ID и Team ID. Требуются доступы/возможности Apple Developer. Если для вашего аккаунта нужна платная программа — остановитесь; ничего платного автоматически не подключается.
- Не отключайте Firebase AppDelegate swizzling. После разрешения уведомлений SDK должен получить APNs token, затем FCM token. Пока APNs token отсутствует, включение push возвращает недоступность без падения приложения.
- Проверьте настоящую доставку foreground/background/terminated и переход в историю на iPhone. Не подменяйте её локальным уведомлением или Android-результатом. Условия фоновой доставки iOS отличаются от Android.
- Для Crashlytics добавьте рекомендуемый SDK upload-symbols/run script по [официальной инструкции](https://firebase.google.com/docs/crashlytics/get-started?platform=flutter), проверьте dSYM/символы именно iOS. Новое non-fatal событие и появление в Console ещё не проверены. Android-событие 23.11 не является iOS-доказательством.

## 6. Запуск на своём iPhone

1. Подключите iPhone к Mac, разблокируйте и подтвердите «Доверять этому компьютеру».
2. Включите Developer Mode по запросу iOS, выполните требуемую перезагрузку телефона.
3. В Xcode → Settings → Accounts войдите в Apple Account самостоятельно.
4. Откройте `ios/Runner.xcworkspace`, выберите Runner → Signing & Capabilities → вашу Team, automatic signing. Бесплатная Personal Team подходит для базового запуска на своём устройстве с ограничениями; APNs и публикация проверяются отдельно. Членство/оплату не оформляйте автоматически.
5. Выберите iPhone в destination и Run. Либо после успешного signing выполните `flutter devices`, затем `flutter run -d <ID_iPhone>` из корня проекта.
6. Если уже установлена версия с этим Bundle ID и другой подписью, **не удаляйте её** ради запуска: остановитесь и сначала оцените сохранность данных.
7. Проверьте: старт/темы/клавиатуру, настоящий Open-Meteo, OSM, GPS с отказом и повторным разрешением, камеру/галерею/отмену, сохранение фото/настроек после перезапуска, Firebase и Google после настоящей настройки. Скриншоты профиля публикуйте без email/имени/фото.

iPhone-проверка подтверждает iOS, но не закрывает обязательное физическое Android-тестирование недели 11.

## Источники

[Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup), [Firebase Apple setup](https://firebase.google.com/docs/ios/setup/), [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup), [Google Sign-In iOS](https://pub.dev/packages/google_sign_in_ios), [FCM/APNs prerequisites](https://firebase.google.com/docs/cloud-messaging/flutter/get-started), [image_picker](https://pub.dev/packages/image_picker), [geolocator](https://pub.dev/packages/geolocator). Проверены 25.11.2026; учитывайте совместимость именно зафиксированных версий в `pubspec.lock`.

## Подготовка к будущему App Store

Правило [4.8 Login Services](https://developer.apple.com/app-store/review/guidelines/#login-services) требует при стороннем/social login эквивалентный вариант с указанными Apple свойствами приватности, если исключения не применимы. Наличие Email/Password само по себе не подтверждает соответствие этому пункту. Для этого приложения стандартный путь — **Sign in with Apple**: потребуются capability/провайдер Firebase и реальные проверки на Apple-стенде. Сейчас этот вход **не реализован**; не добавляется неработающая кнопка и не оформляется платная программа.

Проверить также правило 5.1.1 об удалении аккаунта. Текущий запрос через email разработчику не объявляется достаточным in-app deletion для App Store: перед публикацией нужен принятый Apple сценарий полного удаления аккаунта/связанных данных и, при Apple login, отзыва токенов. Данные существующих пользователей во время подготовки не удаляются. Это отдельные блокеры публикации наряду с Xcode, signing, Firebase iOS и APNs.
