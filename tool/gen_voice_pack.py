#!/usr/bin/env python3
"""Полный голосовой пак для приложения (Silero TTS, русский) — ОДИН голос.

После того как выбрал голос в gen_voice_samples.py — поставь его в VOICE ниже и:
    pip install torch soundfile numpy omegaconf
    python tool/gen_voice_pack.py

(omegaconf нужен Silero v4; без него torch.hub падает ModuleNotFoundError.)

Файлы лягут в assets/voice/pack/<key>.wav и попадут в сборку. В Настройках
приложения выбери «Встроенный голос (офлайн)» — будет играть этот пак.

Ключи (<key>) и фразы должны совпадать с картой в lib/core/voice/voice.dart.
Лицензия Silero — открытая, годится для публикации.
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

# ← поставь выбранный голос: baya / kseniya / xenia (жен.) · aidar / eugene (муж.)
VOICE = "baya"
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
    print(f"Голос: {VOICE}. Загружаю модель Silero v4_ru…")
    model, _ = torch.hub.load(
        repo_or_dir="snakers4/silero-models",
        model="silero_tts",
        language="ru",
        speaker="v4_ru",
        trust_repo=True,  # иначе torch.hub зависает на «Do you trust…? (y/N)»
    )
    model.to(torch.device("cpu"))

    os.makedirs(OUT, exist_ok=True)
    for key, text in PHRASES.items():
        audio = model.apply_tts(
            text=text,
            speaker=VOICE,
            sample_rate=SAMPLE_RATE,
            put_accent=True,
            put_yo=True,
        )
        sf.write(os.path.join(OUT, f"{key}.wav"), audio.numpy(), SAMPLE_RATE)
        print("  ok", key)

    print(f"\nГотово → {OUT}  (голос: {VOICE})")
    print("В приложении: Настройки → «Встроенный голос (офлайн)».")


if __name__ == "__main__":
    main()
