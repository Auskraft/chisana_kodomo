Встроенный («офлайн») голос помощника — клипы по подпапке на каждый голос:

  assets/voice/pack/<voice>/<key>.mp3     (voice: baya / kseniya / xenia)

Два вида имён <key>:
  • фиксированные фразы — семантический ключ (num_3, praise_0, greet… = карта
    _clipKeys в lib/core/voice/voice.dart);
  • композиционные фразы (с переменной: «Где собачка?», «Это цифра три!») — имя
    файла = FNV-1a хеш текста (Voice.clipKey ↔ fnv1a в tool/gen_voice_pack.py).

Сборка пака (два шага):
  python tool/gen_voice_pack.py     # Silero синтез → .wav (фикс + ~178 композ)
  python tool/compress_voice.py     # .wav → .mp3 (64k mono, ~10× меньше)

Голоса — Voice.packVoices. В Настройках → «Голос помощника» пользователь выбирает
встроенный голос; нет клипа на фразу — фолбэк на системный TTS (офлайн, без Google).
Бандлятся подпапки <voice>/ (pubspec.yaml). Сам README в сборку не идёт.
