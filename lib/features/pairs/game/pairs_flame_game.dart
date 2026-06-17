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
import '../logic/pairs_logic.dart';

/// Фаза экрана игры «Парочки».
enum PairsPhase { ready, playing, setDone }

/// Flame-игра «Парочки»: сетка карточек рубашкой вверх; малыш открывает по две
/// и ищет совпадения. «Сок» (поп/конфетти), пауза (`isPaused`), «без проигрышей».
///
/// Чистая логика колоды и совпадений — в [PairsSession]; здесь рендер, голос
/// (через [onSay]) и поощрение. Состояние наружу — через нотифаеры.
class PairsGame extends FlameGame {
  PairsGame({
    required this.set,
    required this.colors,
    this.onSay,
    Random? random,
  }) : _rng = random ?? Random();

  final PairsSet set;
  final AppColors colors;

  /// Голосовой хук (хост подключает к `Voice.instance.say`).
  final void Function(String text, {bool flush})? onSay;

  final Random _rng;

  late PairsSession _session;
  bool _locked = false; // короткая блокировка ввода (показ несовпадения)

  /// Эмодзи для каждого символа набора (перемешаны на старте — для разнообразия).
  late List<String> _symbolEmoji;
  final Map<int, _Card> _cardViews = <int, _Card>{};

  final ValueNotifier<PairsPhase> phase = ValueNotifier<PairsPhase>(
    PairsPhase.ready,
  );
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);

  /// Сколько пар уже найдено — для HUD.
  final ValueNotifier<int> matchedPairs = ValueNotifier<int>(0);
  final ValueNotifier<int> earnedStars = ValueNotifier<int>(0);

  static const List<String> _emojiPool = <String>[
    '🍎', '🐶', '⭐', '🐰', '🌸', '🐟', '🚗', '🎈', '🍓', '🐤',
  ];

  bool get _active => phase.value == PairsPhase.playing && !isPaused.value;

  String emojiFor(int symbol) => _symbolEmoji[symbol % _symbolEmoji.length];

  @override
  Color backgroundColor() => colors.background;

  /// Начать/перезапустить набор (новая перемешанная колода).
  void start() {
    _session = PairsSession(set, random: _rng);
    _symbolEmoji = (<String>[..._emojiPool]..shuffle(_rng)).take(set.pairs).toList();
    _locked = false;
    matchedPairs.value = 0;
    phase.value = PairsPhase.playing;
    isPaused.value = false;
    paused = false;
    _buildBoard();
    onSay?.call('Найди пару!', flush: true);
  }

  void togglePause() {
    if (phase.value != PairsPhase.playing) return;
    isPaused.value = !isPaused.value;
    paused = isPaused.value;
  }

  void resume() {
    if (!isPaused.value) return;
    isPaused.value = false;
    paused = false;
  }

  // ── Ввод ────────────────────────────────────────────────────────────────────

  /// Тап по карточке [index] (зовётся компонентом карты).
  void onCardTap(int index) {
    if (!_active || _locked) return;
    final res = _session.flip(index);
    switch (res.outcome) {
      case FlipOutcome.ignored:
        return;
      case FlipOutcome.firstUp:
        Sfx.play(SfxEvent.tap);
        Haptics.tap();
        _cardViews[index]?.flipToFace();
      case FlipOutcome.matched:
        _onMatched(res);
      case FlipOutcome.mismatch:
        _onMismatch(res);
    }
  }

  void _onMatched(FlipResult res) {
    Sfx.play(SfxEvent.correct);
    Haptics.success();
    final a = _cardViews[res.index];
    final b = _cardViews[res.otherIndex!];
    a?.flipToFace();
    a?.markMatched();
    b?.markMatched();
    if (a != null && b != null) {
      _burst((a.position + b.position) / 2);
    }
    matchedPairs.value += 1;

    if (res.allMatched) {
      add(TimerComponent(period: 1.2, removeOnFinish: true, onTick: _finishSet));
    } else {
      onSay?.call(Praise.pick(_rng));
    }
  }

  void _onMismatch(FlipResult res) {
    Sfx.play(SfxEvent.soft);
    Haptics.tap();
    final a = res.index;
    final b = res.otherIndex!;
    _cardViews[a]?.flipToFace();
    _locked = true;
    add(TimerComponent(
      period: 0.95,
      removeOnFinish: true,
      onTick: () {
        _session.resolveMismatch(a, b);
        _cardViews[a]?.flipToBack();
        _cardViews[b]?.flipToBack();
        _locked = false;
      },
    ));
  }

  // ── Поле ──────────────────────────────────────────────────────────────────

  void _buildBoard() {
    _clearBoard();
    add(_Board(owner: this));
  }

  void _finishSet() {
    _clearBoard();
    earnedStars.value = PairsSet.starsForMismatches(_session.mismatches, set.pairs);
    Sfx.play(SfxEvent.complete);
    onSay?.call('Молодец! Ты справился!');
    phase.value = PairsPhase.setDone;
  }

  void _clearBoard() {
    for (final c in children.whereType<_Board>().toList()) {
      c.removeFromParent();
    }
    _cardViews.clear();
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

/// Контейнер поля: раскладывает карточки сеткой долями от экрана. Перестраивает
/// виды из состояния сессии (открыта/совпала) — корректно при ресайзе.
class _Board extends PositionComponent {
  _Board({required this.owner});

  final PairsGame owner;

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
    owner._cardViews.clear();

    final s = owner.size;
    final set = owner.set;
    final cards = owner._session.cards;
    final cols = set.columns;
    final rows = (set.cardCount / cols).ceil();

    final topPad = s.y * 0.14;
    final areaW = s.x * 0.9;
    final areaH = s.y * 0.74;
    final cellW = areaW / cols;
    final cellH = areaH / rows;
    final side = (min(cellW, cellH) * 0.84).clamp(40.0, 150.0).toDouble();
    final gridW = cols * cellW;
    final startX = (s.x - gridW) / 2 + cellW / 2;

    for (var i = 0; i < cards.length; i++) {
      final r = i ~/ cols;
      final colInRow = i % cols;
      final pos = Vector2(
        startX + colInRow * cellW,
        topPad + cellH * r + cellH / 2,
      );
      final view = _Card(
        index: i,
        emoji: owner.emojiFor(cards[i].symbol),
        colors: owner.colors,
        side: side,
        position: pos,
        faceUp: cards[i].faceUp,
        matched: cards[i].matched,
        onTapCard: owner.onCardTap,
      );
      owner._cardViews[i] = view;
      add(view);
    }
  }
}

