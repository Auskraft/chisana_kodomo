import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_tts/flutter_tts.dart';

/// Голосовые подсказки и похвала через системный TTS (`flutter_tts`).
///
/// Русская речь (`ru-RU`), чуть медленнее — под малышей. **Очередь фраз:**
/// по умолчанию фразы проигрываются последовательно и НЕ перебивают друг друга
/// (число → похвала → подсказка). `flush: true` — прервать текущее и сказать
/// сразу (счёт по тапу, «попробуй ещё»). **Безопасно без TTS/в тестах** — молчит.
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
  Future<void> init() async {
    if (_inTest || _tts != null) return;
    try {
      final t = FlutterTts();
      await t.awaitSpeakCompletion(true); // speak() завершится по окончании фразы
      await t.setLanguage('ru-RU');
      await t.setSpeechRate(0.45); // чуть медленнее, по-детски
      await t.setPitch(1.25); // повыше — дружелюбнее
      await t.setVolume(1.0);
      _tts = t;
    } catch (_) {
      _tts = null; // нет движка/голоса — будем молчать
    }
  }

  /// Произнести фразу. [flush]=false (по умолчанию) — в очередь, без перебивания;
  /// [flush]=true — прервать текущее и очередь, сказать сразу.
  Future<void> say(String text, {bool flush = false}) async {
    if (!enabled || _inTest) return;
    final t = _tts;
    if (t == null) return;
    if (flush) {
      _queue.clear();
      try {
        await t.stop();
      } catch (_) {}
    }
    _queue.add(text);
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
