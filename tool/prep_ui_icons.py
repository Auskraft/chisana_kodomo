#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Подготовить навигационные PNG-иконки в `assets/ui/` из папки-исходника.

Берёт кириллически-названные PNG (клеевидные кружки на ПРОЗРАЧНОМ фоне),
ужимает до --size px (по умолчанию 200), СОХРАНЯЯ альфу (RGBA), и кладёт под
латинским слагом в `assets/ui/` (карта [NAMES]).

Пример:
    python tool/prep_ui_icons.py --src "E:/.../навИконки"
"""
import argparse
import os

from PIL import Image

# Исходное имя (RU, без .png) -> слаг ассета (EN).
NAMES = {
    'назад': 'back',            # ← undo (Отменить) в раскраске
    'вперёд': 'forward',        # → redo (Вернуть)
    'избранное': 'favorite',    # сердечко
    'Настройки': 'settings',    # шестерёнка (лобби)
    'домой': 'home',            # домой/выход (раскраска, музыка)
    'замок': 'lock',            # детский замок (раскраска)
    'заново': 'restart',        # «Заново» (раскраска)
    'Выбор раскрасок': 'pictures',  # «Картинка» — пикер (раскраска)
    'раскраска': 'mode_paint',  # таб режима «Раскрасить»
    'по номерам': 'mode_numbers',  # таб «По номерам»
    'Рисование': 'mode_draw',   # таб «Рисовать»
    'пауза': 'pause',           # пауза (HUD всех игр)
    'динамик': 'sound',         # звук-кнопка (Ферма / Звуки животных)
}


def main() -> None:
    ap = argparse.ArgumentParser(description='Иконки навигации -> assets/ui/.')
    ap.add_argument('--src', required=True, help='папка с RU-named PNG')
    ap.add_argument('--dst', default='assets/ui', help='куда класть слаги')
    ap.add_argument('--size', type=int, default=200, help='сторона, px')
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
        out = os.path.join(a.dst, en + '.png')
        im.save(out, format='PNG', optimize=True)
        done += 1
        print(f'  {ru}.png  ->  {en}.png  ({os.path.getsize(out) // 1024} KB)')
    print(f'==== ГОТОВО: {done} иконок в {a.dst}/ ====')


if __name__ == '__main__':
    main()
