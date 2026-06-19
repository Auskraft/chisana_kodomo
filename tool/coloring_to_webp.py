#!/usr/bin/env python3
"""Раскраски PNG → WebP (lossy q90) ради веса APK.

PNG уже квантованы в палитру (compress_coloring.py), поэтому lossless WebP почти
не жмёт (~6%). Реальный выигрыш — lossy q90: ~54 МБ → ~7.4 МБ (в ~7×). Контуры
сохраняются, заливка (flood_fill) устойчива к артефактам — порог по яркости с
допуском 64. Прозрачность (если есть) кладём на белый фон.

    pip install pillow
    python tool/coloring_to_webp.py

Конвертит assets/coloring/<тема>/<уровень>/*.png → .webp и удаляет .png.
Приложение принимает .webp (parseColoringAsset в coloring_pictures.dart).
Оригиналы восстановимы из мастер-папки и git-истории. Если на устройстве заливка
где-то протекает — подними QUALITY (95) и перегони, либо верни PNG из истории.
"""

import glob
import os
import sys

from PIL import Image

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

QUALITY = 90

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACK = os.path.join(_ROOT, "assets", "coloring")


def main() -> None:
    pngs = glob.glob(os.path.join(PACK, "*", "*", "*.png"))
    if not pngs:
        print("Нет .png в", PACK, "— нечего конвертировать.")
        return
    before = sum(os.path.getsize(p) for p in pngs)
    print(f"Конвертирую {len(pngs)} раскрасок PNG → WebP (q{QUALITY})…")
    after = 0
    done = 0
    for p in pngs:
        out = p[:-4] + ".webp"
        try:
            im = Image.open(p).convert("RGBA")
            bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
            bg.alpha_composite(im)
            bg.convert("RGB").save(out, "WEBP", quality=QUALITY, method=6)
        except Exception as e:
            print("  ! ошибка:", p, e)
            continue
        after += os.path.getsize(out)
        os.remove(p)
        done += 1
    print(f"Готово: {done}/{len(pngs)} → .webp; .png удалены.")
    print(f"Вес: {before // 1024 // 1024} МБ → {after // 1024 // 1024} МБ "
          f"({after / before * 100:.0f}%).")


if __name__ == "__main__":
    main()
