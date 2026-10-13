# Air Quality Monitor

Нативное мобильное приложение на Dart + Flutter. Сейчас разрабатываем и проверяем **только Android**. iOS отложен по просьбе пользователя. Веб-интерфейс не создавался.

Цель — помочь жителям городов, студентам, родителям и спортсменам понимать качество воздуха, сравнивать места и планировать активность.

## Что реализовано

- Onboarding с жестами и сохранением завершения.
- Главный экран: текущая оценка US AQI, шесть загрязнителей при наличии, время данных/получения, обновление и pull-to-refresh.
- Прогноз на 24 часа, график с выбором точки, лучший час по минимуму доступного AQI.
- Поиск городов с debounce, избранное, недавние места, сохранение выбора, GPS и reverse geocoding.
- Сравнение двух городов с независимой загрузкой данных и временем получения.
- История сохранённых текущих оценок: 24 часа / 7 / 30 дней, US AQI / PM₂.₅ / PM₁₀, среднее/максимум, календарь доступных дней.
- Рекомендации по AQI и справочник загрязнителей.
- Светлая, тёмная и системная темы; единицы мкг/м³ или мг/м³ для состава воздуха на главной.
- Заметки с текстом и фотографией через Android camera intent; сохранение фото в приватной папке приложения.
- Локальные предупреждения при обновлении свежего AQI выше персонального порога, разрешение Android notifications и история.
- Собственный Android Platform Channel: модель устройства, API level, батарея; кнопка «Об устройстве» в профиле.
- GoRouter: именованные маршруты, StatefulShellRoute, сохранение вкладок, маршрут `/city/:id`, redirect защищённого `/account`, неизвестный маршрут.

Google Maps, Firebase Auth (email/register/Google/reset/session/logout), Firestore, Storage для аватара, FCM и Crashlytics **имеют код интеграции, но ещё не подключены к реальному облачному проекту**. UI явно показывает этот статус; кнопки входа не имитируют успешную авторизацию. Фоновые push не активированы и не проверены.

Полный реестр и подтверждённые проверки: [PROJECT_PROGRESS.md](PROJECT_PROGRESS.md).

## Дизайн

Слоновая кость #F5F2E9, лесной зелёный #203F33, шалфей #A9B49B, графит #242A26. Шрифты Manrope и Lora встроены локально с OFL-лицензиями — загрузка из сети для шрифтов не нужна. Сетка отступов 8 pt, поля 24 pt, крупная типографика и компактные строки данных. Цвет категории AQI отделён от фирменной палитры.

SafeArea, прокрутка, клавиатура, системный back, нижняя навигация и масштабирование текста учитываются в экранах. Тестируется ширина 320 px, альбомная ориентация onboarding и увеличенный текст. Ориентиры продукта: IQAir AirVisual (AQI), Windy (карта), Plume Labs (планирование активности).

## Архитектура

```text
lib/core/             тема, router, DI
lib/presentation/     экраны, общие widgets, Provider-контроллеры, BLoC
lib/domain/           сущности, interfaces Repository, рекомендации/use cases
lib/data/             API, generated JSON-модели, SQLite, repositories, native/cloud services
functions/            отдельный Python backend для серверных предупреждений
```

Provider используется для небольших настроек и состояния аккаунта/избранного. BLoC обслуживает Air, CitySearch и History с состояниями Initial / Loading / Success / Empty / Error / Refreshing там, где применимо. Счётчики ревизий защищают от запоздавших ответов. Реализации Repository передаются через конструкторы в `AppDependencies`; production-код не содержит фиктивных значений загрязнения.

`setState` подходит для локального UI (форма, slider, выбранная точка графика), `InheritedWidget` передаёт зависимости по дереву, Provider добавляет удобную подписку и жизненный цикл модели. Отдельный работающий учебный пример всех трёх подходов: [docs/state_examples.dart](docs/state_examples.dart). Запуск: `flutter run -t docs/state_examples.dart -d emulator-5554`. Пример не является частью production-потока AQI.

## Источник и смысл данных

