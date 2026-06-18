#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Подготовить иконки игр (карточки лобби) в `assets/games/` из папки-исходника.

Берёт кириллически-названные PNG (клеевидные иллюстрации, «полная заливка» —
кремовый фон под цвет карточки), ужимает до --size px (по умолчанию 500, как у
текущих) с сохранением альфы и кладёт под латинским слагом = id игры.

Пример:
    python tool/prep_game_icons.py --src "E:/.../Без фона/полная заливка"
"""
import argparse
import os

from PIL import Image

# Исходное имя (RU, без .png) -> id игры (= имя ассета в assets/games/).
NAMES = {
    'счёт': 'counting',
    'парочки': 'pairs',
    'Цвета и формы': 'colors_shapes',
    'Звуки': 'animals',          # «Звуки животных»
    'музыка': 'music',
    'раскраска': 'coloring',
    'ферма': 'farm',
    'Что лишнее': 'odd_one_out',
    'пазлы': 'puzzles',
}


def main() -> None:
    ap = argparse.ArgumentParser(description='Иконки игр -> assets/games/.')
    ap.add_argument('--src', required=True, help='папка с RU-named PNG')
    ap.add_argument('--dst', default='assets/games', help='куда класть слаги')
    ap.add_argument('--size', type=int, default=460, help='сторона, px')
    ap.add_argument('--colors', type=int, default=256,
                    help='палитра PNG-8 (0 — RGBA без квантования); FASTOCTREE, альфа сохр.')
    a = ap.parse_args()

    os.makedirs(a.dst, exist_ok=True)
    done = 0
    for ru, en in NAMES.items():
        src = os.path.join(a.src, ru + '.png')
        if not os.path.isfile(src):
            print(f'  ПРОПУСК (нет файла): {ru}.png')
            continue
        im = Image.open(src).convert('RGBA')
        if max(im.size) != a.size:
            im = im.resize((a.size, a.size), Image.LANCZOS)
        if a.colors:
            # FASTOCTREE поддерживает альфу (MEDIANCUT — нет).
            im = im.quantize(colors=a.colors, method=Image.Quantize.FASTOCTREE)
        out = os.path.join(a.dst, en + '.png')
        im.save(out, format='PNG', optimize=True)
        done += 1
        print(f'  {ru}.png  ->  {en}.png  ({os.path.getsize(out) // 1024} KB)')
    print(f'==== ГОТОВО: {done} иконок в {a.dst}/ ====')


if __name__ == '__main__':
    main()
