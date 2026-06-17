"""Процедурные тоны ксилофона для игры «Музыка» (Фаза 5).

Только стандартная библиотека. До-мажор, одна октава (8 пластин) — порядок и
полутоны совпадают с `Xylophone.cMajor` в `music_logic.dart`.

Запуск:  python tool/gen_notes.py
Выход:   assets/notes/note_0..note_7.wav  (индекс = позиция в cMajor)
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

# Marimba-подобный тембр: основной тон + затухающие обертоны.
HARMONICS = (1.0, 0.5, 0.28, 0.12)
DUR = 0.55
DECAY = 6.5
ATTACK = 0.004


def note(freq):
    n = int(DUR * SR)
    hsum = sum(HARMONICS)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1.0, t / ATTACK) * math.exp(-DECAY * t)
        s = sum(h * math.sin(2 * math.pi * freq * (k + 1) * t)
                for k, h in enumerate(HARMONICS))
        out.append(0.5 * env * s / hsum)
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
    for i, semi in enumerate(SEMITONES):
        freq = BASE_HZ * (2 ** (semi / 12))
        write_wav(f"note_{i}", note(freq))
    print("Готово.")


if __name__ == "__main__":
    main()
