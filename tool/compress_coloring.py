#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ужималка контурных раскрасок под вес APK.

Проходит по `assets/coloring/**/*.png|jpg|jpeg` и пересохраняет каждую картинку
оптимизированно (на месте):
  • приводит к RGB на белом фоне (на случай прозрачности),
  • уменьшает до --max px по большей стороне (по умолчанию 1024 — с запасом для
    телефона: холст рисуется ~0.82 ширины экрана),
  • квантует палитру до --colors цветов (line-art сжимается в разы; заливка по
    белым областям от меньшего числа цветов только чище),
  • сохраняет PNG c optimize.

ОРИГИНАЛЫ держи отдельно (напр. исходную папку-мастер) — скрипт пишет ПОВЕРХ
файлов в assets/. Качество заливки проверь на устройстве; не понравится —
перекопируй мастера и прогони с другими --max/--colors.

Примеры:
  python tool/compress_coloring.py --dry          # только показать прогноз
  python tool/compress_coloring.py                # ужать (1024 px, 64 цвета)
  python tool/compress_coloring.py --max 900 --colors 32   # агрессивнее
"""
import argparse
import glob
import io
import os

from PIL import Image

EXTS = ('png', 'jpg', 'jpeg')


def optimized_bytes(path: str, max_side: int, colors: int) -> bytes:
    im = Image.open(path)
    # На белый фон, в RGB.
    if im.mode in ('RGBA', 'LA', 'P'):
        im = im.convert('RGBA')
        bg = Image.new('RGBA', im.size, (255, 255, 255, 255))
        bg.alpha_composite(im)
        im = bg.convert('RGB')
    else:
        im = im.convert('RGB')
    # Уменьшение по большей стороне.
    w, h = im.size
    if max_side and max(w, h) > max_side:
        s = max_side / max(w, h)
        im = im.resize((round(w * s), round(h * s)), Image.LANCZOS)
    # Квантование палитры (line-art -> PNG-8).
    if colors:
        im = im.quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    buf = io.BytesIO()
    im.save(buf, format='PNG', optimize=True)
    return buf.getvalue()


def main() -> None:
    ap = argparse.ArgumentParser(description='Ужать раскраски в assets/coloring.')
    ap.add_argument('--dir', default='assets/coloring', help='корень раскрасок')
    ap.add_argument('--max', type=int, default=1024, help='макс. сторона, px (0 — не менять)')
    ap.add_argument('--colors', type=int, default=64, help='цветов палитры (0 — RGB без квантования)')
    ap.add_argument('--dry', action='store_true', help='только прогноз, без записи')
    a = ap.parse_args()

    files = []
    for ext in EXTS:
        files += glob.glob(os.path.join(a.dir, '**', '*.' + ext), recursive=True)
        files += glob.glob(os.path.join(a.dir, '**', '*.' + ext.upper()), recursive=True)
    files = sorted(set(files))

    total_before = total_after = 0
    for f in files:
        before = os.path.getsize(f)
        data = optimized_bytes(f, a.max, a.colors)
        after = len(data)
        if not a.dry and after < before:
            with open(f, 'wb') as out:
                out.write(data)
        elif not a.dry:
            after = before  # не раздуваем: оставляем как было
        total_before += before
        total_after += after
        print('%-40s %5d -> %5d KB' % (os.path.relpath(f, a.dir), before // 1024, after // 1024))

    mode = 'ПРОГНОЗ' if a.dry else 'ГОТОВО'
    print('==== %s: %d файлов, %.1f -> %.1f MB (max=%d, colors=%d) ====' %
          (mode, len(files), total_before / 1048576, total_after / 1048576, a.max, a.colors))


if __name__ == '__main__':
    main()
