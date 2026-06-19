# Озвучка — выбор голоса

Цель: уйти от «робота» системного TTS к приятному голосу. Набор фраз маленький и
фиксированный (числа 0–10, похвала, подсказки), поэтому генерим клипы заранее и
бандлим. **Готово:** 3 женских голоса (baya/kseniya/xenia) в
`assets/voice/pack/<voice>/`, пользователь выбирает в Настройках → «Голос
помощника». Ниже — как переслушать варианты и перегенерировать.

## Вариант A — Silero (рекомендую: бесплатно, офлайн, чистая лицензия, 5 голосов)
```bash
pip install torch soundfile numpy omegaconf
python tool/gen_voice_samples.py
```
→ `tool/voice_samples/<voice>/*.wav` для голосов: **baya, kseniya, xenia** (жен.),
**aidar, eugene** (муж.). Послушай папки, выбери — скажи какой.

## Вариант B — edge-tts (быстро послушать, 2 голоса; лицензия для релиза мутная)
```bash
pip install edge-tts
edge-tts --voice ru-RU-SvetlanaNeural --text "Привет! Давай посчитаем! Один, два, три. Молодец!" --write-media svetlana.mp3
edge-tts --voice ru-RU-DmitryNeural   --text "Привет! Давай посчитаем! Один, два, три. Молодец!" --write-media dmitry.mp3
```
Звучит отлично, но для **публикации** в сторе лучше Silero/Piper (чистая лицензия).

## Паки (сгенерированы)
В `assets/voice/pack/<voice>/` лежат **3 женских пака** (baya/kseniya/xenia, по
26 клипов). Пользователь выбирает голос в **Настройках → «Голос помощника»**
(встроенные голоса; фолбэк на системный TTS). Перегенерировать / поменять состав:
1. правь список `VOICES` в `tool/gen_voice_pack.py` (и `Voice.packVoices` в
   `lib/core/voice/voice.dart`, если меняешь набор голосов),
2. `pip install torch soundfile numpy omegaconf` → `python tool/gen_voice_pack.py`
   → клипы лягут в `assets/voice/pack/<voice>/`,
3. пересобери.

> `tool/voice_samples/` в сборку НЕ идёт (только послушать). А
> `assets/voice/pack/<voice>/` — идёт (готовые паки для приложения).
