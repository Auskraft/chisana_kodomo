import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';

/// Небольшой полифонический проигрыватель ассет-звуков (round-robin пул
/// [AudioPlayer]) для коротких частых эффектов: SFX-события, ноты ксилофона,
/// звуки животных. Путь — относительно `assets/` (как у [AssetSource]).
///
/// Лениво создаёт плееры при первом [play]; ошибки (нет файла/движка) гасит
/// тихо. **В тестах молчит** (нет платформенного аудио).
class SoundPool {
  SoundPool({this.size = 4});

  final int size;
  static final bool _inTest = Platform.environment.containsKey('FLUTTER_TEST');

  final List<AudioPlayer> _players = <AudioPlayer>[];
  int _next = 0;
  bool _ready = false;

  Future<void> _ensure() async {
    if (_ready) return;
    _ready = true;
    for (var i = 0; i < size; i++) {
      final p = AudioPlayer();
      try {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
      } catch (_) {}
      _players.add(p);
    }
  }

  /// Сыграть ассет (например `'sfx/tap.wav'`) на следующем плеере пула.
  Future<void> play(String asset) async {
    if (_inTest) return;
    await _ensure();
    if (_players.isEmpty) return;
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    try {
      await p.stop();
      await p.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final p in _players) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _players.clear();
    _ready = false;
  }
}
