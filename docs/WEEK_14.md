# Неделя 14. Release и подготовка публикации

Обновлено 16.11.2026.

## Реализация

Сохранён существующий ключ подписи. Версия исходников 1.1.0+2. Подготовлены политика конфиденциальности, запрос удаления аккаунта, описание магазина и черновик Data Safety.

## Доказательства

[Описание магазина](store/LISTING.md), [Data Safety](store/DATA_SAFETY.md), [политика](PRIVACY_POLICY.md), [удаление аккаунта](ACCOUNT_DELETION.md). Публичный контакт: erkezhanabdraim@gmail.com. Текущий read-only аудит подтверждает billingEnabled=false.

## Что осталось

Подписанные APK/AAB 1.1.0+2 собраны с --obfuscate и --split-debug-info. Подпись APK совпадает с существующим ключом, подпись AAB проверена. [Проверка артефактов](rk2/evidence/release-verification.json). Release обновлён на отдельном резервно скопированном AVD через install -r. После полного перезапуска Android авторизованный профиль сохранён. Свежий Google-вход не повторялся: существующая сессия сохранена. Контролируемая non-fatal ошибка Crashlytics отправлена из отдельной QA-сборки; DataTransport HTTP 200, владелец подтвердил событие в Console. Dart symbols QA и финальной версии успешно загружены. Финальный обычный APK возвращён без uninstall. [Подтверждение](rk2/evidence/crashlytics.json). В logcat текущего процесса фатальных маркеров не обнаружено. После отдельного разрешения владельца финальный APK загружен в App Distribution, release notes добавлены и приглашение отправлено согласованному тестировщику. [Результат](rk2/evidence/distribution.json). Повторная read-only проверка вернула HTTP 200; billingEnabled=false. Принятие приглашения и установка тестировщиком ещё не подтверждены. Политика и инструкция удаления опубликованы в публичном GitHub: docs/PRIVACY_POLICY.md и docs/ACCOUNT_DELETION.md. App Store: для фактического iOS-релиза нужны отдельная сборка, подпись и аккаунт разработчика.

23.11 release дополнительно запущен без пересборки на лёгком API 30: подписи готовых артефактов повторно проверены, тестовая Firebase-сессия сохранена. App Distribution повторно проверен read-only; [актуальное состояние](rk2/evidence/distribution-status-20261123.json).

## Локальный выпуск 1.1.0 (3), 23.11.2026

Новые APK и AAB собраны с `--obfuscate --split-debug-info`. Подписи **обоих** сверены с существующим ключом, а не только признаны валидными: [проверка](final_audit/evidence/release-verification.json). Три файла символов сохранены локально; `.debug_info` в arm64 `libapp.so` финального APK отсутствует. Firebase SHA-1/SHA-256 зарегистрированы, Google provider включён, billing выключен — [read-only проверка](final_audit/evidence/firebase-readonly.json).

В App Distribution остаётся прежний build 2; build 3 не отправлялся. Новые APK/AAB не публикуются без разрешения. QA и normal Dart symbols build 3 загружены в существующий закрытый Crashlytics для расшифровки. Предыдущее non-fatal событие в Console подтверждено владельцем; подтверждение SDK и Console различаются.

Финальная non-fatal проверка build 3: SDK enqueued + HTTP 200; владелец подтвердил новое событие в Console. Обычный APK восстановлен через -r; хеш фактически установленного APK совпал с финальным артефактом. [Crashlytics](final_audit/evidence/crashlytics.json), [сохранность данных](final_audit/evidence/release-data-preservation.json).

Финальный подписанный release отдельно прошёл настоящие foreground/background/terminated FCM-сценарии; переходы и сохранение сообщений проверены. [Результаты](RK2_REPORT.md).
