import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_tts/flutter_tts.dart';

/// Один доступный системный голос (для выбора в настройках).
class VoiceOption {
  const VoiceOption({required this.name, required this.locale});

  /// Имя голоса в движке (id для `setVoice`).
  final String name;

  /// Локаль голоса (напр. `ru-RU`).
  final String locale;
}

/// Голосовые подсказки и похвала через системный TTS (`flutter_tts`).
///
/// Русская речь (`ru-RU`), чуть медленнее — под малышей. **Очередь фраз:** по
/// умолчанию фразы идут последовательно и НЕ перебивают друг друга (число →
/// похвала → подсказка); `flush: true` — прервать и сказать сразу (счёт по тапу,
/// «попробуй ещё»). Голос выбирается в настройках ([russianVoices]/[applyVoice]).
/// **Безопасно без TTS/в тестах** — молчит.
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  /// Под `flutter test` платформы TTS нет — не трогаем её вовсе.
  static final bool _inTest = Platform.environment.containsKey('FLUTTER_TEST');

  FlutterTts? _tts;
  bool enabled = true;

  final List<String> _queue = <String>[];
  bool _draining = false;

  /// Инициализация (вызывать из `main()` после `GameStorage.init()`).
  /// Если в настройках выбран голос — применяем его.
  Future<void> init({String? voiceName, String? voiceLocale}) async {
    if (_inTest || _tts != null) return;
    try {
      final t = FlutterTts();
      await t.awaitSpeakCompletion(true); // speak() завершится по окончании фразы
      await t.setLanguage('ru-RU');
      await t.setSpeechRate(0.45); // чуть медленнее, по-детски
      await t.setPitch(1.25); // повыше — дружелюбнее
      await t.setVolume(1.0);
      _tts = t;
      if (voiceName != null && voiceName.isNotEmpty) {
        await applyVoice(voiceName, voiceLocale ?? 'ru-RU');
      }
    } catch (_) {
      _tts = null; // нет движка/голоса — будем молчать
    }
  }

  /// Доступные русские голоса устройства (для экрана настроек). Пусто, если
  /// TTS недоступен или русских голосов не установлено.
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

  /// Применить выбранный голос (без персиста — это делает настройки/GameStorage).
  Future<void> applyVoice(String name, String locale) async {
    final t = _tts;
    if (t == null) return;
    try {
      await t.setVoice(<String, String>{'name': name, 'locale': locale});
    } catch (_) {}
  }

  /// Произнести фразу. [flush]=false (по умолчанию) — в очередь, без перебивания;
  /// [flush]=true — прервать текущее и очередь, сказать сразу.
  Future<void> say(String text, {bool flush = false}) async {
    if (!enabled || _inTest) return;
    final t = _tts;
    if (t == null) return;
    if (flush) {
      // Кладём фразу в очередь ДО `await stop()` — иначе следующий say() успеет
      // вклиниться в окно ожидания и проиграться первым (баг «похвала раньше числа»).
      _queue
        ..clear()
        ..add(text);
      try {
        await t.stop();
      } catch (_) {}
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
        final t = _tts;
        if (t == null) break;
        final next = _queue.removeAt(0);
        try {
          await t.speak(next); // ждёт окончания (awaitSpeakCompletion)
        } catch (_) {}
      }
    } finally {
      _draining = false;
    }
  }

  /// Остановить речь и очистить очередь.
  Future<void> stop() async {
    _queue.clear();
    final t = _tts;
    if (t == null) return;
    try {
      await t.stop();
    } catch (_) {}
  }
}
