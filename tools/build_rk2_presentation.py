"""Create the RK2 slides from checked-in evidence; no generated UI images."""
from pathlib import Path
import json
from pptx import Presentation
from pptx.util import Inches, Pt
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/rk2'
PROFILE_EVIDENCE = ROOT / 'docs/final_audit/evidence'
SUMMARY = json.loads((PROFILE_EVIDENCE / 'map-profile-summary.json').read_text())
VALIDATION = json.loads((ROOT / 'docs/audit_20261126/results.json').read_text())
TEST_COUNT = VALIDATION['unitWidgetTests']
COVERAGE = f"{VALIDATION['coveragePercent']:.2f}".replace('.', ',')
slides = [
('Air Quality Monitor', 'Качество воздуха в понятном формате\nFlutter / Dart · Android и iOS\nРК2: недели 8–15', 'Представлю приложение, его архитектуру и проверенные возможности. Отдельно обозначу ограничения. Время: 30 секунд.'),
('Задача и аудитория', 'Для жителей городов и любителей прогулок\nUS AQI, загрязнители и прогноз\nМодельные данные Open-Meteo / CAMS', 'Цель — помочь понять качество воздуха перед прогулкой. Данные модельные, приложение не является датчиком. Время: 35 секунд.'),
('Архитектура', 'presentation → domain → data\nProvider: общие настройки и зависимости\nBLoC: загрузка воздуха, поиск и история\nRepository + Dependency Injection', 'Покажу, как экран получает состояние, а репозиторий выбирает API или локальный источник. Время: 45 секунд.'),
('Карта без платных услуг', 'flutter_map + OpenStreetMap\nРеальные AQI, PM₂.₅, PM₁₀ и время данных\nГруппы AQI, легенда и раскрываемая карточка\nГеолокация, атрибуция и кэш тайлов', 'Карта работает без Google Cloud billing. Если требуется именно Google Maps, замена нуждается в согласовании преподавателя. Время: 45 секунд.'),
('Offline-first', 'SharedPreferences: настройки\nSQLite: кэш, история, избранное, заметки\nСначала сохранённые данные, затем обновление\nПри ошибке сохраняется исходное время', 'Покажу, почему устаревшие данные нельзя выдавать за свежие. Время: 40 секунд.'),
('Нативные возможности', 'Камера и галерея, локальные фото\nKotlin и Swift MethodChannel\nНастоящий iOS Simulator integration\niPhone release: GPS, камера, фото\nGoogle-сессия после запуска без Mac', 'Android камера, галерея и channel проверены на эмуляторе. На физическом iPhone владелец подтвердил GPS, камеру, выбор фото из галереи и сохранение после перезапуска release без Mac. Физического Android нет. Время: 40 секунд.'),
('Измерение производительности', f"Карта: парный profile-прогон, 23.11.2026\nBuild p95: {SUMMARY['before']['buildP95Ms']} → {SUMMARY['after']['buildP95Ms']} мс\nRaster p95: {SUMMARY['before']['rasterP95Ms']} → {SUMMARY['after']['rasterP95Ms']} мс\nHeap после GC: {SUMMARY['before']['heapAfterGcMiB']} → {SUMMARY['after']['heapAfterGcMiB']} MiB", 'Это один парный прогон карты на API 30 с 2 ГБ RAM. Новая карта больше на 59 процентов; raster p95 вырос, доля медленных кадров снизилась. Нельзя утверждать общее ускорение. Я не утверждаю, что все кадры укладываются в 16,67 мс или что доказано отсутствие утечек. Время: 50 секунд.'),
('DevTools: реальные измерения', '', 'Покажу настоящие снимки Performance до и после от 23 ноября. Сырые FrameTiming и память сохранены вместе с описанием стенда и ограничениями. Покажу исходные цифры без обещания стабильных 60 FPS. Время: 20 секунд.'),
('Тестирование', f'Unit + widget + integration\nПройдено тестов: {TEST_COUNT}\nПокрытие строк: {COVERAGE}%\nAnalyze без замечаний; тесты прошли', 'Тестирую API, состояние, навигацию, SQLite, карту и ошибки. Интеграционные тесты используют отдельный AVD и сохраняют установку. Время: 40 секунд.'),
('Firebase и безопасность', 'Authentication, Firestore, FCM, Crashlytics\nAndroid FCM: три состояния приложения\nУдаление аккаунта: подтверждение и reauth\nRules блокируют запись старых сеансов\nКлючи и личные данные вне Git', 'Email, Firestore и Android FCM проверены; non-fatal build 3 подтверждён в Console 23 ноября. Свежий Google-вход iPhone и сохранение сессии release подтверждены 26 ноября. Удаление аккаунта реализовано в приложении; порядок и ошибки покрыты тестами. Рабочий аккаунт для проверки не удаляется. APNs iOS пока не настроен. Время: 45 секунд.'),
('CI и выпуск', 'GitHub Actions: analyze → tests → APK\nCI 552bb11: success, новый код локально\nAndroid APK/AAB 1.1.0 (3) сохранены\niPhone Release AOT 1.1.1 (4) установлен\nApp Distribution: предыдущий build 2', 'Последний опубликованный CI 45630653658 успешен. Текущая рабочая копия ещё не отправлена и не имеет нового remote run. Android по просьбе владельца не пересобирался. iPhone release работает без debugger, бесплатная подпись до 3 декабря 2026. Магазины и платные услуги не подключены. Время: 35 секунд.'),
('Демонстрация приложения', 'Главная → выбор города → карта\nКарточка данных и время обновления\nИстория → профиль → тема\nПоказать доказательства DevTools', 'Во время демонстрации не очищаю данные и не меняю существующий аккаунт. На случай отсутствия сети есть реальные скриншоты. Время: 60 секунд.'),
('Оставшиеся шаги', 'Согласовать OSM вместо Google Maps\nФизический Android: проверка отложена\niOS Apple Sign-In / APNs не настроены\nНовый push и delivery требуют разрешения\nМагазины пока не опубликованы', 'Android проверен на эмуляторе; физический iPhone release действительно работает. Он не заменяет обязательную Android-приёмку. Обновление бесплатной iPhone-подписи потребуется после 3 декабря. Непроверенные permissions и live iOS Crashlytics учитываются отдельно. Время: 35 секунд.'),
]
OUT.mkdir(parents=True, exist_ok=True)
r = Presentation(); r.core_properties.author = 'Air Quality Monitor'; r.core_properties.last_modified_by = 'Air Quality Monitor'; r.core_properties.title = 'Air Quality Monitor — РК2'; r.slide_width = Inches(13.333); r.slide_height = Inches(7.5)
font_path = '/System/Library/Fonts/Supplemental/Arial.ttf'
pdfmetrics.registerFont(TTFont('ArialRK2', font_path))
c = canvas.Canvas(str(OUT / 'RK2_PRESENTATION.pdf'), pagesize=(960, 540))
for title, body, notes in slides:
 s = r.slides.add_slide(r.slide_layouts[6])
 bg = s.background.fill; bg.solid(); bg.fore_color.rgb = __import__('pptx').dml.color.RGBColor.from_string('EFF5F4')
 for text, top, size in [(title,.55,30),(body,1.65,24)]:
  tf = s.shapes.add_textbox(Inches(.65), Inches(top), Inches(12), Inches(5)).text_frame
  tf.word_wrap = True
  for i, line in enumerate(text.splitlines()):
   p = tf.paragraphs[0] if i == 0 else tf.add_paragraph(); p.text = line; p.font.size = Pt(size)
 if title == 'Карта без платных услуг':
  s.shapes.add_picture(str(ROOT / 'docs/audit_20261125/android-map.png'), Inches(9.1), Inches(1.65), height=Inches(5.2))
 if title == 'DevTools: реальные измерения':
  for image, left in [('map-before-performance.png',.6),('map-after-performance.png',6.9)]:
   s.shapes.add_picture(str(PROFILE_EVIDENCE / image), Inches(left), Inches(1.7), width=Inches(5.7))
 s.notes_slide.notes_text_frame.text = notes
 c.setFillColorRGB(.94,.96,.96); c.rect(0,0,960,540,fill=1,stroke=0); c.setFillColorRGB(.12,.24,.26)
 c.setFont('ArialRK2',25); c.drawString(42,478,title)
 c.setFont('ArialRK2',19)
 for i,line in enumerate(body.splitlines()): c.drawString(42,397-i*43,line)
 if title == 'Карта без платных услуг':
  c.drawImage(str(ROOT / 'docs/audit_20261125/android-map.png'), 730, 60, width=195, height=433, preserveAspectRatio=True, mask='auto')
 if title == 'DevTools: реальные измерения':
  for image, left in [('map-before-performance.png',35),('map-after-performance.png',495)]:
   c.drawImage(str(PROFILE_EVIDENCE / image),left,110,width=430,height=300,preserveAspectRatio=True,mask='auto')
 c.setFont('ArialRK2',11); c.drawString(42,28,'Air Quality Monitor · РК2 · 26.11.2026'); c.showPage()
