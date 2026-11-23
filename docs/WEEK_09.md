# Неделя 9. Карта и геолокация

Обновлено 16.11.2026.

## Реализация

Реализована карта flutter_map / OpenStreetMap без Google Cloud billing. Есть реальные показатели Open-Meteo/CAMS, переключение AQI/PM₂.₅/PM₁₀, карточка времени данных, города, масштаб, GPS, обработка отказа и отключённой геолокации. Запросы ограничены, последовательны, с debounce и SQLite-кэшем. Атрибуция видна постоянно.

## Доказательства

Карта на Android проверена вручную; интеграционный тест реальных тайлов и GPS успешно прошёл 16.11.2026. Сохранены 6 тайлов; координаты заданы через emulator geo fix. [Результат Android](rk2/evidence/map-android-verification.json). [Скриншот](rk2/screenshots/02-map-light.png). [Политика тайлов](OSM_TILE_POLICY.md).

## Что осталось

Замена Google Maps на OpenStreetMap требует согласования преподавателя, если в задании указан именно Google Maps. Billing не подключён.

На подписанной release-сборке дополнительно проверены [тёмная карта](rk2/screenshots/03-map-dark-release.png), [сохранённые данные без сети](rk2/screenshots/04-map-offline-release.png) и [альбомная ориентация](rk2/screenshots/05-map-landscape-release.png). Сеть и светлая тема восстановлены после проверки.
