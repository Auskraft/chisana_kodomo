#!/usr/bin/env python3
"""Импорт арт-иконок зверей в assets/animals/<key>.png.

Берёт английские по имени PNG из мастер-папки (кириллические — это уже
подключённые старые, пропускаем), приводит к виду существующих (400×400, RGB,
кремовый фон #FDF2D9) и кладёт под ключом. Пробелы → '_'; спец-случаи:
«baby deer» → deer, «polar bear» → polar_bear.

Запуск:  python tool/prep_animals.py
"""
import os
import sys
from pathlib import Path

from PIL import Image

SRC = Path(r"E:\Проекты\Детская игра\Иконки животных")
DST = Path(r"A:\StudioProjects\chisana_kodomo\assets\animals")
CREAM = (0xFD, 0xF2, 0xD9)
SPECIAL = {"baby deer": "deer", "polar bear": "polar_bear"}

sys.stdout.reconfigure(encoding="utf-8")


def is_ascii(s: str) -> bool:
    return all(ord(c) < 128 for c in s)


def main() -> None:
    DST.mkdir(parents=True, exist_ok=True)
    done = []
    for fn in sorted(os.listdir(SRC)):
        if not fn.lower().endswith(".png"):
            continue
        stem = fn[:-4]
        if not is_ascii(stem):  # кириллические = старые (уже подключены)
            continue
        key = SPECIAL.get(stem.lower(), stem.lower().replace(" ", "_"))
        im = Image.open(SRC / fn)
        if im.mode in ("RGBA", "LA", "P"):
            im = im.convert("RGBA")
            bg = Image.new("RGBA", im.size, CREAM + (255,))
            bg.alpha_composite(im)
            im = bg.convert("RGB")
        else:
            im = im.convert("RGB")
        if im.size != (400, 400):
            im = im.resize((400, 400), Image.LANCZOS)
        im.save(DST / f"{key}.png")
        done.append(key)
    print(f"Импортировано: {len(done)}")
    print(", ".join(sorted(done)))


if __name__ == "__main__":
    main()
