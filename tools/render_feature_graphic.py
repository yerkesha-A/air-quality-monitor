"""Render store artwork from the existing brand; no fabricated app screenshots."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from render_store_icon import render_icon


def main():
    root = Path(__file__).resolve().parents[1]
    image = Image.new('RGB', (1024, 500))
    draw = ImageDraw.Draw(image)
    for y in range(500):
        t = y / 499
        color = tuple(round(a + (b - a) * t) for a, b in zip((237, 248, 252), (209, 233, 240)))
        draw.line((0, y, 1023, y), fill=color)
    def font(size):
        face = ImageFont.truetype(str(root / 'assets/fonts/Manrope.ttf'), size)
        face.set_variation_by_axes([500])
        return face
    ink = '#20343c'
    draw.text((64, 72), 'AIR QUALITY', font=font(54), fill=ink)
    draw.text((64, 138), 'MONITOR', font=font(54), fill=ink)
    draw.text((68, 236), 'Воздух вашего города', font=font(31), fill=ink)
    draw.text((68, 295), 'US AQI  ·  Прогноз  ·  Карта', font=font(23), fill='#355c67')
    draw.text((68, 402), 'Open-Meteo / CAMS  ·  OpenStreetMap', font=font(18), fill='#355c67')
    mark = render_icon(236)
    mask = Image.new('L', mark.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 235, 235), radius=52, fill=255)
    image.paste(mark, (714, 132), mask)
    out = root / 'docs/store/assets/feature-graphic-1024x500.png'
    image.save(out)
    print('Feature graphic: 1024×500 RGB, existing brand and factual features')


if __name__ == '__main__':
    main()
