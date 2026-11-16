# Подготовка тестовой доставки

Подготовлено 16.11.2026. Загрузка не выполнялась.

## Firebase App Distribution

Это отдельное действие от GitHub push. Нужны явное разрешение владельца на загрузку сборки и адреса тестировщиков, которым разрешено отправить приглашение. Публичный контакт разработчика не считается согласием на отправку приглашения.

Read-only проверка текущего Firebase-проекта вернула 404 для App Distribution. Нужно открыть существующий проект в Firebase Console и проверить инициализацию раздела App Distribution. Создавать новый Firebase-проект и подключать billing не требуется.

Перед загрузкой:

1. Проверить текущий APK, подпись существующим ключом и вход на отдельном release-AVD.
2. Сохранить APK и соответствующие Dart symbols вне Git.
3. Подготовить release notes и согласованные адреса тестировщиков.
4. После отдельного разрешения выполнить `firebase appdistribution:distribute PATH_TO_APK --app FIREBASE_ANDROID_APP_ID --testers APPROVED_EMAILS --release-notes-file RELEASE_NOTES`.
5. Проверить ссылку доставки и установку тестировщиком. Успешная локальная сборка не подтверждает доставку.

## Crashlytics

Release включает сбор ошибок Firebase Crashlytics. Для обфусцированных Dart-стеков нужно сохранить symbols именно от соответствующей сборки. При разрешённой подготовке серверной символизации используется `firebase crashlytics:symbols:upload --app=FIREBASE_ANDROID_APP_ID SYMBOLS_DIRECTORY`.

Успех SDK, HTTP-доставка и появление события в Firebase Console — разные уровни подтверждения. Пока текущая контролируемая ошибка не проверена, не отмечать её принятой сервером.

## App Store

Android AAB нельзя отправить в App Store. Для iOS отдельно потребуются macOS/Xcode, iOS-конфигурация того же Firebase-проекта, Bundle ID, разрешения камеры/геолокации, подпись Apple, проверка Sign in with Apple при применимости требований, App Privacy и проверка на iPhone. Платная регистрация Apple Developer не выполнялась. Этот этап не считается завершённым.

Справочные первоисточники: [App Distribution](https://firebase.google.com/docs/app-distribution/android/distribute-cli), [символы Flutter Crashlytics](https://firebase.google.com/docs/crashlytics/flutter/get-deobfuscated-reports), [обфускация Flutter](https://docs.flutter.dev/deployment/obfuscate).
