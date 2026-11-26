# Air Quality Monitor на iOS

## Проверенное состояние

25.11.2026 установлен **Xcode 27.2**, доступен iOS 27.2 runtime. Выполнена настоящая arm64 Simulator debug-сборка существующего Flutter-проекта и нативный integration-прогон на отдельном **AQM iOS QA**. Проверены Swift MethodChannel, Firebase initialization, настоящий Open-Meteo, SQLite/заметки/пагинация, карта/навигация и fallback с реальным кешем при имитации сбоя сети. [Протокол](audit_20261125/ios-integration.json).

Это первый QA debug-прогон 1.1.0 (3), а не приёмка финального Android release или физического iPhone. Google callback проверен в собранном bundle, интерактивный вход и Apple/APNs этим не подтверждены.

Все текущие iOS-плагины подключаются через **Swift Package Manager**. Пустой CocoaPods fallback удалён после резервного копирования: оставшийся Check Pods Manifest.lock ломал сборку после pub get. Поддерживаются iOS 15+, UIScene/Swift AppDelegate и SceneDelegate. Android ID, Firebase-проект и upload key сохранены.

В Xcode 27 окно эмуляторов называется **Device Hub**, а не Simulator.app: Xcode → Open Developer Tool → Device Hub. [Документация Apple](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub).

## Firebase и локальная конфигурация

26.11.2026 после разрешённого исправления подписи текущий iOS Bundle ID — **kz.erkezhan.airqualitymonitor**. Для него отдельно зарегистрирован iOS app в существующем **air-quality-monitor-erkezhan**. Новый Firebase-проект и billing не создавались. Для нового ID скачан настоящий `ios/Runner/GoogleService-Info.plist`, обновлены iOS OAuth client/callback; конфигурация исключена из Git. Прежняя регистрация `com.example.airQualityMonitor` и её приватная конфигурация сохранены. Старое QA-приложение не удаляется: новый Bundle ID имеет отдельный sandbox, автоматического переноса данных между ID нет. Android package остаётся `com.example.air_quality_monitor`.

После получения своего plist:

```sh
flutter pub get
python3 tools/configure_ios_firebase.py
```

Скрипт сверяет Bundle ID и создаёт приватный `ios/Flutter/Firebase.xcconfig` с callback scheme из настоящего plist. Info.plist использует build setting, Google client ID определяется native-каналом только при совпадении callback. Android web client ID не подставляется вместо iOS client ID.

Build phase копирует существующий plist в bundle, отклоняет несовпадающий Bundle ID и устаревший plist в build output. Без конфигурации возможна гостевая сборка; вход честно недоступен. Фиктивная конфигурация для обхода ошибок не создаётся. `Firebase.xcconfig`, `Signing.xcconfig`, plist и Apple `.p8` не публикуются.

## Подпись и физический iPhone

**26.11.2026:** подписанная **Release AOT 1.1.1 (4)** установлена поверх debug-версии с теми же Bundle ID и Personal Team. Deep/strict codesign, provisioning, Firebase plist и Google callback проверены. Перед обновлением сохранена приватная копия контейнера приложения; SQLite `integrity_check = ok`. Удаление приложения не выполнялось. Владелец отключил iPhone от Mac, полностью закрыл приложение и открыл его с главного экрана: запуск и прежние имя/email без повторного Google-входа подтверждены. [Протокол release](audit_20261126/ios-release.json).

Чёрный экран с текстом *In iOS 14+, debug mode Flutter apps can only be launched…* был штатным ограничением debug/JIT, а не доказанным сбоем сохранения Firebase-сессии. Для самостоятельного запуска нужна Release или Profile; установленная Release работает без debugger. Бесплатный development provisioning этой установки истекает **03.12.2026, 15:54 UTC**. После истечения приложение потребуется заново подписать/обновить через Mac, сохраняя Team и Bundle ID; постоянная App Store-подпись этим не предоставляется.

На Mac с 8 ГБ RAM сборка выполнялась последовательно: release config из Flutter, затем `xcodebuild` в конфигурации Release, `-jobs 1`, Swift `-j1`, с настоящей автоматической подписью. Обфускация включена, Dart symbols и dSYM сохранены приватно. `kernel_blob.bin` отсутствует, AOT App.framework присутствует. Никаких QA Dart defines в пользовательской сборке нет.

