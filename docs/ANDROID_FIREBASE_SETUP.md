# Firebase Authentication для Android — следующий шаг пользователя

Firebase-проекта пока нет. Email-регистрация, вход, восстановление, выход и наблюдение
за SDK-сессией подготовлены в коде. Реальные аккаунты не создавались, облачный вход
ещё не проверен. Google Sign-In подготовлен, но без OAuth client ID его кнопка отключена.
Google Maps и iOS сейчас не настраиваем. Firestore, Storage и push не нужны для первой
проверки email-авторизации и будут отдельными этапами.

## Что сделать в Firebase Console

1. Откройте [Firebase Console](https://console.firebase.google.com/) под своим Google-аккаунтом.
2. Нажмите **Create a project / Создать проект**, назовите его **Air Quality Monitor**.
   Выберите доступный Project ID и сохраните его. Google Analytics для email-входа не требуется;
   можно пока отключить этот пункт мастера.
3. В обзоре проекта нажмите значок **Android** / **Add app**.
4. Укажите Android package name точно: **`com.example.air_quality_monitor`**.
   Nickname: `Air Quality Monitor Android`.
   Это applicationId существующего проекта; не создавайте новую Flutter-программу.
5. Добавьте реальные fingerprints текущей debug-подписи:
   - SHA-1: `61:BB:E7:FA:D7:9B:52:9A:68:FB:DD:64:A8:F8:E8:B8:6C:00:47:06`.
   - SHA-256: `77:FC:05:D9:D8:6C:51:0D:2A:05:71:D3:E2:B8:66:14:5E:68:C2:9A:B6:32:F5:B3:C6:53:8D:81:C7:50:A3:B5`.
   Это публичные отпечатки сертификата, не private keys. Для email-входа SHA не обязателен,
   но он нужен при последующей настройке Google Sign-In. Release-подпись позже добавляется отдельно.
6. Скачайте **google-services.json**. Поместите его в существующий проект:
   **`android/app/google-services.json`**. Не переименовывайте и не редактируйте содержимое.
   Файл уже исключён из Git.
7. Откройте **Authentication → Get started → Sign-in method**.
   Включите **Email/Password**, сохраните. Вход по email-link пока включать не нужно.
8. В **Authentication → Templates** проверьте шаблон **Password reset** и язык письма.
   В приложении при регистрации требуется минимум 8 символов пароля; если вы зададите более
   строгую Password policy в Console, нужно согласовать проверку формы с ней.
9. Сообщите **Project ID** и что JSON уже лежит в указанном месте. На этом ваш первый шаг завершён.

Не нужны service account JSON, приватные ключи или пароль вашего Google-аккаунта.
Не создавайте тестовые аккаунты вручную вместо регистрации через приложение.

## Google Sign-In — отдельная проверка

Если хотите подготовить его сразу: включите **Google** в Authentication → Sign-in method,
выберите support email, убедитесь, что SHA добавлены в Android app settings, и повторно скачайте
`google-services.json`. OAuth web client из настоящей конфигурации используется как
`serverClientId`; никаких вымышленных client ID в коде нет. Доступность кнопки после конфигурации
ещё не означает успешной приёмки — вход нужно проверить на Android с Google Play services.

## Что уже готово в существующем Android-проекте

- Firebase зависимости и плагины Google Services/Crashlytics объявлены в Gradle.
- Плагины применяются только при наличии настоящего `android/app/google-services.json`.
- Native `google_app_id` определяет наличие конфигурации; `Firebase.initializeApp()` использует
  Android resources, созданные Google Services plugin. Для текущей Android-only схемы ручные
  `FirebaseOptions` и фиктивный `firebase_options.dart` не нужны.
- Firebase Auth SDK хранит сессию нативно; приложение слушает `userChanges()`.
- Provider обрабатывает loading/errors, защищает от повторной отправки формы и не удаляет
  локальную историю/избранное/кеш при выходе.
- Unit-тесты используют SDK mocks и проверяют вызовы/ошибки/сессионный поток;
  это не доказательство успешного облачного входа.

## Приёмка после получения конфигурации

Выполняем полную пересборку (hot reload недостаточно), затем на Android Emulator:

1. Регистрируем выбранный вами реальный тестовый email через форму; проверяем пользователя в Console.
2. Выходим и входим снова. Проверяем неверный пароль, повторную регистрацию, ошибки сети.
3. Проверяем письмо восстановления и вход с новым паролем.
4. Перезапускаем приложение и проверяем сохранённую сессию.
5. Выходим; убеждаемся, что аккаунт закрыт, а история/избранное/настройки сохранены.
6. Отдельно проверяем Google Sign-In после включения провайдера и обновления JSON.

Firestore-профиль/Storage/FCM/Maps не считаются готовыми по результатам email-входа.

Официальные инструкции: [Android-конфигурация](https://firebase.google.com/docs/android/setup),
[Firebase для Flutter](https://firebase.google.com/docs/flutter/setup),
[email/password](https://firebase.google.com/docs/auth/flutter/password-auth),
[сессия и изменения состояния](https://firebase.google.com/docs/auth/flutter/start).
