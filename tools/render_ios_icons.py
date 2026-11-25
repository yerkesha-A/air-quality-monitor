"""Export the existing app mark at the sizes declared by the iOS asset catalog."""
import json
from PIL import Image, ImageDraw
from pathlib import Path
from render_store_icon import render_icon


def main():
    root = Path(__file__).resolve().parents[1]
    catalog = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    images = json.loads((catalog / 'Contents.json').read_text())['images']
    for entry in images:
        points = float(entry['size'].split('x')[0])
        scale = float(entry['scale'].removesuffix('x'))
        render_icon(round(points * scale)).save(catalog / entry['filename'])
    launch = root / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for scale in (1, 2, 3):
        size = 96 * scale
        mark = render_icon(size)
        mask = Image.new('L', mark.size)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=21 * scale, fill=255)
        framed = Image.new('RGBA', mark.size)
        framed.paste(mark, (0, 0), mask)
        framed.save(launch / ('LaunchImage' + ('' if scale == 1 else '@' + str(scale) + 'x') + '.png'))
    print(f'Exported {len(images)} iOS icons from the existing app mark')


if __name__ == '__main__':
    main()
