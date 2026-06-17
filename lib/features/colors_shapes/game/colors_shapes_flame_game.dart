import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/sfx.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/praise/praise.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/colors_shapes_logic.dart';

/// Палитра фигур (порядок совпадает с [kColorNameM]/[kColorNameF]).
const List<Color> kShapeColors = <Color>[
  Color(0xFFE53935), // красный
  Color(0xFFFFC107), // жёлтый
  Color(0xFF42A5F5), // синий
  Color(0xFF66BB6A), // зелёный
  Color(0xFFFF8A5B), // оранжевый
  Color(0xFF9C6ADE), // фиолетовый
];

/// Нарисовать фигуру [kind] цветом [paint] с центром [center] и «радиусом».
void drawShape(
  Canvas canvas,
  ShapeKind kind,
  Offset center,
  double radius,
  Paint paint,
) {
  switch (kind) {
    case ShapeKind.circle:
      canvas.drawCircle(center, radius, paint);
    case ShapeKind.square:
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 1.7,
        height: radius * 1.7,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius * 0.28)),
        paint,
      );
    case ShapeKind.triangle:
      final path = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius * 0.92, center.dy + radius * 0.78)
        ..lineTo(center.dx - radius * 0.92, center.dy + radius * 0.78)
        ..close();
      canvas.drawPath(path, paint);
    case ShapeKind.star:
      final path = Path();
      const points = 5;
      final rIn = radius * 0.45;
      for (var i = 0; i < points * 2; i++) {
        final rr = i.isEven ? radius : rIn;
        final a = -pi / 2 + i * pi / points;
        final p = Offset(center.dx + rr * cos(a), center.dy + rr * sin(a));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
  }
}

/// Фаза экрана игры «Цвета и формы».
enum CSPhase { ready, playing, setDone }

/// Flame-игра «Цвета и формы»: показывает цель и варианты-фигуры; малыш тапает
/// такую же. «Сок» и пауза — как в «Счёте». «Без проигрышей».
class ColorsShapesGame extends FlameGame {
  ColorsShapesGame({
    required this.set,
    required this.colors,
    this.roundsPerSet = 5,
    this.onSay,
    Random? random,
  }) : _rng = random ?? Random();

  final CSSet set;
  final AppColors colors;
  final int roundsPerSet;
  final void Function(String text, {bool flush})? onSay;
  final Random _rng;

  late final CSSession _session;
  int _mistakes = 0;
  bool _locked = false;

  final ValueNotifier<CSPhase> phase = ValueNotifier<CSPhase>(CSPhase.ready);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
  final ValueNotifier<int> roundNumber = ValueNotifier<int>(1);
  final ValueNotifier<int> earnedStars = ValueNotifier<int>(0);

  bool get _active => phase.value == CSPhase.playing && !isPaused.value;

  @override
  Color backgroundColor() => colors.background;

  @override
  Future<void> onLoad() async {
    _session = CSSession(set, random: _rng);
  }

  void start() {
    _mistakes = 0;
    _locked = false;
    roundNumber.value = 1;
    phase.value = CSPhase.playing;
    isPaused.value = false;
    paused = false;
    _buildRound();
  }

  void togglePause() {
    if (phase.value != CSPhase.playing) return;
    isPaused.value = !isPaused.value;
    paused = isPaused.value;
  }

  void resume() {
    if (!isPaused.value) return;
    isPaused.value = false;
    paused = false;
  }

  /// Тап по варианту. true — верно (иначе плитка трясётся сама).
  bool onChoose(int index) {
    if (!_active || _locked) return true;
    if (_session.choose(index).isCorrect) {
      _solveRound();
      return true;
    }
    _mistakes++;
    Sfx.play(SfxEvent.soft);
    onSay?.call('Попробуй ещё', flush: true);
    return false;
  }

  void _buildRound() {
    _locked = false;
    _clearRound();
    add(_Board(owner: this, round: _session.round));
    onSay?.call(
      'Где ${csItemName(_session.round.target)}?',
      flush: roundNumber.value == 1,
    );
  }

  void _solveRound() {
    _locked = true;
    Sfx.play(SfxEvent.correct);
    Haptics.success();
    _burst(Vector2(size.x / 2, size.y * 0.34));
    if (roundNumber.value < roundsPerSet) {
      onSay?.call(Praise.pick(_rng));
    }
    add(TimerComponent(period: 1.6, removeOnFinish: true, onTick: _advance));
  }

  void _advance() {
    if (roundNumber.value >= roundsPerSet) {
      _finishSet();
    } else {
      roundNumber.value += 1;
      _session.nextRound();
      _buildRound();
    }
  }

