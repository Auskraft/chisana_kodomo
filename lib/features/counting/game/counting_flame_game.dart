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
import '../logic/counting_logic.dart';

/// Фаза экрана игры «Счёт».
enum CountPhase { ready, playing, setDone }

/// Flame-игра «Счёт»: тап-канвас с эмодзи-объектами, оба режима (счёт тапом /
/// выбор цифры) и «сок» (поп объектов, конфетти, мягкая тряска). Прогрессия и
/// ввод — только когда [_active]. «Без проигрышей»: лишний/неверный тап безопасен.
///
/// Чистая логика раунда — в [CountingSession]; здесь рендер, голос (через [onSay])
/// и поощрение. Состояние наружу — через нотифаеры (для оверлеев хоста).
class CountingGame extends FlameGame {
  CountingGame({
    required this.set,
    required this.colors,
    this.roundsPerSet = 5,
    this.onSay,
    Random? random,
  }) : _rng = random ?? Random();

  final CountSet set;
  final AppColors colors;
  final int roundsPerSet;

  /// Голосовой хук (хост подключает к `Voice.instance.say`).
  final void Function(String text)? onSay;

  final Random _rng;

  late final CountingSession _session;
  int _mistakes = 0;
  bool _locked = false; // короткая блокировка ввода после успеха

  /// Текущая фаза (ready → playing → setDone).
  final ValueNotifier<CountPhase> phase = ValueNotifier<CountPhase>(
    CountPhase.ready,
  );

  /// Пауза (нотифаер называется `isPaused`, не `paused`).
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);

  /// Номер текущего раунда в наборе (1-based) — для HUD.
  final ValueNotifier<int> roundNumber = ValueNotifier<int>(1);

  /// Звёзды за набор (выставляется при [CountPhase.setDone]).
  final ValueNotifier<int> earnedStars = ValueNotifier<int>(0);

  static const List<String> _emojiPool = <String>[
    '🍎', '🐶', '⭐', '🐰', '🌸', '🐟', '🚗', '🎈', '🍓', '🐤',
  ];

  bool get _active => phase.value == CountPhase.playing && !isPaused.value;

  @override
  Color backgroundColor() => colors.background;

  @override
  Future<void> onLoad() async {
    _session = CountingSession(set, random: _rng);
  }

  /// Начать/перезапустить набор (вызывает хост по кнопке «Играть»).
  void start() {
    _mistakes = 0;
    _locked = false;
    roundNumber.value = 1;
    phase.value = CountPhase.playing;
    isPaused.value = false;
    paused = false;
    _buildRound();
  }

  void togglePause() {
    if (phase.value != CountPhase.playing) return;
    isPaused.value = !isPaused.value;
    paused = isPaused.value; // замораживаем эффекты/таймеры движка
  }

  void resume() {
    if (!isPaused.value) return;
    isPaused.value = false;
    paused = false;
  }

  // ── Ввод (зовётся компонентами раунда) ──────────────────────────────────────

  /// Тап по объекту (режим tapCount).
  void onObjectCounted() {
    if (!_active || _locked) return;
    final res = _session.tap();
    Sfx.play(SfxEvent.tap);
    Haptics.tap();
    onSay?.call(_numberWord(res.counted));
    if (res.isComplete) _solveRound();
  }

  /// Выбор цифры (режим chooseNumeral). Возвращает `true`, если верно; при
  /// `false` кнопка трясётся сама. Тапы вне игры/после успеха игнорируются.
  bool onNumberChosen(int value) {
    if (!_active || _locked) return true;
    final res = _session.choose(value);
    if (res.isCorrect) {
      _solveRound();
      return true;
    }
    _mistakes++;
    Sfx.play(SfxEvent.soft);
    onSay?.call('Попробуй ещё');
    return false;
  }

  // ── Поток раундов ───────────────────────────────────────────────────────────

  void _buildRound() {
    _locked = false;
    _clearRound();
    final round = _session.round;
    add(_RoundComponent(
      owner: this,
      round: round,
      emoji: _emojiPool[_rng.nextInt(_emojiPool.length)],
    ));
    onSay?.call(round.mode == CountMode.tapCount ? 'Посчитай!' : 'Сколько?');
  }

  void _solveRound() {
    _locked = true;
    Sfx.play(SfxEvent.correct);
    Haptics.success();
    _burst(Vector2(size.x / 2, size.y * 0.38));
    onSay?.call('${Praise.pick(_rng)} ${_numberWord(_session.round.count)}.');
    add(TimerComponent(period: 0.95, removeOnFinish: true, onTick: _advance));
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
    phase.value = CountPhase.setDone;
  }

  void _clearRound() {
    for (final c in children.whereType<_RoundComponent>().toList()) {
      c.removeFromParent();
    }
  }

  void _burst(Vector2 at) {
    final palette = <Color>[
      colors.accent,
      colors.primary,
      colors.secondary,
      colors.success,
    ];
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

String _numberWord(int n) {
  const words = <String>[
    'ноль', 'один', 'два', 'три', 'четыре',
    'пять', 'шесть', 'семь', 'восемь', 'девять', 'десять',
  ];
  return (n >= 0 && n < words.length) ? words[n] : '$n';
}

/// Контейнер одного раунда: раскладывает объекты (и кнопки-цифры) по экрану
/// долями от размера игры — адаптивно под любой телефон.
class _RoundComponent extends PositionComponent {
  _RoundComponent({
    required this.owner,
    required this.round,
    required this.emoji,
  });

  final CountingGame owner;
  final CountRound round;
  final String emoji;

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
    final n = round.count;
    final isChoose = round.mode == CountMode.chooseNumeral;

    final cols = min(n, 5);
    final rows = (n / cols).ceil();
    final topPad = s.y * 0.16;
    final objAreaH = s.y * (isChoose ? 0.42 : 0.66);
    final cellW = (s.x * 0.86) / cols;
    final cellH = objAreaH / rows;
    final side = (min(cellW, cellH) * 0.82).clamp(28.0, 110.0).toDouble();

    for (var i = 0; i < n; i++) {
      final r = i ~/ cols;
      final colInRow = i - cols * r;
      final rowCount = (r == rows - 1) ? (n - cols * (rows - 1)) : cols;
      final rowW = rowCount * cellW;
      final cx = (s.x - rowW) / 2 + cellW * colInRow + cellW / 2;
      final cy = topPad + cellH * r + cellH / 2;
      final pos = Vector2(cx, cy);

      if (isChoose) {
        add(TextComponent(
          text: emoji,
          anchor: Anchor.center,
          position: pos,
          textRenderer: TextPaint(style: TextStyle(fontSize: side * 0.8)),
        ));
      } else {
        add(_TapEmoji(
          side: side,
          emoji: emoji,
          position: pos,
          onCount: owner.onObjectCounted,
        ));
      }
    }

    if (isChoose) {
      final opts = round.options;
      final bw = (s.x * 0.8 / opts.length).clamp(48.0, 120.0).toDouble();
      final bh = (bw * 0.9).clamp(48.0, 110.0).toDouble();
      final gap = bw * 0.28;
      final totalW = opts.length * bw + (opts.length - 1) * gap;
      final startX = (s.x - totalW) / 2 + bw / 2;
      final by = s.y * 0.8;
      for (var i = 0; i < opts.length; i++) {
        add(_NumberButton(
          value: opts[i],
          fill: owner.colors.primary,
          textColor: owner.colors.onPrimary,
          buttonSize: Vector2(bw, bh),
          position: Vector2(startX + i * (bw + gap), by),
          onChosen: owner.onNumberChosen,
        ));
      }
    }
  }
}

