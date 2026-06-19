#!/usr/bin/env python3
"""Импорт звуков зверей в assets/animals/<key>.wav.

Берёт сырые скачанные файлы (MP3/WAV, любой длины) из мастер-папок, приводит к
формату игры: WAV, моно, 44100 Гц, ~до 1.6 с, с обрезкой тишины по краям и
нормализацией громкости (ffmpeg из пакета imageio-ffmpeg — системный не нужен).
На каждый ключ берётся лучший источник (приоритет: «Обрезанные» → «сырые» →
«Новая папка»). В конце печатает, у каких зверей звука ещё НЕТ.

Запуск:  python tool/prep_animal_sounds.py
"""
import os
import re
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
DST = Path(r"A:\StudioProjects\chisana_kodomo\assets\animals")

# Папки-источники в порядке приоритета (раньше = лучше).
DIRS = [
    Path(r"C:\Users\Auskraft_PC\Downloads\сырые\Новая папка\Обрезанные"),
    Path(r"C:\Users\Auskraft_PC\Downloads\сырые"),
    Path(r"C:\Users\Auskraft_PC\Downloads\сырые\Новая папка"),
]

sys.stdout.reconfigure(encoding="utf-8")

# Все звери игры (ключи) — для отчёта «кого не хватает».
GAME = [
    "dog", "cat", "cow", "pig", "hen", "frog", "sheep", "horse", "chick", "rabbit",
    "lion", "tiger", "elephant", "monkey", "bear", "wolf", "fox", "owl", "duck",
    "rooster", "goat", "donkey", "mouse", "snake", "bee", "giraffe", "zebra",
    "hippo", "rhino", "panda", "koala", "kangaroo", "crocodile", "camel", "deer",
    "raccoon", "hedgehog", "squirrel", "sloth", "dolphin", "whale", "seal",
    "walrus", "penguin", "polar_bear", "turtle", "crab", "parrot", "peacock",
    "flamingo", "swan", "butterfly", "ladybug", "snail",
]
VALID = set(GAME)

# Описательные имена (mixkit/русские) → ключ.
KEYWORDS = {
    "коров": "cow", "петух": "rooster", "kitty": "cat", "meow": "cat",
    "pig": "pig", "horse": "horse", "neigh": "horse", "rooster": "rooster",
    "wolf": "wolf", "monkey": "monkey", "donkey": "donkey", "goat": "goat",
}


def keyof(fname: str):
    s = fname.rsplit(".", 1)[0].lower()
    for junk in ["(mp3cut.net)", "(online-audio-converter.com)", "[cut_1sec]",
                 "[cut 1sec]"]:
        s = s.replace(junk, "")
    s = s.strip().strip("_").strip()
    if "geese" in s or "goose" in s:
        return None  # гуся в игре нет
    if "polar" in s:
        return "polar_bear"  # составной ключ — не резать по '_'
    for kw, key in KEYWORDS.items():
        if kw in s:
            return key
    s = s.replace("zebra6", "zebra")
    tok = re.split(r"[ _]", s)[0]  # отрезаем хвосты-хэши/суффиксы
    return tok if tok in VALID else (tok or None)


def main() -> None:
    DST.mkdir(parents=True, exist_ok=True)
    # Лучший источник на ключ (первая встреча по приоритету папок).
    src = {}
    for d in DIRS:
        if not d.is_dir():
            continue
        for fn in sorted(os.listdir(d)):
            p = d / fn
            if not p.is_file() or p.suffix.lower() not in (".wav", ".mp3"):
                continue
            key = keyof(fn)
            if key in VALID and key not in src:
                src[key] = p

    done = []
    for key, p in sorted(src.items()):
        out = DST / f"{key}.wav"
        cmd = [
            FFMPEG, "-y", "-i", str(p),
            "-ac", "1", "-ar", "44100",
            # обрезаем тишину в начале и в конце, нормализуем
            "-af", ("silenceremove=start_periods=1:start_threshold=-45dB:"
                    "start_silence=0.02,areverse,"
                    "silenceremove=start_periods=1:start_threshold=-45dB:"
                    "start_silence=0.02,areverse,dynaudnorm=g=7"),
            "-t", "1.6",
            str(out),
        ]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode == 0 and out.exists():
            done.append(key)
        else:
            print(f"  !! ошибка {key}: {r.stderr.strip().splitlines()[-1:]}")

    print(f"Импортировано звуков: {len(done)}")
    print("  " + ", ".join(sorted(done)))
    missing = [k for k in GAME if k not in done]
    print(f"\nБез звука ({len(missing)}):")
    print("  " + ", ".join(missing))


if __name__ == "__main__":
    main()
