import 'dart:io' show Platform;

import 'package:flutter_tts/flutter_tts.dart';

/// Голосовые подсказки и похвала через системный TTS (`flutter_tts`).
///
/// Русская речь (`ru-RU`), чуть медленнее — под малышей (дети не читают, поэтому
/// озвучка важнее текста). **Безопасно без платформы/голоса:** под тестами и при
/// любой ошибке инициализации/синтеза всё глушится — приложение просто молчит и
/// не падает. Флаг [enabled] синхронизируется с настройкой голоса в `GameStorage`.
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  /// Под `flutter test` платформы TTS нет — не трогаем её вовсе.
  static final bool _inTest = Platform.environment.containsKey('FLUTTER_TEST');

  FlutterTts? _tts;
  bool enabled = true;

  /// Инициализация (вызывать из `main()` после `GameStorage.init()`).
  Future<void> init() async {
    if (_inTest || _tts != null) return;
    try {
      final t = FlutterTts();
      await t.setLanguage('ru-RU');
      await t.setSpeechRate(0.45); // чуть медленнее, по-детски
      await t.setPitch(1.25); // повыше — дружелюбнее, меньше «робота»
      await t.setVolume(1.0);
      _tts = t;
    } catch (_) {
      _tts = null; // нет движка/голоса — будем молчать
    }
  }

  /// Произнести фразу, прервав предыдущую. Тихо, если голос выключен/недоступен.
  Future<void> say(String text) async {
    if (!enabled || _inTest) return;
    final t = _tts;
    if (t == null) return;
    try {
      await t.stop();
      await t.speak(text);
    } catch (_) {
      // движок недоступен — молчим
    }
  }

  /// Остановить текущую речь.
  Future<void> stop() async {
    final t = _tts;
    if (t == null) return;
    try {
      await t.stop();
    } catch (_) {
      // молчим
    }
  }
}