/// Тап-объект (эмодзи) для режима счёта. Один тап — поп-анимация + колбэк.
class _TapEmoji extends PositionComponent with TapCallbacks {
  _TapEmoji({
    required double side,
    required this.emoji,
    required this.onCount,
    super.position,
  }) : super(size: Vector2.all(side), anchor: Anchor.center);

  final String emoji;
  final VoidCallback onCount;
  bool _counted = false;

  @override
  Future<void> onLoad() async {
    add(TextComponent(
      text: emoji,
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(style: TextStyle(fontSize: size.x * 0.82)),
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_counted) return;
    _counted = true;
    add(ScaleEffect.to(
      Vector2.all(1.22),
      EffectController(duration: 0.1, alternate: true),
    ));
    onCount();
  }
}

/// Кнопка-цифра для режима выбора.
class _NumberButton extends PositionComponent with TapCallbacks {
  _NumberButton({
    required this.value,
    required this.fill,
    required this.textColor,
    required Vector2 buttonSize,
    required this.onChosen,
    super.position,
  }) : super(size: buttonSize, anchor: Anchor.center);

  final int value;
  final Color fill;
  final Color textColor;
  final bool Function(int value) onChosen;

  @override
  Future<void> onLoad() async {
    add(TextComponent(
      text: '$value',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: size.y * 0.5,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    ));
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.y * 0.3),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);
    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!onChosen(value)) shake();
  }

  /// Мягкая тряска при неверном выборе (без штрафа).
  void shake() {
    add(MoveEffect.by(
      Vector2(10, 0),
      EffectController(duration: 0.05, alternate: true, repeatCount: 3),
    ));
  }
}
