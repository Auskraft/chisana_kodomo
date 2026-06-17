#!/usr/bin/env python3
"""Генератор СЭМПЛОВ голоса для прослушивания и выбора (Silero TTS, русский).

Зачем: послушать несколько чистых по лицензии нейроголосов и выбрать, какой
поставим в приложение. Это НЕ финальный пак — только короткие сэмплы на выбор.

Запуск (как генератор джинглов в танках):
    pip install torch soundfile numpy
    python tool/gen_voice_samples.py

Результат: tool/voice_samples/<voice>/<key>.wav — послушай папки, выбери голос
и скажи какой. Дальше я сгенерю полный пак этим голосом и подключу в игру
(выбор останется в Настройках).

Лицензия: Silero TTS — открытая, можно использовать в публикуемом приложении.
"""

import os

import soundfile as sf
import torch

SAMPLE_RATE = 48000

# Голоса модели v4_ru (женские: baya/kseniya/xenia; мужские: aidar/eugene).
VOICES = ["baya", "kseniya", "xenia", "aidar", "eugene"]

# Небольшой набор фраз, чтобы оценить «фил»: счёт, вопрос, похвала, приветствие.
PHRASES = {
    "odin": "Один.",
    "dva": "Два.",
    "tri": "Три.",
    "skolko": "Сколько?",
    "molodec": "Молодец!",
    "privet": "Привет! Давай посчитаем!",
}

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "voice_samples")


def main() -> None:
    torch.set_num_threads(4)
    print("Загружаю модель Silero v4_ru (первый раз — скачается)…")
    model, _ = torch.hub.load(
        repo_or_dir="snakers4/silero-models",
        model="silero_tts",
        language="ru",
        speaker="v4_ru",
    )
    model.to(torch.device("cpu"))

    for voice in VOICES:
        voice_dir = os.path.join(OUT_DIR, voice)
        os.makedirs(voice_dir, exist_ok=True)
        for key, text in PHRASES.items():
            audio = model.apply_tts(
                text=text,
                speaker=voice,
                sample_rate=SAMPLE_RATE,
                put_accent=True,
                put_yo=True,
            )
            path = os.path.join(voice_dir, f"{key}.wav")
            sf.write(path, audio.numpy(), SAMPLE_RATE)
        print(f"  готово: {voice}")

    print(f"\nГотово → {OUT_DIR}")
    print("Послушай папки голосов и скажи, какой нравится — подключу его в игру.")


if __name__ == "__main__":
    main()
