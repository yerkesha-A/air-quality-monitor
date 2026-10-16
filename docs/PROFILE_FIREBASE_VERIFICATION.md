# Профиль и Firebase: проверка 16 октября 2026

## Изменения профиля

- Круглый аватар 88×88 logical px; в карточке вкладки профиля — 48×48.
  Размер ограничен независимо от ширины ListView. Google photo URL отображается
  внутри ClipOval; при ошибке/отсутствии фото — инициалы. Локальное фото имеет приоритет.
- Имя/email, молочные и голубые поверхности существующей темы, maxWidth 640,
  прокрутка и явная кнопка «Назад» с переходом в `/profile`, если стека нет.
- «Изменить фото» открывает галерею или камеру через существующий ImagePicker.
  Изображение уменьшается до 640×640, quality 80; локальный лимит 5 МБ.
- LocalAvatarStore сохраняет фото в documents/profile_photos отдельно по UID.
  Это постоянные приватные файлы, не временный путь picker. Запись атомарная,
  имя файла меняется для обновления image cache; чужие UID не затрагиваются.
- Фото не загружается в Storage и не меняет Google photoURL. Локальный путь
  не включён в Firestore. При выходе фото остаётся на устройстве для того же UID.
- Локальное сохранение работает без Firebase reload/интернета. Новое фото
  обновляет stream профиля. SDK Google Sign-Out вызывается и после восстановления
  сессии в новом процессе, когда GoogleSignIn ещё не инициализирован в Dart.

## Результаты

| Проверка | Результат |
| --- | --- |
| `flutter analyze --no-pub` | Без замечаний |
| Все unit/widget tests | 66/66 |
| LCOV `flutter test --coverage --no-pub` | 2103/3039 = 69,20% |
| `python3 tools/check_coverage.py` | Успешно, выше 40% |
| Profile widget matrix | 320×568, 740×360, 800×1280, 1280×800, обе темы, текст 150% |
| Camera/gallery source actions | Widget-тесты передают выбранные байты в avatar action |
| Локальное фото | Unit: новый store, изоляция UID, замена, ошибки записи; Android: контрольное изображение пережило остановку процесса |
| Android integration capture | Прошёл, существующая Google-сессия владельца |
| Android integration verify | Прошёл после force-stop, совпали UID, настройки, избранное, выбранный город |
| Android Google logout/login + route guard + reset request | Прошёл; выбран тот же существующий Google-аккаунт в native chooser |
| Android final verify | Прошёл после повторного Google-входа и force-stop, включая сохранность файла фото |
| Android profile | Проверены размер аватара, email, меню камеры/галереи, Back |
| Логи проверенного Android-процесса | 0 найденных Firebase error lines / fatal / unhandled errors |
| `git diff --check` | Успешно |

Все четыре native integration-запуска использовали **`--no-uninstall`**.
Тест не очищает preferences/SQLite, не заменяет владельца тестовым аккаунтом,
не удаляет приложение. Для проверки фото использовалась отдельная тестовая папка
в app documents; фотография владельца не заменялась. Это подтверждает постоянство
хранилища; ручной выбор личного фото в системной галерее отдельно не выполнялся.

Google logout/login проверен настоящим Firebase SDK и Android Credential Manager:
после выхода currentUser был null, попытка открыть `/account` перенаправила на
AuthScreen; после выбора единственного существующего аккаунта вернулся исходный UID.

Запрос настоящего письма восстановления отправлен через Firebase Auth на email
текущего Google-профиля. Успешный ответ SDK подтверждён; владелец ответил
«Да, письмо пришло». Доставка на настоящий email проверена. Пароль не менялся.
Смена пароля по ссылке и вход с новым паролем ещё не проверены.

Резервные копии исходников и полных app data (117 МБ) созданы до изменений:
`.local-backups/profile-firebase/`. Логи и снимки с персональным профилем остаются
там же и не публикуются. Обычный debug APK собран после integration-тестов;
обновление выполняется через `adb install -r -t`, без очистки данных.

## Google Maps — подключение остановлено

Read-only Cloud API подтвердил для `air-quality-monitor-erkezhan`:
`billingEnabled: false`, `mapsAndroidService: DISABLED`.
`maps.apiKey` и `GOOGLE_MAPS_API_KEY` отсутствуют.

[Официальная документация Maps SDK for Android](https://developers.google.com/maps/documentation/android-sdk/usage-and-billing)
требует включённого billing для проекта. Поэтому API не включался, ключи не создавались,
billing не подключался; другая карта не подставлялась. Реализация новых маркеров,
выборки точек/debounce/cache и native-приёмка карты отложены до решения владельца.
Текущее состояние MapScreen не объявляется готовой картой качества воздуха.

Firebase Storage, iOS, AlmaU App и GitHub publication не затрагивались.

## Повторить безопасно

```sh
flutter analyze --no-pub
flutter test --coverage --no-pub
python3 tools/check_coverage.py
flutter test integration_test/profile_session_test.dart -d emulator-5554 --no-uninstall --no-pub
# После остановки процесса, без изменения preferences и favorites:
flutter test integration_test/profile_session_test.dart -d emulator-5554 --no-uninstall --no-pub --dart-define=VERIFY_PROFILE_RESTART=true
```

Integration предполагает уже авторизованный Google-аккаунт. Optional define
`RECHECK_GOOGLE_LOGIN=true` выполняет настоящий logout/login с выбором аккаунта
на Android; `SEND_PROFILE_RESET=true` действительно отправляет письмо владельцу.
Не добавлять эти defines в автоматический CI и не запускать их повторно без необходимости.
