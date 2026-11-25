"""Rasterize the approved Android vector paths for native app icons."""
from pathlib import Path
from PIL import Image, ImageDraw


def render_icon(size=512):
    paths = [
     [('M',29,42),('L',61,42),('C',72,42,72,28,63,28),('C',58,28,55,31,55,34)],
     [('M',29,54),('L',74,54),('C',85,54,85,70,75,70),('C',70,70,67,67,67,64)],
     [('M',29,67),('L',49,67),('C',60,67,60,83,50,83),('C',45,83,42,80,42,77)],
    ]
    scale = 2048 / 108
    image = Image.new('RGB', (2048,2048), '#285964')
    draw = ImageDraw.Draw(image)
    for path in paths:
     points=[]
     for op,*v in path:
      if op in ('M','L'):
       pos=tuple(v);points.append(pos)
      else:
       start=pos
       for i in range(1,81):
        t=i/80;u=1-t
        points.append(tuple(u**3*start[j]+3*u*u*t*v[j]+3*u*t*t*v[j+2]+t**3*v[j+4] for j in (0,1)))
       pos=tuple(v[-2:])
     pts=[(round(x*scale),round(y*scale)) for x,y in points]
     w=round(5*scale);draw.line(pts, fill='#D5EAF0',width=w,joint='curve')
     for x,y in [pts[0],pts[-1]]:draw.ellipse((x-w/2,y-w/2,x+w/2,y+w/2),fill='#D5EAF0')
    return image.resize((size, size), Image.Resampling.LANCZOS)


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    out = root / 'docs/store/assets'
    out.mkdir(parents=True, exist_ok=True)
    render_icon().save(out / 'icon-512.png')
    (out/'README.md').write_text('# Иконка магазина\n\nicon-512.png — экспорт существующего Android vector drawable в 512×512 RGB PNG. Цвета и геометрия сохранены; это не скриншот приложения. Исходник: android/app/src/main/res/drawable/ic_launcher_foreground.xml. Скругление выполняет магазин.\n')
    print('Rendered existing Android vector to 512×512 store icon')
