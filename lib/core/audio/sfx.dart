import 'dart:async';

import 'sound_pool.dart';

/// Короткие звуковые события (детский набор). Имя — событие, не файл.
enum SfxEvent {
  /// Касание объекта/кнопки.
  tap,

  /// Правильно — мягкий радостный «дзынь».
  correct,

  /// Не то — нейтральный мягкий «пуф» (без негатива, «попробуй ещё»).
  soft,

  /// Получена звезда.
  star,

  /// Набор пройден — маленький фанфар.
  complete,

  /// Старт игры.
  start,
}

/// Фасад звуковых эффектов: играет процедурные клипы `assets/sfx/<event>.wav`
/// (сгенерированы `tool/gen_sfx.py`) через полифонический [SoundPool].
///
/// Контракт [SfxEvent] стабилен — игровой слой зовёт [play] как раньше. Флаг
/// [enabled] синхронизируется с настройкой звука в `GameStorage`. Нет файла или
/// аудио (в т.ч. в тестах) — тихий фолбэк.
class Sfx {
  const Sfx._();

  static bool enabled = true;

  static final SoundPool _pool = SoundPool(size: 5);

  static const Map<SfxEvent, String> _files = <SfxEvent, String>{
    SfxEvent.tap: 'sfx/tap.wav',
    SfxEvent.correct: 'sfx/correct.wav',
    SfxEvent.soft: 'sfx/soft.wav',
    SfxEvent.star: 'sfx/star.wav',
    SfxEvent.complete: 'sfx/complete.wav',
    SfxEvent.start: 'sfx/start.wav',
  };

  /// Сыграть эффект [event] (если звук включён).
  static void play(SfxEvent event) {
    if (!enabled) return;
    final file = _files[event];
    if (file != null) unawaited(_pool.play(file));
  }
}