/// Карточка: рубашка / лицо (эмодзи) / найденная (лицо + рамка успеха).
/// Переворот — сжатие по X с подменой стороны.
class _Card extends PositionComponent with TapCallbacks {
  _Card({
    required this.index,
    required this.emoji,
    required this.colors,
    required double side,
    required Vector2 position,
    required this.onTapCard,
    required bool faceUp,
    required bool matched,
  })  : _faceUp = faceUp,
        _matched = matched,
        super(size: Vector2.all(side), anchor: Anchor.center, position: position);

  final int index;
  final String emoji;
  final AppColors colors;
  final void Function(int index) onTapCard;

  bool _faceUp;
  bool _matched;
  late final TextPaint _emojiPaint;

  @override
  Future<void> onLoad() async {
    _emojiPaint = TextPaint(style: TextStyle(fontSize: size.x * 0.56));
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.2),
    );
    if (_faceUp || _matched) {
      canvas.drawRRect(rrect, Paint()..color = colors.surface);
      _emojiPaint.render(
        canvas,
        emoji,
        Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
      );
      if (_matched) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.x * 0.06
            ..color = colors.success,
        );
      }
    } else {
      // Рубашка: яркая плашка с кружком-узором.
      canvas.drawRRect(rrect, Paint()..color = colors.primary);
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x * 0.18,
        Paint()..color = colors.onPrimary.withValues(alpha: 0.5),
      );
    }
  }

  void flipToFace() => _flip(toFace: true);

  void flipToBack() => _flip(toFace: false);

  void markMatched() {
    _matched = true;
    add(ScaleEffect.to(
      Vector2.all(1.12),
      EffectController(duration: 0.12, alternate: true),
    ));
  }

  void _flip({required bool toFace}) {
    add(ScaleEffect.to(
      Vector2(0.02, 1.0),
      EffectController(duration: 0.11),
      onComplete: () {
        _faceUp = toFace;
        add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.11)));
      },
    ));
  }

  @override
  void onTapDown(TapDownEvent event) => onTapCard(index);
}