[Open-Meteo Air Quality API](https://open-meteo.com/en/docs/air-quality-api) предоставляет **оценки атмосферной модели Copernicus CAMS**, а не показания ближайшей физической станции. Запрашиваются `us_aqi`, `pm2_5`, `pm10`, `nitrogen_dioxide`, `ozone`, `carbon_monoxide`, `sulphur_dioxide`. Все концентрации исходно в мкг/м³. Используются Unix timestamps; часовые подписи учитывают UTC offset выбранного места.

Шкала только US AQI: 0–50 / 51–100 / 101–150 / 151–200 / 201–300 / 301+. [Категории EPA / AirNow](https://www.airnow.gov/aqi/aqi-basics/). Рекомендации ознакомительные, без медицинской диагностики. Поиск и разрешение ID города — [Geocoding API / GeoNames](https://open-meteo.com/en/docs/geocoding-api). Бесплатный API предназначен для некоммерческого использования; перед коммерческой публикацией необходимо проверить актуальный тариф/условия.

API-клиент проверяет HTTP, JSON, поля, нечисловые/отрицательные значения и таймаут 18 секунд. Нет выдуманных значений для отсутствующих загрязнителей.

## Локальные данные и офлайн

SharedPreferences: тема, единицы, пороги/разрешённые сценарии уведомлений, onboarding, выбранное место. SQLite: кеш ответов, избранное/недавние места, текущие оценки по часовым слотам, заметки, история предупреждений. Схема содержит миграцию версии 1 → 2.

При загрузке сначала показывается кеш, затем сетевой результат. При недоступности источника сохраняется время исходного получения и отмечается кеш/офлайн; данные старше часа помечаются как сохранённые. История записывает **только текущую оценку при запросе**, не прогноз. Она накапливается с использованием приложения, ограничена примерно 31 днём и не представляет непрерывные станционные измерения. Среднее считается по доступным точкам. На новом устройстве 30-дневного архива нет.

## Запуск Android

Flutter 3.47.5 / Dart 3.13.4. Android SDK и лицензии проверены. Установлены Java из Android Studio, AGP 9.1.0 и Gradle 9.3.1. Минимальная версия приложения — Android API 24.

```sh
flutter pub get
flutter run -d emulator-5554
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Это debug-сборка для тестирования, не подписанный production-релиз. Локальный Gradle wrapper использует установленный пользователем `/tmp/gradle-9.3.1-all.zip`; на чистом компьютере выполните `python3 tools/portable_gradle.py`, чтобы переключиться на официальный HTTPS-дистрибутив той же версии. CI выполняет этот шаг автоматически.

Подробная инструкция с настоящими debug SHA fingerprints: [docs/ANDROID_FIREBASE_SETUP.md](docs/ANDROID_FIREBASE_SETUP.md).

## Firebase: нужны действия владельца проекта

1. Создайте проект Air Quality Monitor в [Firebase Console](https://console.firebase.google.com/).
2. Добавьте **Android app**, package: `com.example.air_quality_monitor` — существующий идентификатор сохранён.
3. Скачайте настоящий `google-services.json` в `android/app/google-services.json`.
4. Authentication → Sign-in method: включите Email/Password и Google; задайте support email. Добавьте SHA-1/SHA-256 вашей debug-подписи; после этого повторно скачайте JSON с OAuth client.
5. Создайте Firestore. Опубликуйте проверенные `firestore.rules`; для аватара потребуется Firebase Storage и `storage.rules`. Перед включением платных сервисов/серверного scheduler проверьте тариф в Console.
6. Пересоберите приложение. Google Services и Crashlytics Gradle plugins применяются только при наличии настоящего JSON. Конфигурация без фиктивных ключей.
7. Проверьте регистрацию, вход, Google, reset, восстановление сессии и выход на Android. После входа код сохраняет профиль/настройки/избранное в Firestore; облачная интеграция и восстановление данных между устройствами требуют отдельной приёмки.

[Официальная настройка Android Firebase](https://firebase.google.com/docs/android/setup). Не добавляйте JSON, signing keys и service account credentials в публичный репозиторий: соответствующие пути исключены `.gitignore`.

## Google Maps

В Google Cloud включите Maps SDK for Android и billing. Создайте Android API key с ограничениями package `com.example.air_quality_monitor` + SHA-1 и ограничением API Maps SDK for Android. Добавьте `maps.apiKey=ВАШ_РЕАЛЬНЫЙ_КЛЮЧ` в игнорируемый `android/local.properties` или передайте `GOOGLE_MAPS_API_KEY` окружению сборки. Пересоберите APK.

Карта — `google_maps_flutter` / настоящий Android SDK, без статической подмены. Код поддерживает выбор точки, маркеры текущего/сохранённых мест, проверку центра после перемещения и GPS. Ключ и tiles/gestures пока не проверены: сервиса ещё нет. [Документация пакета](https://pub.dev/packages/google_maps_flutter).

## Уведомления и сервер

Локальные предупреждения проверяются при получении свежего AQI в открытом приложении, с дедупликацией места/часа/порога. Они не обещают фоновую периодическую работу. FCM-код включает foreground/background reception, токены устройства, историю получения и открытие Alerts по нажатию.

`functions/main.py` — отдельный сервер на Python для Cloud Functions + Cloud Scheduler. Он получает настоящий US AQI, проверяет порог и актуальность модели, использует Firestore transaction для дедупликации и отправляет FCM только зарегистрированным устройствам соответствующего пользователя. Успешная отправка в FCM не доказывает доставку на телефон. Код не развёрнут; тесты Python сейчас проверяют только чистую логику порогов/координат/ID, а не весь облачный job.

После настройки Firebase, ревью backend и согласования облачного развёртывания необходимо проверить фактическую доставку foreground/background, токен после переустановки и tap routing. Только после этой проверки используйте `--dart-define=AQI_SCHEDULER_DEPLOYED=true`, чтобы активировать UI фоновых предупреждений. [Cloud Scheduler](https://firebase.google.com/docs/functions/schedule-functions) и [FCM reception](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages).

## Тестирование

```sh
flutter analyze
flutter test --coverage
python3 tools/check_coverage.py
flutter test integration_test/mobile_smoke_test.dart -d emulator-5554
flutter test integration_test/air_flow_test.dart -d emulator-5554
python3 -m unittest discover -s functions -p 'test_*.py'
npm ci --prefix tools/firebase-tests
node tools/firebase-tests/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore --project demo-air-quality-monitor 'node --test tools/firebase-tests/rules.test.mjs'
```

Для Firebase Emulator нужна Java 21+; можно использовать JBR Android Studio через JAVA_HOME. Node используется **только инструментами и тестами правил**, Android UI написан на Dart/Flutter. Demo project не обращается к настоящему облачному Firebase.

Текущие подтверждённые результаты: analyze без замечаний; 28 unit/widget-тестов; Flutter LCOV 63,00% (1362/2162 строк), 42 библиотеки. `main.dart`/bootstrap и декларативный interface places_repository не вошли в этот отчёт; сгенерированные JSON-модели входят. Моки и синтетические fixtures используются только в тестах. Firestore Rules: 6/6; Python logic: 3/3. Тест onboarding/navigation/theme прошёл на Android 17 API 37. Расширенный live Android-тест также прошёл: настоящий API, SQLite, fallback кеша, заметки, MethodChannel и вызов/история уведомления. Дополнительно проверены GPS permission/координаты, настоящая camera capture/save, отображение локального предупреждения в шторке и cold start с кешем без сети на эмуляторе. Физический смартфон и реальный FCM ещё не проверены.

GitHub Actions запускает зависимости, форматирование, analyze, test/coverage >40%, Android debug build, Python logic и Firestore Rules. Workflow подготовлен локально; удалённого GitHub repository/CI run ещё нет.

## Релиз и ограничения

Release APK/AAB требует настоящего keystore и `android/key.properties`; образец — `android/key.properties.example`. Debug-подпись для release больше не подставляется. Crashlytics-код и Gradle plugin подготовлены, сбор диагностик включается в release при настоящем Firebase; отчёт в Console не проверен. Публикация в Google Play не выполнялась.

Остаются внешняя конфигурация/приёмка Firebase и Google Maps, камера/GPS на физическом устройстве, проверка фонового push, английская локализация, сравнение исторических периодов, экспорт визуальной карточки (пока share текста отчёта), полный DevTools-профиль, публичная privacy policy и release signing. Автоматическая ежедневная push-сводка не реализована; на главной есть рекомендации и лучший час по текущим данным/прогнозу. Фото не определяют качество воздуха. iOS не настраивается до завершения Android.

## Реальные Android-скриншоты

[Onboarding](docs/screenshots/android-onboarding.png), [главная](docs/screenshots/android-home.png), [города](docs/screenshots/android-cities.png), [заметка с камерой](docs/screenshots/android-notes.png), [локальное уведомление](docs/screenshots/android-notification.png), [офлайн после перезапуска](docs/screenshots/android-offline.png). Скриншоты сняты с Android Emulator, не являются HTML-макетами.
