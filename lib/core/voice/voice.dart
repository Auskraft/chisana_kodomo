import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

/// Один доступный системный голос (для выбора в настройках).
class VoiceOption {
  const VoiceOption({required this.name, required this.locale});

  /// Имя голоса в движке (id для `setVoice`).
  final String name;

  /// Локаль голоса (напр. `ru-RU`).
  final String locale;
}

/// Встроенный (офлайн) голос: id спикера Silero + ярлык/эмодзи для Настроек.
/// Список должен совпадать с `VOICES` в `tool/gen_voice_pack.py` и папками
/// `assets/voice/pack/<id>/`.
class PackVoice {
  const PackVoice(this.id, this.label, this.emoji);
  final String id;
  final String label;
  final String emoji;
}

/// Голос помощника: произносит фиксированный набор фраз (числа, похвала,
/// подсказки) одним из двух способов:
/// - **встроенный пак** (`usePack`) — заранее озвученные клипы `assets/voice/pack/`
///   (офлайн, одинаково у всех, без Google) — играются через [AudioPlayer];
/// - **системный TTS** (`flutter_tts`) — голос телефона (можно выбрать получше).
///
/// Фразы идут **очередью** и не перебивают друг друга; `flush: true` — сказать
/// сразу (счёт/ошибка). Если клипа нет — мягкий фолбэк на TTS. **В тестах/без
/// движка — молчит.**
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  static final bool _inTest = Platform.environment.containsKey('FLUTTER_TEST');

  FlutterTts? _tts;
  AudioPlayer? _clip;
  bool enabled = true;

  /// Использовать встроенный пак клипов вместо системного TTS.
  bool usePack = false;

  /// Голос по умолчанию, если ничего не сохранено.
  static const String defaultPackVoice = 'baya';

  /// Встроенные голоса для выбора пользователем (женские Silero v4_ru).
  /// Должен совпадать с `VOICES` в `tool/gen_voice_pack.py`.
  static const List<PackVoice> packVoices = <PackVoice>[
    PackVoice('baya', 'Марина', '🦊'),
    PackVoice('kseniya', 'Ольга', '🐰'),
    PackVoice('xenia', 'Маша', '🐱'),
  ];

  /// Системные (онлайн) голоса телефона, которые показываем в Настройках, →
  /// человеческое имя. Ключ — имя голоса движка в нижнем регистре. Остальные
  /// ru-голоса прячем. Это сетевые голоса Google (нужен интернет).
  static const Map<String, String> systemVoiceLabels = <String, String>{
    'ru-ru-x-ruf-network': 'Артём',
    'ru-ru-x-ruc-network': 'Светлана',
  };

  /// Какой встроенный голос играть (папка `assets/voice/pack/<packVoice>/`).
  String packVoice = defaultPackVoice;

  final List<String> _queue = <String>[];
  bool _draining = false;
  final Map<String, bool> _clipReadyCache = <String, bool>{};

  /// Текст фразы → имя файла клипа (`assets/voice/pack/<voice>/<key>.wav`). Должен
  /// совпадать с тем, что произносят игры (см. `_numberWord`, `Praise.phrases`).
  static const Map<String, String> _clipKeys = <String, String>{
    'ноль': 'num_0',
    'один': 'num_1',
    'два': 'num_2',
    'три': 'num_3',
    'четыре': 'num_4',
    'пять': 'num_5',
    'шесть': 'num_6',
    'семь': 'num_7',
    'восемь': 'num_8',
    'девять': 'num_9',
    'десять': 'num_10',
    'Молодец!': 'praise_0',
    'Умница!': 'praise_1',
    'Здорово!': 'praise_2',
    'Верно!': 'praise_3',
    'Супер!': 'praise_4',
    'Класс!': 'praise_5',
    'Получилось!': 'praise_6',
    'Отлично!': 'praise_7',
    'Посчитай!': 'prompt_count',
    'Сколько?': 'prompt_howmany',
    'Попробуй ещё': 'try_again',
    'Найди пару!': 'prompt_pairs',
    'Найди лишнее!': 'prompt_odd',
    'Собери картинку!': 'prompt_puzzles',
    'Готово! Красиво!': 'coloring_done',
    'Молодец! Ты справился!': 'set_done',
    'Молодец! Ты справилась!': 'set_done_girl',
    'Молодец! Всё получилось!': 'set_done_neutral',
    'Привет! Давай посчитаем!': 'greet',
  };

  /// Инициализация (вызывать из `main()` после `GameStorage.init()`).
  Future<void> init({
    String? voiceName,
    String? voiceLocale,
    bool usePack = false,
    String? packVoice,
  }) async {
    this.usePack = usePack;
    if (packVoice != null && packVoice.isNotEmpty) this.packVoice = packVoice;
    if (_inTest || _tts != null) return;
    try {
      final t = FlutterTts();
      await t.awaitSpeakCompletion(true);
      await t.setLanguage('ru-RU');
      await t.setSpeechRate(0.45);
      await t.setPitch(1.25);
      await t.setVolume(1.0);
      _tts = t;
      if (voiceName != null && voiceName.isNotEmpty) {
        await applyVoice(voiceName, voiceLocale ?? 'ru-RU');
      }
    } catch (_) {
      _tts = null;
    }
  }

  void setUsePack(bool value) => usePack = value;

  /// Сменить встроенный голос (папку клипов). Чистим кэш готовности клипов —
  /// у разных голосов свои файлы.
  void setPackVoice(String id) {
    if (id.isEmpty || id == packVoice) return;
    packVoice = id;
    _clipReadyCache.clear();
  }

  /// Доступные русские голоса устройства (для экрана настроек).
  Future<List<VoiceOption>> russianVoices() async {
    final t = _tts;
    if (t == null) return const <VoiceOption>[];
    try {
      final raw = await t.getVoices;
      final seen = <String>{};
      final out = <VoiceOption>[];
      if (raw is List) {
        for (final v in raw) {
          if (v is Map) {
            final name = (v['name'] ?? '').toString();
            final locale = (v['locale'] ?? '').toString();
            if (name.isNotEmpty &&
                locale.toLowerCase().startsWith('ru') &&
                seen.add(name)) {
              out.add(VoiceOption(name: name, locale: locale));
            }
          }
        }
      }
      return out;
    } catch (_) {
      return const <VoiceOption>[];
    }
  }

  Future<void> applyVoice(String name, String locale) async {
    final t = _tts;
    if (t == null) return;
    try {
      await t.setVoice(<String, String>{'name': name, 'locale': locale});
    } catch (_) {}
  }

  /// Произнести фразу. [flush]=false — в очередь, без перебивания; [flush]=true —
  /// прервать текущее и сказать сразу.
  Future<void> say(String text, {bool flush = false}) async {
    if (!enabled || _inTest) return;
    if (flush) {
      _queue
        ..clear()
        ..add(text);
      await _stopCurrent();
    } else {
      _queue.add(text);
    }
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        final text = _queue.removeAt(0);
        final key = usePack ? _clipKeys[text.trim()] : null;
        if (key != null && await _clipReady(key)) {
          await _playClip(key);
        } else {
          final t = _tts;
          if (t == null) break;
          try {
            await t.speak(text);
          } catch (_) {}
        }
      }
    } finally {
      _draining = false;
    }
  }

  /// Есть ли клип в бандле (с кэшем, чтобы не грузить повторно).
  Future<bool> _clipReady(String key) async {
    final cached = _clipReadyCache[key];
    if (cached != null) return cached;
    var ok = false;
    try {
      await rootBundle.load('assets/voice/pack/$packVoice/$key.wav');
      ok = true;
    } catch (_) {
      ok = false;
    }
    _clipReadyCache[key] = ok;
    return ok;
  }

  Future<void> _playClip(String key) async {
    final p = _clip ??= AudioPlayer();
    final done = Completer<void>();
    StreamSubscription<void>? sub;
    try {
      sub = p.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      });
      await p.stop();
      await p.play(AssetSource('voice/pack/$packVoice/$key.wav'));
      await done.future.timeout(const Duration(seconds: 5), onTimeout: () {});
    } catch (_) {
      // не удалось — тихо (фолбэк уже не нужен, фраза пропускается)
    } finally {
      await sub?.cancel();
    }
  }

  Future<void> _stopCurrent() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    try {
      await _clip?.stop();
    } catch (_) {}
  }

  /// Остановить речь и очистить очередь.
  Future<void> stop() async {
    _queue.clear();
    await _stopCurrent();
  }
}
