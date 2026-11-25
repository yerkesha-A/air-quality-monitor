# Готовность к Google Play

Проверено **25.11.2026**. Приложение не отправлено на проверку и не объявляется полностью готовым к публикации. Платные аккаунты/billing не подключаются.

| Пункт | Проверка / состояние |
|---|---|
| Application ID | `com.example.air_quality_monitor` сохранён. Предложен `kz.erkezhan.airqualitymonitor`; требуется согласование и [план миграции](APPLICATION_ID_PLAN.md) |
| Target / compile SDK | В реально собранном APK **36 / 36**, min SDK 24. Проверена действующая политика Google Play: для новых обычных Android приложений/обновлений требуется API 36+ с 31.08.2026 |
| Версия | 1.1.0 (3), последний App Distribution — build 2. Перед внешней доставкой сверить доступный versionCode в Console; не менять подпись |
| APK/AAB | Подписаны существующим ключом; obfuscate и три ABI symbols сохранены локально; итоговые хеши в протоколе сборки |
| 16-КБ страницы | `zipalign -c -P 16 4` прошёл; PT_LOAD alignment всех 64-bit ELF >=16 КБ. Это статическая проверка, не запуск на 16-КБ устройстве |
| Иконка / splash | Существующие adaptive icon foreground/background и Android 12+ windowSplashScreen; сохраняется утверждённый знак и цвета |
| Feature graphic | [1024×500 RGB PNG](assets/feature-graphic-1024x500.png), создан из существующего брендинга. Не является скриншотом и не содержит выдуманных функций |
| Скриншоты | Настоящие Android-снимки; экспорт для Play сохраняет весь кадр внутри 1080×1920 с полями, без подмены содержимого. Источник/дата перечислены рядом |
| Разрешения | Location и notifications по действию пользователя; нет background GPS, широкого доступа к файлам или рекламного SDK. Камера использует системный picker/intent |
| Crashlytics | Работает Android release; событие build 3 подтверждено в Console 23.11. Новые символы текущего бинарника сохранены отдельно; перед доставкой загрузить подходящие symbols, не выдавая старые за новые |
| Удаление аккаунта | В приложении есть рабочая и понятная **инициация запроса через поддержку**, копирование email и обработка отсутствия mail app; автоматическое удаление не реализовано. Есть регламент удаления Auth + подколлекций Firestore. Реальную обработку запроса/публичный web-путь нужно принять перед публикацией |
| Data Safety / политика | Описаны реальные SDK/данные; не утверждается отсутствие сбора. Форму сверить по версиям SDK и фактической обработке данных; политика должна быть публичной, доступной без входа, не PDF |
| App Distribution | read-only API подтверждает build 2 и запись тестировщика. Новая доставка и установка на физический Android не подтверждены |
| Google Sign-In | Provider и release SHA зарегистрированы; требуется свежий интерактивный вход на совместимом Google Play стенде |
| Проверка developer account | Для нового personal account требуется подтверждение доступа к реальному Android через Play Console mobile app. iPhone и эмулятор это не заменяют; регистрацию/оплату агент не выполнял |
| Google Play testing | Internal testing ещё не выполнялся; closed testing/production access зависит от аккаунта разработчика и требований Console |

## Порядок отправки после разрешения

1. Согласовать ID и пройти отдельный план миграции; подтвердить keystore и версии Firebase/OAuth. Либо явно принять текущий ID как постоянный — это решение владельца.
2. Открыть собственный Play Console аккаунт. Регистрацию/оплату самостоятельно агент не выполняет.
3. Создать карточку приложения, указать язык/контакты, загрузить иконку, feature graphic, настоящие screenshots и тексты из [LISTING.md](LISTING.md).
4. Заполнить App content: privacy policy URL, account deletion web URL, Data Safety, ads (отсутствуют), content rating, target audience и доступ для reviewer. Мониторинг доступен гостю; для проверки аккаунта нужен отдельный безопасный reviewer login. Не публиковать его в репозитории.
5. В Release → Testing → Internal testing загрузить **AAB согласованного package** и release notes. Проверить Play App Signing/upload certificate и все предупреждения; ничего не нажимать для production без отдельного разрешения.
6. Добавить согласованных тестировщиков, получить opt-in link и провести реальную установку из Play. App Distribution не заменяет internal testing. Для новых personal accounts проверить отдельные условия closed testing/доступа к production в своей Console; internal track не гарантирует production access. По проверенной политике для personal accounts, созданных после 13.11.2023, перед production access требуется closed test минимум с 12 тестировщиками, непрерывно opted-in не менее 14 дней; затем отдельная заявка на доступ.
7. Проверить pre-launch report, Google login с сертификатом Play App Signing (он может отличаться от upload key), FCM, разрешения, offline/data persistence, физическую камеру/GPS и 16-КБ совместимость.
8. Перед production актуализировать политику, обработку удаления и SDK disclosures; получить отдельное разрешение владельца.

## Проверенные источники

- [Target API policy](https://support.google.com/googleplay/android-developer/answer/11926878)
- [16 KB compatibility](https://developer.android.com/guide/practices/page-sizes)
- [Store assets](https://support.google.com/googleplay/android-developer/answer/9866151)
- [Account deletion](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Real device verification](https://support.google.com/googleplay/android-developer/answer/14316361)
- [Personal account testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465)
- [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)

Актуальные ответы Console и решение review не подменяются локальным отчётом. Новая версия и текущие документы не опубликованы автоматически.
