# Google Cloud для недели 9

Проверено read-only 29 октября 2026: существующий проект `air-quality-monitor-erkezhan`, package `com.example.air_quality_monitor`; billing выключен, `maps-android-backend.googleapis.com` DISABLED. SHA-1 и SHA-256 существующего upload-сертификата зарегистрированы. Проект и release-ключ не пересоздавались.

## Ручные действия владельца

1. Открыть [Billing проекта](https://console.cloud.google.com/billing/linkedaccount?project=air-quality-monitor-erkezhan). Привязка платёжного аккаунта выполняется только владельцем после согласия с возможными расходами. Self-service Cloud Billing требует действующего способа оплаты — обычно карты; не присылайте её данные в чат. [Правила способов оплаты](https://docs.cloud.google.com/billing/docs/how-to/payment-methods).
2. Включить только [Maps SDK for Android](https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com?project=air-quality-monitor-erkezhan).
3. В [Credentials](https://console.cloud.google.com/apis/credentials?project=air-quality-monitor-erkezhan) создать/использовать ключ с Android application restriction `com.example.air_quality_monitor` и SHA-1 нужного сертификата. API restriction — **только Maps SDK for Android**. Debug и upload требуют соответствующих fingerprints; Play App Signing при будущей публикации использует свой сертификат.
4. В Billing → Budgets создать бюджет в удобной владельцу сумме и email-уведомления 50/90/100%. Проверить получателей. Обычный бюджет уведомлений **не является автоматическим лимитом расходов**. При необходимости ограничить квоты там, где конкретный API поддерживает их. [Бюджеты](https://docs.cloud.google.com/billing/docs/how-to/budgets), [ограничения ключа](https://developers.google.com/maps/api-security-best-practices).
5. Записать ключ в игнорируемый `android/local.properties`: `maps.apiKey=...`. Сам ключ не отправлять в чат или Git. Затем сообщить, что настройка готова. Понадобятся пересборка тестового APK и реальная проверка tiles, маркеров, отказа геолокации и тем.

## Возможные расходы

[Google требует billing даже для SDK](https://developers.google.com/maps/documentation/android-sdk/usage-and-billing). На дату проверки обычный **Maps SDK без Map ID** имеет бесплатное безлимитное использование. В этом приложении Map ID не нужен и не задаётся. Платные SKU (например, карты с Map ID, Street View, Places) и другие сервисы Cloud/Firebase могут создавать расходы. Тарифы и условия проверяются перед подключением: [официальная таблица](https://developers.google.com/maps/billing-and-pricing/pricing), [разделение SKU](https://developers.google.com/maps/billing-and-pricing/sku-details#maps-sdk).

Не обещается нулевой счёт всего Cloud-проекта. Связывание billing также меняет платёжный контекст Firebase; не следует включать лишние API или серверные задачи ради проверки карты. Самостоятельного подключения billing, создания неограниченных ключей или смены провайдера карты не выполняется.

До фактического открытия Google Maps на Android неделя 9 остаётся частично выполненной.
