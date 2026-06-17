"""Процедурные звуковые эффекты для «Chisana kodomo» (Фаза 5).

Только стандартная библиотека (wave + math + struct) — без зависимостей.
Звуки мягкие и добрые (детское приложение, «без проигрышей»): без резких
негативных сигналов, «не то» = нейтральный тёплый «пуф».

Запуск:  python tool/gen_sfx.py
Выход:   assets/sfx/{tap,correct,soft,star,complete,start}.wav  (имена = SfxEvent)
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
OUT = os.path.join(ROOT, "assets", "sfx")


def tone(freq, dur, vol=0.5, harmonics=(1.0,), decay=8.0, attack=0.004):
    """Один затухающий тон с обертонами (marimba-подобный при decay побольше)."""
    n = int(dur * SR)
    hsum = sum(harmonics)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1.0, t / attack) * math.exp(-decay * t)
        s = sum(h * math.sin(2 * math.pi * freq * (k + 1) * t)
                for k, h in enumerate(harmonics))
        out.append(vol * env * s / hsum)
    return out


def seq(*chunks):
    out = []
    for c in chunks:
        out.extend(c)
    return out


def silence(dur):
    return [0.0] * int(dur * SR)


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
    print("  ", os.path.relpath(path, ROOT), f"({len(samples) / SR:.2f}s)")


# Ноты (Гц)
C5, D5, E5, G5, A5, C6, E6, G6 = 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1318.5, 1568.0

MARIMBA = (1.0, 0.5, 0.25)

SOUNDS = {
    # Короткий мягкий «пум» по тапу.
    "tap": tone(E5, 0.10, vol=0.35, harmonics=MARIMBA, decay=22.0),
    # Радостный «дзынь»: две восходящие ноты.
    "correct": seq(
        tone(G5, 0.12, vol=0.5, harmonics=MARIMBA, decay=11.0),
        tone(C6, 0.20, vol=0.5, harmonics=MARIMBA, decay=8.0),
    ),
    # «Не то» — нейтральный тёплый «пуф», низкий и тихий (без негатива).
    "soft": tone(220.0, 0.16, vol=0.32, harmonics=(1.0, 0.3), decay=10.0),
    # Звёздочка — короткий искристый высокий блик.
    "star": seq(
        tone(C6, 0.07, vol=0.4, harmonics=(1.0, 0.6), decay=20.0),
        tone(E6, 0.07, vol=0.4, harmonics=(1.0, 0.6), decay=20.0),
        tone(G6, 0.12, vol=0.4, harmonics=(1.0, 0.6), decay=14.0),
    ),
    # Набор пройден — маленький фанфар (восходящее трезвучие + октава).
    "complete": seq(
        tone(C5, 0.12, vol=0.5, harmonics=MARIMBA, decay=10.0),
        tone(E5, 0.12, vol=0.5, harmonics=MARIMBA, decay=10.0),
        tone(G5, 0.12, vol=0.5, harmonics=MARIMBA, decay=10.0),
        tone(C6, 0.28, vol=0.55, harmonics=MARIMBA, decay=6.0),
    ),
    # Старт игры — дружелюбный «динь-дон».
    "start": seq(
        tone(G5, 0.12, vol=0.45, harmonics=MARIMBA, decay=12.0),
        tone(C6, 0.22, vol=0.45, harmonics=MARIMBA, decay=8.0),
    ),
}


def main():
    print("Генерация SFX →", os.path.relpath(OUT, ROOT))
    for name, samples in SOUNDS.items():
        write_wav(name, samples)
    print("Готово.")


if __name__ == "__main__":
    main()
