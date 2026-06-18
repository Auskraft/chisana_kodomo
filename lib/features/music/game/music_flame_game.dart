import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/sfx.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/music_logic.dart';

/// Фаза экрана «Музыка». Это свободная игра-инструмент — без раундов/звёзд:
/// только готовность и игра.
enum MusicPhase { ready, playing }

/// Радужные цвета пластин (по индексу ноты). Это «личность» инструмента —
/// хардкод-палитра, как [kShapeColors] у фигур (не из темы).
const List<Color> kBarColors = <Color>[
  Color(0xFFE53935), // до — красный
  Color(0xFFFB8C00), // ре — оранжевый
  Color(0xFFFDD835), // ми — жёлтый
  Color(0xFF7CB342), // фа — зелёный
  Color(0xFF26A69A), // соль — бирюзовый
  Color(0xFF42A5F5), // ля — синий
  Color(0xFF5C6BC0), // си — индиго
  Color(0xFFAB47BC), // до² — фиолетовый
];

/// Flame-инструмент «Ксилофон»: 8 цветных пластин «лесенкой» (низкая нота —
/// широкая, внизу). Тап → отскок + вспышка + вибро. **Без проигрышей.**
///
/// Звук ноты — Фаза 5 (процедурный тон по [Xylophone.frequency]); сейчас
/// отклик визуально-тактильный.
class MusicGame extends FlameGame {
  MusicGame({required this.colors, this.onNote});

  final AppColors colors;

  /// Хук на сыгранную ноту (Фаза 5 подключит синтез тона). Может быть null.
  final void Function(XyloNote note)? onNote;

  final ValueNotifier<MusicPhase> phase =
      ValueNotifier<MusicPhase>(MusicPhase.ready);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);

  bool get _active => phase.value == MusicPhase.playing && !isPaused.value;

  @override
  Color backgroundColor() => colors.background;

  void start() {
    phase.value = MusicPhase.playing;
    isPaused.value = false;
    paused = false;
    _buildKeyboard();
  }

  void togglePause() {
    if (phase.value != MusicPhase.playing) return;
    isPaused.value = !isPaused.value;
    paused = isPaused.value;
  }

  void resume() {
    if (!isPaused.value) return;
    isPaused.value = false;
    paused = false;
  }

  /// Тап по пластине (зовётся компонентом пластины).
  void onBarHit(XyloNote note) {
    if (!_active) return;
    Sfx.play(SfxEvent.tap);
    Haptics.tap();
    // Тон ноты играет хост (music_game_screen) через onNote → notes/note_N.wav.
    onNote?.call(note);
  }

  void _buildKeyboard() {
    for (final c in children.whereType<_Keyboard>().toList()) {
      c.removeFromParent();
    }
    add(_Keyboard(owner: this));
  }
}

/// Раскладка пластин: лесенка долями от экрана; перестраивается при ресайзе.
class _Keyboard extends PositionComponent {
  _Keyboard({required this.owner});

  final MusicGame owner;

  @override
  Future<void> onLoad() async => _layout();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isMounted) _layout();
  }

  void _layout() {
    for (final c in children.toList()) {
      c.removeFromParent();
    }
    final s = owner.size;
    final notes = Xylophone.cMajor;
    final count = notes.length;

    final topPad = s.y * 0.1;
    final bottomPad = s.y * 0.04;
    final areaH = s.y - topPad - bottomPad;
    final slot = areaH / count;
    final barH = slot * 0.82;
    final maxW = s.x * 0.88;
    final minW = s.x * 0.5;

    for (var row = 0; row < count; row++) {
      // Сверху — высокие ноты (узкие), снизу — низкие (широкие).
      final noteIndex = count - 1 - row;
      final note = notes[noteIndex];
      final w = maxW - (maxW - minW) * (noteIndex / (count - 1));
      final cy = topPad + slot * row + slot / 2;
      add(_Bar(
        note: note,
        color: kBarColors[noteIndex % kBarColors.length],
        barSize: Vector2(w, barH),
        position: Vector2(s.x / 2, cy),
        onHit: owner.onBarHit,
      ));
    }
  }
}

/// Одна пластина. Вспышка реализована затухающим коэффициентом [_lit].
class _Bar extends PositionComponent with TapCallbacks {
  _Bar({
    required this.note,
    required this.color,
    required Vector2 barSize,
    required Vector2 position,
    required this.onHit,
  }) : super(size: barSize, anchor: Anchor.center, position: position);

  final XyloNote note;
  final Color color;
  final void Function(XyloNote note) onHit;

  double _lit = 0;

  @override
  void update(double dt) {
    if (_lit > 0) _lit = math.max(0, _lit - dt * 4);
  }

  @override
  void render(Canvas canvas) {
    final col = Color.lerp(color, Colors.white, _lit * 0.55)!;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.y * 0.4),
    );
    canvas.drawRRect(r, Paint()..color = col);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _lit = 1.0;
    add(ScaleEffect.to(
      Vector2(1.0, 1.08),
      EffectController(duration: 0.08, alternate: true),
    ));
    onHit(note);
  }
}
