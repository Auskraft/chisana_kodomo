#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Импорт контурных раскрасок из папки-мастера в assets/coloring/<тема>/.

Исходник ожидается как `<src>/<уровень 1..5>/<имя>.png` (имена могут быть
кириллицей и с пробелами). Скрипт копирует каждый файл в
`assets/coloring/<theme>/<уровень>/<slug>.png`, транслитерируя имя в латиницу и
нижний регистр (как у темы `animals` — латинские имена надёжнее для путей-
ассетов на Android). Пробелы/дефисы → `_`, коллизии слагов разводятся суффиксом.

После импорта прогони ужималку, чтобы сбить вес:
    python tool/compress_coloring.py --dir assets/coloring/<theme>

Оригиналы держи в папке-мастере — это только импорт-копия в assets/.

Пример:
    python tool/import_coloring.py --src "E:/.../Тачки" --theme cars
"""
import argparse
import os
import re
import shutil

# Простая практическая транслитерация RU→Latin (для имён файлов, не текста UI).
TRANSLIT = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'e',
    'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'h', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sch',
    'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
}
EXTS = ('.png', '.jpg', '.jpeg')


def slug(name: str) -> str:
    s = ''.join(TRANSLIT.get(ch, ch) for ch in name.lower())
    s = re.sub(r'[^a-z0-9]+', '_', s).strip('_')
    return s or 'image'


def main() -> None:
    ap = argparse.ArgumentParser(description='Импорт раскрасок в assets/coloring.')
    ap.add_argument('--src', required=True, help='папка-мастер с подпапками 1..5')
    ap.add_argument('--theme', required=True, help='ключ темы (cars/nature/food/...)')
    ap.add_argument('--dst', default='assets/coloring', help='корень ассетов раскрасок')
    a = ap.parse_args()

    total = 0
    for level in range(1, 6):
        src_dir = os.path.join(a.src, str(level))
        if not os.path.isdir(src_dir):
            continue
        dst_dir = os.path.join(a.dst, a.theme, str(level))
        os.makedirs(dst_dir, exist_ok=True)
        used = set()
        for fn in sorted(os.listdir(src_dir)):
            stem, ext = os.path.splitext(fn)
            if ext.lower() not in EXTS:
                continue
            base = slug(stem)
            out = base
            i = 2
            while out in used:  # развести коллизии слагов
                out = f'{base}_{i}'
                i += 1
            used.add(out)
            shutil.copy2(os.path.join(src_dir, fn),
                         os.path.join(dst_dir, out + ext.lower()))
            total += 1
            print(f'  L{level}: {fn}  ->  {out}{ext.lower()}')
    print(f'==== ГОТОВО: импортировано {total} файлов в {a.dst}/{a.theme}/ ====')


if __name__ == '__main__':
    main()
