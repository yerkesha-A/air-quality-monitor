# Публикация GitHub — 16.10.2026

Репозиторий: [yerkesha-A/air-quality-monitor](https://github.com/yerkesha-A/air-quality-monitor), **Public**, основная ветка `main`. Создан и опубликован после явного разрешения владельца. История разработки сохранена; force push не использовался.

Без GitHub-токена проверены публичные API/contents endpoints: репозиторий, README, RK1_REPORT, SUBMISSION, DEFENSE_5_MIN, SCREENSHOTS, VALIDATION, wireframes.svg, отдельные Dart-задания, state_examples.dart, снимок главной, workflow CI. Все ответили успешно; `private=false`.

- [README](https://github.com/yerkesha-A/air-quality-monitor#readme)
- [Отчёт РК1](https://github.com/yerkesha-A/air-quality-monitor/blob/main/RK1_REPORT.md)
- [Материалы защиты](https://github.com/yerkesha-A/air-quality-monitor/tree/main/docs/rk1)
- [Dart-задания](https://github.com/yerkesha-A/air-quality-monitor/tree/main/coursework/week01)
- [GitHub Actions](https://github.com/yerkesha-A/air-quality-monitor/actions)

Перед push проверены файлы и история Git: scanner не нашёл секретов; отдельно подтверждено отсутствие tracked keystore/паролей/native config/SQLite/AVD backups/submission. Авторизация использована из macOS Keychain; токен не записывался в исходники, URL remote или аргументы процесса.

APK/AAB и PDF-комплект находятся локально в `submission/RK1_2026-10-16/`; они не добавлялись в Git и не публиковались как GitHub Release. GitHub Actions может создавать собственный debug artifact по существующему workflow. В репозитории есть все редактируемые материалы; преподавателю отдельно передаются подписанный APK и PDF.

Состояние CI доступно по ссылке Actions; локальные проверки документированы отдельно в VALIDATION. Публикация в Google Play не выполнялась.

## Подтверждённый успешный CI

[Android quality checks #38946181056](https://github.com/yerkesha-A/air-quality-monitor/actions/runs/38946181056) для `a1a1b78`: **completed / success**. Оба jobs — `android` и `firestore-rules` — успешны. На GitHub прошли format, analyze, Dart-задания, Flutter tests/coverage, Python, Android debug build, выгрузка APK/coverage и Firestore Rules. Это фактический удалённый результат, а не только наличие workflow. Новые статусы последующих публикаций доступны в Actions.