  void _finishSet() {
    _clearRound();
    earnedStars.value = Praise.starsForMistakes(_mistakes);
    Sfx.play(SfxEvent.complete);
    onSay?.call('Молодец! Ты справился!');
    phase.value = CSPhase.setDone;
  }

  void _clearRound() {
    for (final c in children.whereType<_Board>().toList()) {
      c.removeFromParent();
    }
  }

  void _burst(Vector2 at) {
    final palette = <Color>[colors.accent, colors.primary, colors.secondary, colors.success];
    final particle = Particle.generate(
      count: 24,
      generator: (int i) {
        final angle = _rng.nextDouble() * pi * 2;
        final speed = 90 + _rng.nextDouble() * 170;
        return AcceleratedParticle(
          acceleration: Vector2(0, 260),
          speed: Vector2(cos(angle), sin(angle)) * speed,
          lifespan: 0.9,
          child: CircleParticle(
            radius: 3 + _rng.nextDouble() * 3,
            paint: Paint()..color = palette[i % palette.length],
          ),
        );
      },
    );
    add(ParticleSystemComponent(particle: particle, position: at));
  }
}

/// Контейнер раунда: цель сверху + ряд вариантов. Раскладка — доли от экрана.
class _Board extends PositionComponent {
  _Board({required this.owner, required this.round});

  final ColorsShapesGame owner;
  final CSRound round;

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

    // Цель — по центру верхней трети.
    final shortest = min(s.x, s.y);
    final targetSize = (shortest * 0.34).clamp(120.0, 240.0).toDouble();
    add(_TargetCard(
      item: round.target,
      colors: owner.colors,
      cardSize: targetSize,
      position: Vector2(s.x / 2, s.y * 0.26),
    ));

    // Варианты — ряд по центру нижней половины.
    final n = round.options.length;
    final tile = (s.x * 0.86 / n).clamp(60.0, 150.0).toDouble();
    final gap = tile * 0.22;
    final totalW = n * tile + (n - 1) * gap;
    final startX = (s.x - totalW) / 2 + tile / 2;
    final y = s.y * 0.68;
    for (var i = 0; i < n; i++) {
      add(_OptionTile(
        item: round.options[i],
        index: i,
        colors: owner.colors,
        tile: tile,
        position: Vector2(startX + i * (tile + gap), y),
        onChosen: owner.onChoose,
      ));
    }
  }
}

/// Карточка цели (фигура + имя).
class _TargetCard extends PositionComponent {
  _TargetCard({
    required this.item,
    required this.colors,
    required this.cardSize,
    required Vector2 position,
  }) : super(size: Vector2.all(cardSize), anchor: Anchor.center, position: position);

  final CSItem item;
  final AppColors colors;
  final double cardSize;

  @override
  Future<void> onLoad() async {
    add(TextComponent(
      text: _capitalize(csItemName(item)),
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, size.y * 0.96),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: cardSize * 0.11,
          color: colors.onSurface.withValues(alpha: 0.75),
          fontWeight: FontWeight.w700,
        ),
      ),
    ));
  }

  @override
  void render(Canvas canvas) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.22),
    );
    canvas.drawRRect(r, Paint()..color = colors.surface);
    drawShape(
      canvas,
      item.shape,
      Offset(size.x / 2, size.y * 0.42),
      size.x * 0.26,
      Paint()..color = kShapeColors[item.colorIndex],
    );
    super.render(canvas);
  }
}

/// Тап-плитка варианта (фигура на карточке).
class _OptionTile extends PositionComponent with TapCallbacks {
  _OptionTile({
    required this.item,
    required this.index,
    required this.colors,
    required this.tile,
    required Vector2 position,
    required this.onChosen,
  }) : super(size: Vector2.all(tile), anchor: Anchor.center, position: position);

  final CSItem item;
  final int index;
  final AppColors colors;
  final double tile;
  final bool Function(int index) onChosen;

  @override
  void render(Canvas canvas) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.24),
    );
    canvas.drawRRect(r, Paint()..color = colors.surface);
    drawShape(
      canvas,
      item.shape,
      Offset(size.x / 2, size.y / 2),
      size.x * 0.32,
      Paint()..color = kShapeColors[item.colorIndex],
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    add(ScaleEffect.to(
      Vector2.all(1.12),
      EffectController(duration: 0.1, alternate: true),
    ));
    if (!onChosen(index)) {
      add(MoveEffect.by(
        Vector2(10, 0),
        EffectController(duration: 0.05, alternate: true, repeatCount: 3),
      ));
    }
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
