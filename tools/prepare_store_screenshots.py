"""Frame actual, dated app captures without cropping or fabricating UI."""
from pathlib import Path
import json
from PIL import Image


def main():
    root = Path(__file__).resolve().parents[1]
    out = root / 'docs/store/assets/screenshots'
    out.mkdir(parents=True, exist_ok=True)
    sources = ['docs/audit_20261125/android-home.png',
               'docs/audit_20261125/android-map.png',
               'docs/rk2/screenshots/07-map-expanded-20261123.png',
               'docs/rk2/screenshots/11-history-final-20261123.png',
               'docs/rk2/screenshots/10-map-dark-final-20261123.png',
               'docs/rk1/screenshots/03-city-picker.png']
    manifest = []
    for i, source in enumerate(sources, 1):
        image = Image.open(root / source).convert('RGB')
        scale = min(1080 / image.width, 1920 / image.height)
        image = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
        frame = Image.new('RGB', (1080, 1920), '#edf6fa')
        frame.paste(image, ((1080 - image.width) // 2, (1920 - image.height) // 2))
        filename = f'{i:02}.png'
        frame.save(out / filename)
        manifest.append({'file': filename, 'source': source, 'canvas': [1080, 1920],
                         'content': 'full actual capture, proportional resize and margins; source date retained'})
    (out / 'sources.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (out / 'README.md').write_text('# Скриншоты Google Play\n\nНастоящие ранее снятые Android-экраны, экспортированы 25.11.2026 в 1080×1920 RGB. Добавлены только поля, весь экран сохранён. Дата исходной съёмки не меняется: пути в sources.json. Это не новые iOS-снимки и не доказательство нового запуска. Профиль с личными данными не включён.\n')
    print('Prepared six actual app screenshots at 1080×1920; provenance saved')


if __name__ == '__main__':
    main()
