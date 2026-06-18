"""Процедурные тоны для игры «Музыка»: 3 клавишных инструмента.

Только стандартная библиотека. До-мажор, одна октава (8 нот) — порядок и
полутоны совпадают с `Xylophone.cMajor` в `music_logic.dart`.

Инструменты (префикс файла = `Instrument.soundPrefix`):
  • note  — ксилофон: яркий короткий «щелчок» (маримба-обертоны, быстрое затухание);
  • piano — пианино: теплее и длиннее, богаче обертонами;
  • organ — орган: тянущийся тон (трапеция attack→плато→release), октавные обертоны.

Запуск:  python tool/gen_notes.py
Выход:   assets/notes/<prefix>_0..7.wav   (индекс = позиция в cMajor)
"""

import math
import os
import struct
import sys
import wave

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

SR = 44100
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "notes")

BASE_HZ = 261.63  # «до» (C4) — как Xylophone.baseHz
SEMITONES = [0, 2, 4, 5, 7, 9, 11, 12]  # до ре ми фа соль ля си до²

# Гармоники = амплитуды обертонов (1×, 2×, 3× … от основной частоты).
# sustain=False → ударная огибающая exp(-decay·t) (ксилофон/пианино);
# sustain=True  → трапеция attack→плато→release (тянущийся орган).
INSTRUMENTS = {
    "note": dict(  # ксилофон (не менять — совпадает с прежними note_N.wav)
        harmonics=(1.0, 0.5, 0.28, 0.12),
        dur=0.55, attack=0.004, decay=6.5, sustain=False),
    "piano": dict(  # пианино: длиннее, богаче, мягче
        harmonics=(1.0, 0.6, 0.4, 0.25, 0.15, 0.08),
        dur=1.0, attack=0.006, decay=3.4, sustain=False),
    "organ": dict(  # орган: тянущийся, октавные обертоны (2×, 4×, 8×)
        harmonics=(1.0, 0.5, 0.0, 0.45, 0.0, 0.0, 0.0, 0.3),
        dur=0.8, attack=0.02, release=0.12, sustain=True),
    "bells": dict(  # колокольчики/металлофон: НЕгармонические обертоны (как у
                    # струнного металла) → яркий «металлический» звон, долгий хвост
        partials=[(1.0, 1.0), (2.76, 0.55), (5.40, 0.30), (8.93, 0.16)],
        dur=1.6, attack=0.001, decay=3.0, sustain=False),
    "synth": dict(  # синтезатор: «пила» (все обертоны 1/n) → яркий бузз, электронно
        harmonics=(1.0, 0.5, 0.33, 0.25, 0.2, 0.16, 0.14, 0.12),
        dur=0.7, attack=0.005, decay=3.0, sustain=False),
}


def envelope(t, p):
    a = min(1.0, t / p["attack"]) if p["attack"] > 0 else 1.0
    if p.get("sustain"):
        rel = p.get("release", 0.1)
        if t > p["dur"] - rel:
            return a * max(0.0, (p["dur"] - t) / rel)
        return a
    return a * math.exp(-p["decay"] * t)


def note(freq, p):
    n = int(p["dur"] * SR)
    # partials=[(ratio, amp), …] — произвольные обертоны (в т.ч. НЕцелые, для
    # колокольчиков); иначе harmonics → целые кратные 1×, 2×, 3× …
    parts = p["partials"] if "partials" in p \
        else [(k + 1, h) for k, h in enumerate(p["harmonics"])]
    norm = sum(a for _, a in parts)
    out = []
    for i in range(n):
        t = i / SR
        s = sum(a * math.sin(2 * math.pi * freq * r * t) for r, a in parts)
        out.append(0.5 * envelope(t, p) * s / norm)
    return out


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        )
        w.writeframes(frames)
    print("  ", os.path.relpath(path, ROOT))


def main():
    print("Генерация нот →", os.path.relpath(OUT, ROOT))
    for prefix, p in INSTRUMENTS.items():
        for i, semi in enumerate(SEMITONES):
            freq = BASE_HZ * (2 ** (semi / 12))
            write_wav(f"{prefix}_{i}", note(freq, p))
    print("Готово.")


if __name__ == "__main__":
    main()