1. Подключить iPhone по USB, разблокировать и подтвердить доверие. В Device Hub завершить Pair. Включить Настройки → Конфиденциальность и безопасность → Режим разработчика; после необходимой перезагрузки снова разблокировать.
2. В Xcode → Settings → Apple Accounts добавить Apple Account. Открыть **ios/Runner.xcworkspace**, выбрать TARGETS → Runner → Signing & Capabilities → Automatically manage signing → свою Team. Bundle Identifier без согласования не менять.
3. Личная Team хранится в локальном `ios/Flutter/Signing.xcconfig` как `DEVELOPMENT_TEAM = ...`; её значение не входит в Git. Personal Team подходит для доступной бесплатной отладочной установки, но не означает доступность всех capabilities или публикации App Store.
4. Выбрать подключённый iPhone. Перед сборкой штатно закрыть QA Simulator и все Android AVD. При ошибке install/signing остановиться: не удалять существующее приложение/данные для обхода проблемы.
5. Проверить запуск, четыре вкладки, клавиатуру/SafeArea, API/кеш, фото через камеру/галерею, GPS и отказы, уведомления и сохранность после полного закрытия. Физическая проверка отмечается только по результату.

## Авторизация

Email/Password и Google используют существующие AuthRepository/Controller и настоящий iOS Firebase. Для Google после установки открыть вход, нажать «Продолжить с Google», подтвердить тот же аккаунт, затем полностью закрыть и открыть приложение. Пароль не передаётся в чат/репозиторий.

На физическом iPhone новый Google-вход и последующее сохранение сессии при обновлении debug → release и запуске без Mac подтверждены владельцем 26.11.2026. Имя/email и токены в публичный протокол не включены. Владелец также проверил GPS, камеру в заметках, выбор фото из галереи, сохранение фото и локальное уведомление с записью в историю. [Ручная проверка](audit_20261126/ios-physical-owner-check.json). Email/Password, Apple и отказы разрешений учитываются отдельно и этим результатом не объявляются проверенными.

**Apple-вход реализован в коде**, использует `AppleAuthProvider`, native OAuth и отдельную capability-проверку. Кнопка отображается только после реальной настройки. Для включения нужны Sign in with Apple у App ID/Team, соответствующий provisioning и Apple provider существующего Firebase; при необходимости — настоящие Team ID/Key ID/`.p8`. Платная программа и ключи самостоятельно не создаются. После настройки добавить boolean `AQMAppleSignInEnabled = YES` в Info.plist. До этого live Apple-вход не заявляется проверенным.

Удаление аккаунта повторно авторизует владельца до удаления облачных данных. Для связанного Apple identity обязательно получает authorization code и отзывает grant через Firebase до удаления Auth. SDK-моки проверяют порядок; настоящий Apple grant без настройки не имитируется. [Процедура](ACCOUNT_DELETION.md), [официальный Firebase API](https://firebase.google.com/docs/auth/flutter/federated-auth).

## Нативные возможности и публикация

Swift-канал `air_quality_monitor/device` возвращает модель, версию ОС, батарею и признаки реальной Firebase/OAuth-конфигурации. Неизвестный метод возвращает notImplemented. Камера/Photos/foreground location имеют purpose strings; фоновый GPS не запрашивается. SQLite, SharedPreferences, фото и навигация используют общую кодовую базу.

Локальные уведомления не спрашивают разрешение при старте. FCM ожидает настоящий APNs token. **APNs push требует корректных Apple capabilities, provisioning и ключа в Firebase**, это не заменяется полем UIBackgroundModes или Android-проверкой. Live APNs и iOS Crashlytics/dSYM проверяются отдельно после подписанной установки. Personal Team не считается подтверждением готовности этих функций.

Перед App Store также нужны рабочий Apple-вход, проверенная процедура удаления, App Privacy, HTTPS политика/поддержка, store screenshots и подпись владельца. Публикация и платные аккаунты не выполнялись. [Текущие требования Apple](https://developer.apple.com/app-store/submitting/), [Firebase Apple setup](https://firebase.google.com/docs/ios/setup).

На Mac с 8 ГБ RAM запускать только один стенд и собирать последовательно с `xcodebuild -jobs 1`. Первичные iPhone layout/widget-тесты не подменяют нативный прогон. `integration_test/ios_flow_test.dart` требует отдельный QA marker; тест удаления дополнительно ограничен локальным `demo-air-quality-monitor` и не удаляет рабочие аккаунты.
