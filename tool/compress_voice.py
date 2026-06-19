#!/usr/bin/env python3
"""Сжать клипы голос-пака WAV → MP3 (ffmpeg) ради веса APK.

Речь при 64 kbps mono практически неотличима от WAV, а файл ~10× меньше
(полный пак со всеми композиционными фразами: ~72 МБ WAV → ~6 МБ MP3).

    pip install imageio-ffmpeg
    python tool/gen_voice_pack.py      # синтез (Silero) → .wav
    python tool/compress_voice.py      # .wav → .mp3 (этот скрипт)

Конвертит assets/voice/pack/<voice>/*.wav → .mp3 и удаляет .wav. Приложение
играет .mp3 (Voice строит путь с расширением .mp3).
"""

import glob
import os
import subprocess
import sys

import imageio_ffmpeg

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
BITRATE = "64k"

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACK = os.path.join(_ROOT, "assets", "voice", "pack")


def main() -> None:
    wavs = glob.glob(os.path.join(PACK, "*", "*.wav"))
    if not wavs:
        print("Нет .wav в", PACK, "— нечего сжимать.")
        return
    print(f"Конвертирую {len(wavs)} клипов WAV → MP3 ({BITRATE} mono)…")
    done = 0
    for w in wavs:
        mp3 = w[:-4] + ".mp3"
        r = subprocess.run(
            [FFMPEG, "-y", "-i", w, "-ac", "1", "-b:a", BITRATE,
             "-loglevel", "error", mp3],
        )
        if r.returncode == 0 and os.path.exists(mp3):
            os.remove(w)
            done += 1
        else:
            print("  ! ошибка конвертации:", w)
    print(f"Готово: {done}/{len(wavs)} → .mp3, исходные .wav удалены.")


if __name__ == "__main__":
    main()
