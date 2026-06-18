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
import '../logic/odd_one_out_logic.dart';

/// Фаза экрана «Что лишнее?».
enum OddPhase { ready, playing, setDone }

/// Flame-игра «Что лишнее?»: на экране предметы, один — из другой категории;
/// малыш тапает лишний. «Сок» и пауза как у остальных квизов. «Без проигрышей».
class OddOneOutGame extends FlameGame {
  OddOneOutGame({
    required this.set,
    required this.colors,
    this.roundsPerSet = 5,
    this.onSay,
    this.setDonePhrase = 'Молодец! Всё получилось!',
    Random? random,
  }) : _rng = random ?? Random();

  final OddSet set;
  final AppColors colors;
  final int roundsPerSet;
  final void Function(String text, {bool flush})? onSay;

  /// Финальная похвала за набор (согласована по полу — задаёт хост).
  final String setDonePhrase;

  final Random _rng;

  late OddSession _session;
  bool _locked = false;

  final ValueNotifier<OddPhase> phase = ValueNotifier<OddPhase>(OddPhase.ready);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
  final ValueNotifier<int> roundNumber = ValueNotifier<int>(1);
  final ValueNotifier<int> earnedStars = ValueNotifier<int>(0);

  bool get _active => phase.value == OddPhase.playing && !isPaused.value;

  @override
  Color backgroundColor() => colors.background;

  @override
  Future<void> onLoad() async {
    _session = OddSession(set, random: _rng);
  }

  void start() {
    _session = OddSession(set, random: _rng);
    _locked = false;
    roundNumber.value = 1;
    phase.value = OddPhase.playing;
    isPaused.value = false;
    paused = false;
    _buildRound();
  }

  void togglePause() {
    if (phase.value != OddPhase.playing) return;
    isPaused.value = !isPaused.value;
    paused = isPaused.value;
  }

  void resume() {
    if (!isPaused.value) return;
    isPaused.value = false;
    paused = false;
  }

  /// Тап по предмету. true — верно (иначе плитка трясётся сама).
  bool onChoose(int index) {
    if (!_active || _locked) return true;
    if (_session.choose(index).isCorrect) {
      _solveRound();
      return true;
    }
    Sfx.play(SfxEvent.soft);
    onSay?.call('Попробуй ещё', flush: true);
    return false;
  }

  void _buildRound() {
    _locked = false;
    _clearRound();
    add(_Board(owner: this, round: _session.round));
    onSay?.call('Найди лишнее!', flush: roundNumber.value == 1);
  }

  void _solveRound() {
    _locked = true;
    Sfx.play(SfxEvent.correct);
    Haptics.success();
    _burst(Vector2(size.x / 2, size.y * 0.4));
    if (roundNumber.value < roundsPerSet) {
      onSay?.call(Praise.pick(_rng));
    }
    add(TimerComponent(period: 1.5, removeOnFinish: true, onTick: _advance));
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
    earnedStars.value = 1; // 1 звезда за пройденный уровень
    Sfx.play(SfxEvent.complete);
    onSay?.call(setDonePhrase);
    phase.value = OddPhase.setDone;
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

/// Контейнер раунда: предметы сеткой по центру; неполный ряд центрируется.
class _Board extends PositionComponent {
  _Board({required this.owner, required this.round});

  final OddOneOutGame owner;
  final OddRound round;

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
    final n = round.items.length;
    final cols = n == 4 ? 2 : (n <= 3 ? n : 3);
    final rows = (n / cols).ceil();

    final tile = (min(s.x * 0.84 / cols, s.y * 0.52 / rows))
        .clamp(64.0, 150.0)
        .toDouble();
    final gap = tile * 0.24;
    final topY = s.y * 0.28;

    for (var i = 0; i < n; i++) {
      final r = i ~/ cols;
      final colInRow = i % cols;
      final rowCount = (r == rows - 1) ? (n - cols * (rows - 1)) : cols;
      final rowW = rowCount * tile + (rowCount - 1) * gap;
      final cx = (s.x - rowW) / 2 + tile / 2 + colInRow * (tile + gap);
      final cy = topY + r * (tile + gap);
      add(_ItemTile(
        emoji: round.items[i],
        index: i,
        tile: tile,
        position: Vector2(cx, cy),
        onChosen: owner.onChoose,
      ));
    }
  }
}

/// Плитка-предмет (эмодзи). Тап → отскок; неверный — тряска.
class _ItemTile extends PositionComponent with TapCallbacks {
  _ItemTile({
    required this.emoji,
    required this.index,
    required this.tile,
    required Vector2 position,
    required this.onChosen,
  }) : super(size: Vector2.all(tile), anchor: Anchor.center, position: position);

  final String emoji;
  final int index;
  final double tile;
  final bool Function(int index) onChosen;
  late final TextPaint _paint;

  @override
  Future<void> onLoad() async {
    _paint = TextPaint(style: TextStyle(fontSize: size.x * 0.66));
  }

  @override
  void render(Canvas canvas) {
    _paint.render(canvas, emoji, Vector2(size.x / 2, size.y / 2), anchor: Anchor.center);
  }

  @override
  void onTapDown(TapDownEvent event) {
    add(ScaleEffect.to(
      Vector2.all(1.14),
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
