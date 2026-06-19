Встроенный («офлайн») голос помощника — клипы по подпапке на каждый голос:

  assets/voice/pack/<voice>/<key>.wav     (voice: baya / kseniya / xenia)

Генерит tool/gen_voice_pack.py (Silero v4_ru, список VOICES). Ключи/фразы (<key>)
совпадают с картой _clipKeys в lib/core/voice/voice.dart, а набор голосов — с
Voice.packVoices. В Настройках → «Голос помощника» пользователь выбирает
встроенный голос; пока клипов нет — фолбэк на системный TTS (офлайн, без Google).

Бандлятся именно подпапки <voice>/ (см. pubspec.yaml). Сам этот README в сборку
не идёт — это заметка для разработки.
