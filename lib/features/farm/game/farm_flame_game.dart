import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/sfx.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../animals/logic/animals_logic.dart';

/// Фаза «Фермы». Свободная игра-игрушка — без раундов/звёзд.
enum FarmPhase { ready, playing }

/// Flame-«Ферма» / «Кто как говорит?»: сетка зверей; тап по зверю → отскок +
/// голос произносит звукоподражание (`Animal.says`, работает офлайн через TTS)
/// + звук-файл (`assets/animals/<key>.wav`, когда есть). **Без проигрышей.**
class FarmGame extends FlameGame {
  FarmGame({required this.colors, this.onAnimal});

  final AppColors colors;

  /// Тап по зверю — хост сам решает звук: реальный CC0-файл
  /// `assets/animals/<soundKey>.wav`, а пока его нет — имя зверя голосом.
  final void Function(Animal animal)? onAnimal;

  final ValueNotifier<FarmPhase> phase = ValueNotifier<FarmPhase>(FarmPhase.ready);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);

  bool get _active => phase.value == FarmPhase.playing && !isPaused.value;

  @override
  Color backgroundColor() => colors.background;

  void start() {
    phase.value = FarmPhase.playing;
    isPaused.value = false;
    paused = false;
    _build();
  }

  void togglePause() {
    if (phase.value != FarmPhase.playing) return;
    isPaused.value = !isPaused.value;
    paused = isPaused.value;
  }

  void resume() {
    if (!isPaused.value) return;
    isPaused.value = false;
    paused = false;
  }

  /// Тап по зверю (зовётся компонентом).
  void onAnimalTap(Animal a) {
    if (!_active) return;
    Sfx.play(SfxEvent.tap);
    Haptics.tap();
    onAnimal?.call(a);
  }

  void _build() {
    for (final c in children.whereType<_FarmBoard>().toList()) {
      c.removeFromParent();
    }
    add(_FarmBoard(owner: this));
  }
}

/// Сетка зверей долями от экрана; неполный последний ряд центрируется.
class _FarmBoard extends PositionComponent {
  _FarmBoard({required this.owner});

  final FarmGame owner;

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
    final animals = Animals.all;
    final n = animals.length;
    const cols = 3;
    final rows = (n / cols).ceil();

    final topPad = s.y * 0.12;
    final cellW = (s.x * 0.92) / cols;
    final cellH = (s.y * 0.8) / rows;
    final side = (min(cellW, cellH) * 0.9).clamp(48.0, 130.0).toDouble();

    for (var i = 0; i < n; i++) {
      final r = i ~/ cols;
      final colInRow = i % cols;
      final rowCount = (r == rows - 1) ? (n - cols * (rows - 1)) : cols;
      final rowW = rowCount * cellW;
      final cx = (s.x - rowW) / 2 + cellW * colInRow + cellW / 2;
      final cy = topPad + cellH * r + cellH / 2;
      add(_AnimalToy(
        animal: animals[i],
        side: side,
        position: Vector2(cx, cy),
        onTap: owner.onAnimalTap,
      ));
    }
  }
}

/// Зверь-кнопка: эмодзи; тап — отскок + колбэк.
class _AnimalToy extends PositionComponent with TapCallbacks {
  _AnimalToy({
    required this.animal,
    required double side,
    required Vector2 position,
    required this.onTap,
  }) : super(size: Vector2.all(side), anchor: Anchor.center, position: position);

  final Animal animal;
  final void Function(Animal animal) onTap;
  late final TextPaint _emoji;

  @override
  Future<void> onLoad() async {
    _emoji = TextPaint(style: TextStyle(fontSize: size.x * 0.7));
  }

  @override
  void render(Canvas canvas) {
    _emoji.render(canvas, animal.emoji, Vector2(size.x / 2, size.y / 2), anchor: Anchor.center);
  }

  @override
  void onTapDown(TapDownEvent event) {
    add(ScaleEffect.to(
      Vector2.all(1.18),
      EffectController(duration: 0.12, alternate: true),
    ));
    onTap(animal);
  }
}
