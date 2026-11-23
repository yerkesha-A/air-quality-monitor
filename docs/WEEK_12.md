# Неделя 12. CI/CD

Обновлено 16.11.2026.

## Реализация

GitHub Actions выполняет pub get, проверку форматирования, analyze, тесты с coverage, сборку debug APK и сохранение артефакта; отдельно проверяет Firestore Rules. Добавлен ручной запуск workflow_dispatch.

## Доказательства

Конфигурация: [.github/workflows/android.yml](../.github/workflows/android.yml). Изменения опубликованы с разрешения владельца. [Run 43856352446](https://github.com/yerkesha-A/air-quality-monitor/actions/runs/43856352446) для 24a6946 завершился success: Android и Firestore Rules.

## Что осталось

Новый запуск подтверждён; [машиночитаемый результат](rk2/evidence/github-actions.json). Следующие изменения отчётов могут запустить новый workflow; его статус нужно отличать от проверенного run.

## Состояние 23.11.2026 перед финальной защитой

Последний опубликованный [run 45177924926](https://github.com/yerkesha-A/air-quality-monitor/actions/runs/45177924926), коммит `86e2acd`, завершился **success**. Новые изменения карты и тестов сохранены локально. Workflow включает форматирование `test_driver`. Новый удалённый запуск не заявляется пройденным: push запрещён до нового разрешения владельца.
