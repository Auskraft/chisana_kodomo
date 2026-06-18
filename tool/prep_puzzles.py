#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Подготовить фото-картинки для игры «Пазлы» в `assets/puzzles/`.

Берёт любые изображения из --src (скачанные с Unsplash и т.п.), делает
КВАДРАТНЫЙ центр-кроп (движок режет квадрат), ужимает до --size (по умолч. 800)
и сохраняет как JPG (фото так весит в разы меньше). Имена → безопасные слаги.

Оригиналы держи отдельно — скрипт только кладёт копии в assets/.

Пример:
    python tool/prep_puzzles.py --src "C:/Downloads/unsplash"
    python tool/prep_puzzles.py --src "..." --size 700 --quality 80   # легче
"""
import argparse
import os
import re

from PIL import Image

EXTS = ('.png', '.jpg', '.jpeg', '.webp', '.bmp')


def slug(name: str) -> str:
    s = re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')
    return s or 'pic'


def main() -> None:
    ap = argparse.ArgumentParser(description='Фото -> квадратные пазлы assets/puzzles/.')
    ap.add_argument('--src', required=True, help='папка с исходными картинками')
    ap.add_argument('--dst', default='assets/puzzles', help='куда класть')
    ap.add_argument('--size', type=int, default=800, help='сторона квадрата, px')
    ap.add_argument('--quality', type=int, default=82, help='качество JPG (1–95)')
    a = ap.parse_args()

    os.makedirs(a.dst, exist_ok=True)
    used: set[str] = set()
    n = 0
    total = 0
    for fn in sorted(os.listdir(a.src)):
        if os.path.splitext(fn)[1].lower() not in EXTS:
            continue
        im = Image.open(os.path.join(a.src, fn)).convert('RGB')
        w, h = im.size
        side = min(w, h)
        left = (w - side) // 2
        top = (h - side) // 2
        im = im.crop((left, top, left + side, top + side))
        if a.size and side != a.size:
            im = im.resize((a.size, a.size), Image.LANCZOS)
        base = slug(os.path.splitext(fn)[0])
        out = base
        i = 2
        while out in used:
            out = f'{base}_{i}'
            i += 1
        used.add(out)
        path = os.path.join(a.dst, out + '.jpg')
        im.save(path, format='JPEG', quality=a.quality, optimize=True)
        kb = os.path.getsize(path) // 1024
        total += kb
        n += 1
        print(f'  {fn}  ->  {out}.jpg  ({kb} KB)')
    print(f'==== ГОТОВО: {n} картинок, ~{total / 1024:.1f} МБ в {a.dst}/ ====')


if __name__ == '__main__':
    main()
