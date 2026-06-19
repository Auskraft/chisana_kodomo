#!/usr/bin/env python3
"""Портирует светлые/детские палитры из соседних прод-проектов в роли AppColors.

Источник: rotating_shift/lib/themes.dart (ThemeMeta). Берём только СВЕТЛЫЕ темы
(светлый фон) и те, что проходят проверку контраста (текст/фон, текст-на-кнопке).
Маппинг календарных ролей → 9 семантических ролей AppColors; success фиксируем
зелёным (чтобы «правильно!» всегда читалось как зелёное), onPrimary считаем под
контраст. Результат — lib/core/theme/theme_palettes.dart (генерируемый).

Запуск:  python tool/gen_themes.py
"""
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

SRC = Path("A:/StudioProjects/rotating_shift/lib/themes.dart")
OUT = Path("A:/StudioProjects/chisana_kodomo/lib/core/theme/theme_palettes.dart")

# Только тёплые/яркие/детские категории (без поп-культуры: Кино/Аниме/Игры).
KID_CATEGORIES = {
    "Пастельные / Дофаминовые",
    "Фруктовые светлые",
    "Природные зелёные",
    "Эстетики",
    "Нейтральные",
}

# Фиксированный «правильно/успех» — дружелюбный зелёный во всех темах.
SUCCESS = 0xFF7AC74F
DARK_TEXT = 0xFF4E342E  # тёплый тёмно-коричневый (как в дефолте)

# Пороги отбора.
MIN_BG_LUM = 0.80          # фон должен быть светлым (детский, читаемый)
MIN_TEXT_CONTRAST = 3.2    # текст vs фон
MIN_BTN_CONTRAST = 2.6     # текст-на-кнопке vs кнопка


def chans(argb):
    return ((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF)


def _lin(c):
    c /= 255.0
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def luminance(argb):
    r, g, b = chans(argb)
    return 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b)


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def over(fg, bg):
    """Скомпозитить fg (с альфой) поверх bg (непрозрачного) → непрозрачный argb."""
    af = (fg >> 24) & 0xFF
    if af == 0xFF:
        return 0xFF000000 | (fg & 0xFFFFFF)
    a = af / 255.0
    fr, fgr, fb = chans(fg)
    br, bgr, bb = chans(bg)
    r = round(fr * a + br * (1 - a))
    g = round(fgr * a + bgr * (1 - a))
    b = round(fb * a + bb * (1 - a))
    return 0xFF000000 | (r << 16) | (g << 8) | b


def opaque(argb):
    return 0xFF000000 | (argb & 0xFFFFFF)


def field_str(block, name):
    m = re.search(name + r":\s*'([^']*)'", block)
    return m.group(1) if m else None


def field_color(block, name):
    m = re.search(r"\b" + name + r":\s*Color\(0x([0-9A-Fa-f]{8})\)", block)
    return int(m.group(1), 16) if m else None


def slug(theme_id):
    s = re.sub(r"[^a-zA-Z0-9]", "_", theme_id).strip("_").lower()
    return "rs_" + (s or "x")


def main():
    text = SRC.read_text(encoding="utf-8")
    # Разбиваем на блоки по ThemeMeta( — каждый блок = одна тема (поля встречаются
    # по одному разу, поэтому первого совпадения regex достаточно).
    parts = text.split("ThemeMeta(")[1:]
    out, seen, skipped = [], set(), []
    by_cat = {}
    for block in parts:
        tid = field_str(block, "id")
        name = field_str(block, "name")
        if not tid or not name:
            continue
        cat = field_str(block, "category") or "Разные"
        if cat not in KID_CATEGORIES:
            continue
        bg = field_color(block, "bg")
        cal_bg = field_color(block, "calBg")
        accent = field_color(block, "accent")
        today = field_color(block, "todayClr") or field_color(block, "todayBorder")
        wclr = field_color(block, "wClr") or field_color(block, "workText")
        oclr = field_color(block, "oClr") or field_color(block, "offText")
        textc = field_color(block, "textClr") or field_color(block, "headerText")
        if None in (bg, accent, textc):
            continue
        bg_o = opaque(bg)
        if luminance(bg_o) < MIN_BG_LUM:
            skipped.append((tid, "тёмный фон"))
            continue
        surface = over(cal_bg, bg_o) if cal_bg is not None else 0xFFFFFFFF
        primary = opaque(accent)
        secondary = opaque(today or accent)
        acc = opaque(wclr or accent)
        on_bg = opaque(textc)
        on_primary = 0xFFFFFFFF if contrast(0xFFFFFFFF, primary) >= contrast(DARK_TEXT, primary) else DARK_TEXT
        # Контроль читаемости (раз не вижу глазами — проверяем числом).
        if contrast(on_bg, bg_o) < MIN_TEXT_CONTRAST:
            skipped.append((tid, "слабый текст/фон"))
            continue
        if contrast(on_primary, primary) < MIN_BTN_CONTRAST:
            skipped.append((tid, "слабый текст-на-кнопке"))
            continue
        sid = slug(tid)
        if sid in seen:
            continue
        seen.add(sid)
        out.append(dict(id=sid, name=name, category=cat, background=bg_o,
                        surface=surface, primary=primary, secondary=secondary,
                        accent=acc, success=SUCCESS, on_bg=on_bg,
                        on_primary=on_primary))
        by_cat[cat] = by_cat.get(cat, 0) + 1

    # Стабильный порядок: по категории, затем по имени.
    out.sort(key=lambda t: (t["category"], t["name"]))

    def hexc(v):
        return f"Color(0x{v:08X})"

    lines = [
        "// СГЕНЕРИРОВАНО tool/gen_themes.py — не редактировать вручную.",
        "// Палитры портированы из rotating_shift (светлые/детские темы) и смапплены",
        "// в роли AppColors. success фиксирован зелёным; onPrimary — под контраст.",
        "// Перегенерация: python tool/gen_themes.py",
        "import 'package:flutter/material.dart';",
        "",
        "import 'app_colors.dart';",
        "import 'app_theme.dart';",
        "",
        "/// Портированные палитры (после дефолтных трёх в [AppThemes.all]).",
        "const List<AppThemeOption> kPortedThemes = <AppThemeOption>[",
    ]
    for t in out:
        lines.append("  AppThemeOption(")
        lines.append(f"    id: '{t['id']}', name: {dart_str(t['name'])}, category: {dart_str(t['category'])},")
        lines.append("    colors: AppColors(")
        lines.append(f"      background: {hexc(t['background'])}, surface: {hexc(t['surface'])},")
        lines.append(f"      primary: {hexc(t['primary'])}, secondary: {hexc(t['secondary'])},")
        lines.append(f"      accent: {hexc(t['accent'])}, success: {hexc(t['success'])},")
        lines.append(f"      onBackground: {hexc(t['on_bg'])}, onSurface: {hexc(t['on_bg'])},")
        lines.append(f"      onPrimary: {hexc(t['on_primary'])},")
        lines.append("    ),")
        lines.append("  ),")
    lines.append("];")
    lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")

    print(f"Портировано тем: {len(out)}")
    for c, n in sorted(by_cat.items()):
        print(f"  {n:3d}  {c}")
    print(f"Пропущено: {len(skipped)}")
    # Сводка причин.
    reasons = {}
    for _, r in skipped:
        reasons[r] = reasons.get(r, 0) + 1
    for r, n in sorted(reasons.items()):
        print(f"  {n:3d}  {r}")


def dart_str(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


if __name__ == "__main__":
    main()
