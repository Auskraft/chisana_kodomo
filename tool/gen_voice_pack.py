#!/usr/bin/env python3
"""Встроенные голосовые паки для приложения (Silero TTS, русский).

Генерит ОДИН пак на каждый голос из VOICES — в подпапку
assets/voice/pack/<voice>/<key>.wav. В Настройках приложения пользователь
выбирает «Встроенный голос» и конкретный голос (раздел «Голос помощника»);
без пака — фолбэк на системный TTS.

    pip install torch soundfile numpy omegaconf
    python tool/gen_voice_pack.py

(omegaconf нужен Silero v4; без него torch.hub падает ModuleNotFoundError.)

Ключи (<key>) и фразы должны совпадать с картой в lib/core/voice/voice.dart,
а список голосов — со списком в settings (см. Voice.packVoices). Лицензия
Silero — открытая, годится для публикации.
"""

import os
import sys

import soundfile as sf
import torch

# Печать рус. текста/стрелок не должна падать на cp1251-консоли Windows.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

# Голоса, которые попадут в выбор пользователя (женские Silero v4_ru).
# Мужские (aidar/eugene) намеренно не включаем. Чтобы добавить/убрать —
# правь и этот список, и Voice.packVoices в lib/core/voice/voice.dart.
VOICES = ["baya", "kseniya", "xenia"]
SAMPLE_RATE = 48000

PHRASES = {
    "num_0": "ноль.",
    "num_1": "один.",
    "num_2": "два.",
    "num_3": "три.",
    "num_4": "четыре.",
    "num_5": "пять.",
    "num_6": "шесть.",
    "num_7": "семь.",
    "num_8": "восемь.",
    "num_9": "девять.",
    "num_10": "десять.",
    "praise_0": "Молодец!",
    "praise_1": "Умница!",
    "praise_2": "Здорово!",
    "praise_3": "Верно!",
    "praise_4": "Супер!",
    "praise_5": "Класс!",
    "praise_6": "Получилось!",
    "praise_7": "Отлично!",
    "prompt_count": "Посчитай!",
    "prompt_howmany": "Сколько?",
    "try_again": "Попробуй ещё.",
    "set_done": "Молодец! Ты справился!",
    "set_done_girl": "Молодец! Ты справилась!",
    "set_done_neutral": "Молодец! Всё получилось!",
    "greet": "Привет! Давай посчитаем!",
}

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(_ROOT, "assets", "voice", "pack")


def main() -> None:
    torch.set_num_threads(4)
    print(f"Голоса: {', '.join(VOICES)}. Загружаю модель Silero v4_ru…")
    model, _ = torch.hub.load(
        repo_or_dir="snakers4/silero-models",
        model="silero_tts",
        language="ru",
        speaker="v4_ru",
        trust_repo=True,  # иначе torch.hub зависает на «Do you trust…? (y/N)»
    )
    model.to(torch.device("cpu"))

    for voice in VOICES:
        vdir = os.path.join(OUT, voice)
        os.makedirs(vdir, exist_ok=True)
        for key, text in PHRASES.items():
            audio = model.apply_tts(
                text=text,
                speaker=voice,
                sample_rate=SAMPLE_RATE,
                put_accent=True,
                put_yo=True,
            )
            sf.write(os.path.join(vdir, f"{key}.wav"), audio.numpy(), SAMPLE_RATE)
        print(f"  готово: {voice} ({len(PHRASES)} клипов)")

    print(f"\nГотово → {OUT}/<voice>/  (голоса: {', '.join(VOICES)})")
    print("В приложении: Настройки → «Голос помощника» → встроенный голос.")


if __name__ == "__main__":
    main()
