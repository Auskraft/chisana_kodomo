#!/usr/bin/env python3
"""Картинки «по номерам» из плоскоцветных мастеров.

Вход: цветная картинка (плоские цвета + контур + белый фон).
Выход на каждую (в tool/_pbn_out/):
  • <name>_lineart.png — контур (чёрные линии на белом) для раскрашивания;
  • <name>.json — сайдкар: палитра (цвета) + регионы (центр+номер);
  • <name>_preview.png — контур + номера + легенда (для глаз);
  • <name>_filled.png — «ответ-ключ» (регионы залиты цветом) для сверки.

Сегментация ПО ЦВЕТУ (не только по контуру): квантуем в ~16 цветов, регионы =
связные компоненты одного цвета. Так розовое тело и синее крыло разделяются, даже
если между ними нет чёрной линии. Контур-линии в line-art дорисовываем по границам
регионов. Тёмно-красный/синий — это цвета-кластеры (не «съедаются» как контур).

    pip install pillow numpy scipy
    python tool/gen_paint_by_number.py
"""

import glob
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

QUANT_COLORS = 16
OUTLINE_LUMA = 70      # кластер темнее этого = чёрный контур (не регион)
MIN_REGION_FRAC = 0.0012
MERGE_DIST = 50        # близкие цвета регионов → один номер


def _luma(a):
    return 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]


def _font(size):
    for nm in ("arialbd.ttf", "arial.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(nm, size)
        except Exception:
            continue
    return ImageFont.load_default()


def process(path):
    im = Image.open(path).convert("RGB")
    arr = np.asarray(im).astype(np.int16)
    h, w = arr.shape[:2]

    # Медианный фильтр сглаживает спеклы/текстуру/AA, сохраняя края → чистые
    # плоские области после квантования (иначе регион дробится на крошки).
    sm = im.filter(ImageFilter.MedianFilter(5))
    q = sm.quantize(colors=QUANT_COLORS, method=Image.Quantize.FASTOCTREE,
                    dither=Image.Dither.NONE)
    qidx = np.asarray(q)
    k = int(qidx.max()) + 1
    qpal = np.array(q.getpalette()[: k * 3], dtype=np.int16).reshape(-1, 3)
    clum = _luma(qpal)
    outline = np.isin(qidx, np.where(clum < OUTLINE_LUMA)[0])

    min_size = int(h * w * MIN_REGION_FRAC)
    struct = ndimage.generate_binary_structure(2, 1)
    labels = np.zeros((h, w), dtype=np.int32)
    background = np.zeros((h, w), bool)
    regions = []
    nid = 0
    for ci in range(k):
        if clum[ci] < OUTLINE_LUMA:
            continue
        cc, ncc = ndimage.label(qidx == ci, structure=struct)
        white = clum[ci] > 225
        for j in range(1, ncc + 1):
            m = cc == j
            size = int(m.sum())
            touches = (m[0, :].any() or m[-1, :].any()
                       or m[:, 0].any() or m[:, -1].any())
            if white and touches:
                background |= m  # фон (белое, касается края)
                continue
            if size < min_size:
                continue
            nid += 1
            labels[m] = nid
            dt = ndimage.distance_transform_edt(m)
            cy, cx = np.unravel_index(int(dt.argmax()), dt.shape)
            regions.append({"cx": int(cx), "cy": int(cy),
                            "color": qpal[ci].astype(int), "lbl": nid})

    # Залить мелкие дырки-спеклы (не контур, не фон) ближайшим регионом — иначе
    # текстура/блики дробят область на крошки с белыми пятнами.
    holes = (labels == 0) & ~outline & ~background
    if holes.any() and (labels > 0).any():
        inds = ndimage.distance_transform_edt(
            labels == 0, return_distances=False, return_indices=True)
        nearest = labels[tuple(inds)]
        labels[holes] = nearest[holes]

    # Палитра приложения: близкие цвета регионов → один номер.
    pal = []
    for r in regions:
        c = r["color"]
        idx = next((j for j, p in enumerate(pal)
                    if np.linalg.norm(c - p) < MERGE_DIST), None)
        if idx is None:
            pal.append(c)
            idx = len(pal) - 1
        r["cidx"] = idx
    pal = [tuple(int(v) for v in p) for p in pal]
    return arr, labels, regions, pal, w, h, outline


def _lineart(labels, outline, h, w):
    lab = labels
    bnd = np.zeros((h, w), bool)
    d = lab[:-1, :] != lab[1:, :]
    bnd[:-1, :] |= d
    bnd[1:, :] |= d
    d = lab[:, :-1] != lab[:, 1:]
    bnd[:, :-1] |= d
    bnd[:, 1:] |= d
    black = outline | bnd
    black = ndimage.binary_dilation(black, iterations=1)
    la = np.where(black[..., None], 0, 255).astype(np.uint8)
    return np.repeat(la, 3, axis=2)


def write_outputs(name, out, labels, regions, pal, w, h, outline):
    os.makedirs(out, exist_ok=True)
    la = _lineart(labels, outline, h, w)
    Image.fromarray(la).save(os.path.join(out, f"{name}_lineart.png"))

    recon = la.copy()
    for r in regions:
        recon[labels == r["lbl"]] = pal[r["cidx"]]
    Image.fromarray(recon).save(os.path.join(out, f"{name}_filled.png"))

    side = {
        "w": w, "h": h,
        "palette": [list(c) for c in pal],
        "regions": [{"x": round(r["cx"] / w, 4), "y": round(r["cy"] / h, 4),
                     "c": r["cidx"]} for r in regions],
    }
    with open(os.path.join(out, f"{name}.json"), "w", encoding="utf-8") as f:
        json.dump(side, f, ensure_ascii=False, indent=1)

    prev = Image.fromarray(la.copy())
    dr = ImageDraw.Draw(prev)
    fsz = max(16, w // 30)
    font = _font(fsz)
    for r in regions:
        dr.text((r["cx"], r["cy"]), str(r["cidx"] + 1), font=font,
                fill=(20, 20, 20), anchor="mm",
                stroke_width=max(2, fsz // 8), stroke_fill=(255, 255, 255))
    sw = max(28, w // 18)
    canvas = Image.new("RGB", (w, h + sw + 16), (255, 255, 255))
    canvas.paste(prev, (0, 0))
    cd = ImageDraw.Draw(canvas)
    x = 8
    for i, c in enumerate(pal):
        cd.rectangle([x, h + 8, x + sw, h + 8 + sw], fill=tuple(c), outline=(0, 0, 0))
        cd.text((x + sw / 2, h + 8 + sw / 2), str(i + 1), font=_font(sw * 2 // 3),
                fill=(0, 0, 0) if sum(c) > 360 else (255, 255, 255), anchor="mm")
        x += sw + 12
    canvas.save(os.path.join(out, f"{name}_preview.png"))
    return len(regions), len(pal)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(root, "tool", "_pbn_samples")
    out = os.path.join(root, "tool", "_pbn_out")
    srcs = sorted(glob.glob(os.path.join(src, "*.png")))
    if not srcs:
        print("Нет картинок в", src)
        return
    for p in srcs:
        name = os.path.splitext(os.path.basename(p))[0]
        arr, labels, regions, pal, w, h, outline = process(p)
        nr, npc = write_outputs(name, out, labels, regions, pal, w, h, outline)
        print(f"  {name}: {nr} регионов, {npc} цветов(номеров)  [{w}x{h}]")
    print(f"\nГотово → {out}  (*_filled.png — сверь с оригиналом)")


if __name__ == "__main__":
    main()
