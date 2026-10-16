# Google Maps: подготовка и оставшаяся настройка

16 октября 2026. Карта — обязательный пункт полного проекта. Для РК1 по неделям 1–7 её подключение не откладывает сдачу.

## Что уже подготовлено

- `google_maps_flutter`, настоящий Android Maps SDK и AndroidManifest placeholder `com.google.android.geo.API_KEY`.
- Gradle читает `maps.apiKey` из приватного `android/local.properties` или `GOOGLE_MAPS_API_KEY` из окружения.
- `MainActivity` сообщает `mapsConfigured`; без ключа экран честно предлагает поиск городов и показывает отсутствие карты.
- `MapScreen`: центр/выбор точки, GPS, маркеры, фильтры US AQI/PM₂.₅/PM₁₀ и тёмный стиль.
- `MapAirController`: debounce 800 мс, максимум 5 модельных точек за обновление, сетка около 5 км, ограниченный кеш 40 точек, защита от устаревших ответов, последовательные запросы и backoff.
- `test/map_air_test.dart`: кеш/границы/ошибки/debounce/конкурирующие запросы. Координаты используют реальные запросы Open-Meteo в production; нет имитации уличных датчиков.
- Геолокация и reverse geocoding используются также на главной и не зависят от отображения Google tiles.

## Что требуется от владельца Google Cloud

[Google требует billing](https://developers.google.com/maps/documentation/android-sdk/usage-and-billing) для Maps SDK for Android. Последняя проверка текущего проекта: billing отключён, Maps API не включён, ключ отсутствует. Платные услуги самостоятельно не включались.

После отдельного решения владельца потребуется:

1. Настроить billing для существующего Google Cloud/Firebase-проекта и согласовать допустимые расходы/ограничения.
2. Включить Maps SDK for Android.
3. Создать API key с API restriction только Maps SDK for Android и Android application restriction: package `com.example.air_quality_monitor` + соответствующий SHA-1 debug/upload сертификата. Для приложения из Google Play потребуется сертификат Play App Signing, а не только upload.
4. Записать ключ локально в `android/local.properties`: `maps.apiKey=...`. Не добавлять этот файл/ключ в Git. Пересобрать приложение.
5. На отдельном AVD/телефоне принять tiles, жесты, GPS permission/denied, смену точки, фильтры, offline/error, обе темы и корректность ограничений ключа.

До этой приёмки карта **не считается готовой**, даже если Dart-код и unit-тесты проходят. Сегодня код подготовлен настолько, насколько его можно проверить без ключа и billing; гарантия завершения в тот же день невозможна без настройки Cloud и native-проверки.
