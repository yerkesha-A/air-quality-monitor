# Показ РК2 на MacBook с 8 ГБ RAM

Физический Android не требуется для подготовки и демонстрации текущего комплекта. iPhone не заменяет Android-тестирование.

## Что открыть перед защитой

1. PDF `docs/rk2/RK2_PRESENTATION.pdf` и сценарий `docs/rk2/DEFENSE.md`.
2. Отчёт `docs/RK2_REPORT.md` и реальные скриншоты `docs/rk2/screenshots`.
3. Только отдельный облегчённый AVD; основной AVD и API 37 оставить закрытыми.
4. Готовый подписанный APK `submission/FINAL_RK1_RK2_2026-11-23/android/air-quality-monitor-1.1.0-3.apk`. AAB подготовлен для выпуска, а не для прямой установки.

Не запускать сборку во время демонстрации. Не очищать данные и не выходить из существующего аккаунта ради показа. Гостевой режим подходит для главной, поиска, карты и тем; Firebase показывается только при наличии реальной сохранённой сессии.

## Сценарий на 9–10 минут

- Объяснить цель и модельные данные Open-Meteo/CAMS.
- Показать главную и время получения данных; выбрать город.
- Открыть карту: маркер, AQI/PM, карточка, источник и атрибуция.
- Показать историю и тему; не обещать накопленную историю на новом AVD.
- Показать архитектуру и результаты тестов, реальные Performance/Memory.
- Показать новый успешный GitHub Actions 45228891410 для 79bca13, App Distribution build 2 и подтверждение нового non-fatal build 3 в Crashlytics.
- Отдельно назвать непроверенные на телефоне функции и необходимость согласовать замену Google Maps.

При отсутствии сети использовать уже сохранённые данные с исходным временем и настоящие скриншоты. Не представлять скриншоты как текущий онлайн-запрос.

## Файлы для преподавателя

Ссылка на GitHub, APK, PDF-презентация и отчёт. Полный локальный комплект находится в `submission/FINAL_RK1_RK2_2026-11-23`, включая исходники и контрольные суммы. Приватные ключи, пароли, Firebase CLI-токены и данные AVD не входят в комплект.

## Запуск уже подготовленного лёгкого AVD на этом Mac

Из корня проекта, если другие эмуляторы закрыты:

```sh
ANDROID_AVD_HOME="$PWD/.local-backups/rk2-light-20261116/avds" \
  "$HOME/Library/Android/sdk/emulator/emulator" \
  -avd AQM_Light_API30 -port 5566 -memory 2048 -cores 2 \
  -gpu host -feature -Vulkan -no-snapshot -no-boot-anim -no-audio -no-metrics -no-skin
```

Если этот AVD уже открыт, второй раз команду не запускать. В другом терминале после загрузки:

```sh
"$HOME/Library/Android/sdk/platform-tools/adb" -s emulator-5566 shell input keyevent KEYCODE_WAKEUP
"$HOME/Library/Android/sdk/platform-tools/adb" -s emulator-5566 shell wm dismiss-keyguard
"$HOME/Library/Android/sdk/platform-tools/adb" -s emulator-5566 shell am start -n com.example.air_quality_monitor/.MainActivity
```

Это локальная готовая конфигурация этого Mac; папка AVD не входит в Git. Экран 720×1600 / density 320 и release APK уже настроены. Закрывать эмулятор штатно, сохраняя диск. Не использовать wipe data или uninstall. Материалы актуализированы 23.11.2026.
