#!/usr/bin/env python3
"""Встроенные голосовые паки для приложения (Silero TTS, русский).

Генерит ОДИН пак на каждый голос из VOICES — в подпапку
assets/voice/pack/<voice>/. Два вида клипов:
  • ФИКСИРОВАННЫЕ фразы — семантическое имя файла (<key>.wav, см. PHRASES;
    ключи совпадают с _clipKeys в lib/core/voice/voice.dart);
  • КОМПОЗИЦИОННЫЕ фразы (с переменной: «Это цифра три!», «Где собачка?»,
    «Жёлтая звезда!») — имя файла = FNV-1a хеш текста (см. fnv1a ниже; та же
    функция Voice.clipKey в Dart). Приложение хеширует то, что собирается
    сказать, и ищет клип; нет клипа — фолбэк на системный TTS.

    pip install torch soundfile numpy omegaconf imageio-ffmpeg
    python tool/gen_voice_pack.py     # синтез Silero → .wav
    python tool/compress_voice.py     # .wav → .mp3 (бандлится .mp3, ~10× меньше)

(omegaconf нужен Silero v4; без него torch.hub падает ModuleNotFoundError.
Приложение играет .mp3 — обязательно прогони compress_voice.py после генерации.)

Списки переменных (числа/звери/цвета/формы) держать в синхроне с Dart-источниками
(animals_logic.dart, colors_shapes_logic.dart, counting_flame_game.dart). Рассинхрон
безопасен: несовпавшая фраза просто уходит в TTS. Лицензия Silero — открытая.
"""

import glob
import os
import sys

import soundfile as sf
import torch

# Печать рус. текста/стрелок не должна падать на cp1251-консоли Windows.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

# Голоса (женские Silero v4_ru). Состав — синхронно с Voice.packVoices.
VOICES = ["baya", "kseniya", "xenia"]
SAMPLE_RATE = 48000

# ── Фиксированные фразы: <key> → текст (семантическое имя файла) ──────────────
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
    "prompt_pairs": "Найди пару!",
    "prompt_odd": "Найди лишнее!",
    "prompt_puzzles": "Собери картинку!",
    "coloring_done": "Готово! Красиво!",
    "set_done": "Молодец! Ты справился!",
    "set_done_girl": "Молодец! Ты справилась!",
    "set_done_neutral": "Молодец! Всё получилось!",
    "greet": "Привет! Давай посчитаем!",
}

# ── Данные для композиционных фраз (синхронно с Dart) ─────────────────────────
# counting_flame_game.dart: _numberWord
NUMBER_WORDS = ["ноль", "один", "два", "три", "четыре", "пять", "шесть", "семь",
                "восемь", "девять", "десять"]
# animals_logic.dart: Animals.all[*].name (54)
ANIMAL_NAMES = [
    "собачка", "кошечка", "коровка", "свинка", "курочка", "лягушка", "овечка",
    "лошадка", "цыплёнок", "зайка", "львёнок", "тигрёнок", "слонёнок",
    "обезьянка", "мишка", "волчок", "лисёнок", "совёнок", "уточка", "петушок",
    "козлик", "ослик", "мышка", "змейка", "пчёлка", "жирафик", "зебра",
    "бегемотик", "носорог", "панда", "коала", "кенгурёнок", "крокодильчик",
    "верблюжонок", "оленёнок", "енотик", "ёжик", "белочка", "ленивец",
    "дельфинчик", "китёнок", "тюлень", "морж", "пингвинёнок", "белый мишка",
    "черепашка", "крабик", "попугайчик", "павлин", "фламинго", "лебедь",
    "бабочка", "божья коровка", "улитка",
]
# colors_shapes_logic.dart: kColorNameM / kColorNameF / ShapeKind.noun
COLORS_M = ["красный", "жёлтый", "синий", "зелёный", "оранжевый", "фиолетовый",
            "розовый", "коричневый"]
COLORS_F = ["красная", "жёлтая", "синяя", "зелёная", "оранжевая", "фиолетовая",
            "розовая", "коричневая"]
SHAPES_M = ["круг", "квадрат", "треугольник", "ромб", "овал"]  # мужской род
SHAPE_FEM = "звезда"  # единственная «женская» фигура (isFeminine)


def compositional_phrases() -> list[str]:
    out: list[str] = []
    for w in NUMBER_WORDS:                      # Счёт
        out.append(f"Это цифра {w}!")
        out.append(f"Сколько получилось? Найди цифру {w}!")
    for n in ANIMAL_NAMES:                      # Звуки / Ферма
        out.append(f"Где {n}?")
        out.append(n[0].upper() + n[1:] + "!")  # animalNameCap + «!»
    for shape in SHAPES_M:                      # Угадай-ка (мужской род)
        for c in COLORS_M:
            out.append(f"Где {c} {shape}?")
    for c in COLORS_F:                          # Угадай-ка (звезда, женский род)
        out.append(f"Где {c} {SHAPE_FEM}?")
    return out


def fnv1a(text: str) -> str:
    """FNV-1a 64-бит по UTF-8 → 16 hex. Зеркало Voice.clipKey в Dart."""
    h = 0xCBF29CE484222325
    for b in text.encode("utf-8"):
        h = ((h ^ b) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return f"{h:016x}"


_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(_ROOT, "assets", "voice", "pack")


def _synth(model, voice: str, text: str, path: str) -> None:
    audio = model.apply_tts(
        text=text, speaker=voice, sample_rate=SAMPLE_RATE,
        put_accent=True, put_yo=True,
    )
    sf.write(path, audio.numpy(), SAMPLE_RATE)


def main() -> None:
    torch.set_num_threads(4)
    comp = compositional_phrases()
    print(f"Голоса: {', '.join(VOICES)}. Фраз: {len(PHRASES)} фикс + "
          f"{len(comp)} композ. Загружаю Silero v4_ru…")
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
        for old in glob.glob(os.path.join(vdir, "*.wav")):  # без сирот
            os.remove(old)
        for key, text in PHRASES.items():
            _synth(model, voice, text, os.path.join(vdir, f"{key}.wav"))
        ok = 0
        for text in comp:
            try:
                _synth(model, voice, text, os.path.join(vdir, f"{fnv1a(text)}.wav"))
                ok += 1
            except Exception as e:  # одна плохая фраза не валит весь прогон
                print(f"    ! пропуск «{text}»: {e}")
        print(f"  готово: {voice} ({len(PHRASES)} фикс + {ok} композ)")

    print(f"\nГотово → {OUT}/<voice>/  (голоса: {', '.join(VOICES)})")
    print("Композиционные фразы — имя файла = FNV-1a хеш (Voice.clipKey).")


if __name__ == "__main__":
    main()