r.save(OUT / 'RK2_PRESENTATION.pptx'); c.save()
(OUT / 'DEFENSE.md').write_text('# Сценарий защиты на 8–10 минут\n\n' + '\n\n'.join(f'## {i+1}. {t}\n\n{n}' for i,(t,b,n) in enumerate(slides)) + '\n\n## Вопросы\n\n- Почему Provider и BLoC вместе? Provider передаёт зависимости и простое общее состояние; BLoC описывает асинхронные события.\n- Данные датчика? Нет, модельные оценки CAMS через Open-Meteo.\n- Почему OpenStreetMap? Не требует подключения Google Cloud billing; замену нужно согласовать.\n- Можно ли гарантировать 60 FPS? Нет, замер на эмуляторе этого не подтверждает.\n- Проверен ли физический телефон? iPhone release проверен владельцем; физического Android нет.\n- Почему iPhone раньше не открывался с главного экрана? Это ограничение Flutter debug/JIT; установленный AOT release запускается без Mac. Бесплатный provisioning до 03.12.2026.\n- Где опубликована сборка? В App Distribution прежний build 2. Android APK/AAB build 3 сохранены; новый iPhone release build 4 установлен локально. Новый push и delivery требуют разрешения.\n')
with (OUT / 'DEFENSE.md').open('a') as f:
 f.write('\nПолный набор: [13 вопросов к защите](QUESTIONS.md).\n')
print('Created PPTX, PDF and speaker scenario from actual current evidence')
