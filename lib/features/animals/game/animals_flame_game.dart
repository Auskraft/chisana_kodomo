import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/sfx.dart';
import '../../../core/components/ui_sprites.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/praise/praise.dart';
import '../../../core/theme/app_colors.dart';
import '../animal_icons.dart';
import '../logic/animals_logic.dart';

/// Фаза экрана игры «Звуки животных».
enum AnimalsPhase { ready, playing, setDone }

/// Flame-игра «Звуки животных»: голос спрашивает «Где собачка?», малыш тапает
/// нужного зверя. Верно → имя зверя голосом + похвала + конфетти. «Сок» и пауза
/// как в остальных играх. «Без проигрышей».
///
/// Звук зверя — Фаза 5 (`Animal.soundKey`); сейчас обратная связь голосом.
class AnimalsGame extends FlameGame {
  AnimalsGame({
    required this.set,
    required this.colors,
    this.roundsPerSet = 5,
    this.onSay,
    this.onAnimalSound,
    this.setDonePhrase = 'Молодец! Всё получилось!',
    Random? random,
  }) : _rng = random ?? Random();

  final AnimalSet set;
  final AppColors colors;
  final int roundsPerSet;
  final void Function(String text, {bool flush})? onSay;

  /// Хук на звук зверя по [Animal.soundKey] (CC0-файлы — Фаза 5). Может быть
  /// null/тихим, пока файлов нет; озвучка имени голосом работает в любом случае.
  final void Function(String soundKey)? onAnimalSound;

  /// Финальная похвала за набор (согласована по полу — задаёт хост).
  final String setDonePhrase;

  final Random _rng;

  late AnimalSession _session;
  int _mistakes = 0;
  bool _locked = false;

  final ValueNotifier<AnimalsPhase> phase =
      ValueNotifier<AnimalsPhase>(AnimalsPhase.ready);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
  final ValueNotifier<int> roundNumber = ValueNotifier<int>(1);
  final ValueNotifier<int> earnedStars = ValueNotifier<int>(0);

  bool get _active => phase.value == AnimalsPhase.playing && !isPaused.value;

  @override
  Color backgroundColor() => colors.background;

  @override
  Future<void> onLoad() async {
    _session = AnimalSession(set, random: _rng);
  }

  void start() {
    _session = AnimalSession(set, random: _rng);
    _mistakes = 0;
    _locked = false;
    roundNumber.value = 1;
    phase.value = AnimalsPhase.playing;
    isPaused.value = false;
    paused = false;
    _buildRound();
  }

  void togglePause() {
    if (phase.value != AnimalsPhase.playing) return;
    isPaused.value = !isPaused.value;
    paused = isPaused.value;
  }

  void resume() {
    if (!isPaused.value) return;
    isPaused.value = false;
    paused = false;
  }

  /// Повторить вопрос (тап по карточке-вопросу).
  void repeatPrompt() {
    if (!_active) return;
    onSay?.call('Где ${_session.round.target.name}?', flush: true);
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
      'Где ${_session.round.target.name}?',
      flush: roundNumber.value == 1,
    );
  }

  void _solveRound() {
    _locked = true;
    Sfx.play(SfxEvent.correct);
    Haptics.success();
    _burst(Vector2(size.x / 2, size.y * 0.3));
    // Звук зверя — главная награда. Голос поверх НЕ накладываем: имя уже звучало
    // в вопросе «Где …?», а похвала-TTS перебила бы сам звук (разные движки).
    onAnimalSound?.call(_session.round.target.soundKey);
    add(TimerComponent(period: 1.8, removeOnFinish: true, onTick: _advance));
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
    onSay?.call(setDonePhrase);
    phase.value = AnimalsPhase.setDone;
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

/// Контейнер раунда: карточка-вопрос сверху (тап — повторить) + сетка вариантов.
class _Board extends PositionComponent {
  _Board({required this.owner, required this.round});

  final AnimalsGame owner;
  final AnimalRound round;

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
    final shortest = min(s.x, s.y);

    final promptSize = (shortest * 0.3).clamp(110.0, 220.0).toDouble();
    add(_PromptCard(
      cardSize: promptSize,
      position: Vector2(s.x / 2, s.y * 0.24),
      onTap: owner.repeatPrompt,
    ));

    final n = round.options.length;
    final cols = n <= 3 ? n : 2;
    final rows = (n / cols).ceil();
    final tile = (min(s.x * 0.86 / cols, s.y * 0.46 / rows))
        .clamp(64.0, 150.0)
        .toDouble();
    final gap = tile * 0.22;
    final topY = s.y * 0.52;
    for (var i = 0; i < n; i++) {
      final r = i ~/ cols;
      final colInRow = i % cols;
      final rowCount = (r == rows - 1) ? (n - cols * (rows - 1)) : cols;
      final rowW = rowCount * tile + (rowCount - 1) * gap;
      final cx = (s.x - rowW) / 2 + tile / 2 + colInRow * (tile + gap);
      final cy = topY + r * (tile + gap);
      add(_AnimalTile(
        animal: Animals.all[round.options[i]],
        index: i,
        tile: tile,
        position: Vector2(cx, cy),
        onChosen: owner.onChoose,
      ));
    }
  }
}

/// Карточка-вопрос: «❓🔊» — тап повторяет вопрос голосом.
class _PromptCard extends PositionComponent with TapCallbacks {
  _PromptCard({
    required this.cardSize,
    required Vector2 position,
    required this.onTap,
  }) : super(size: Vector2.all(cardSize), anchor: Anchor.center, position: position);

  final double cardSize;
  final VoidCallback onTap;
  late final TextPaint _q;
  late final TextPaint _spk;

  @override
  Future<void> onLoad() async {
    _q = TextPaint(style: TextStyle(fontSize: cardSize * 0.5));
    _spk = TextPaint(style: TextStyle(fontSize: cardSize * 0.26));
    await UiSprites.load('sound');
  }

  @override
  void render(Canvas canvas) {
    // Без подложки — «?» и динамик прямо на фоне; динамик опущен ниже.
    _q.render(canvas, '❓', Vector2(size.x / 2, size.y * 0.38), anchor: Anchor.center);
    final icon = UiSprites.cached('sound');
    if (icon != null) {
      final side = size.x * 0.34;
      UiSprites.paintInRect(
        canvas,
        icon,
        Rect.fromCenter(
            center: Offset(size.x / 2, size.y * 0.92), width: side, height: side),
      );
    } else {
      _spk.render(canvas, '🔊', Vector2(size.x / 2, size.y * 0.92), anchor: Anchor.center);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    add(ScaleEffect.to(
      Vector2.all(1.08),
      EffectController(duration: 0.1, alternate: true),
    ));
    onTap();
  }
}

/// Плитка-вариант: эмодзи зверя на карточке.
class _AnimalTile extends PositionComponent with TapCallbacks {
  _AnimalTile({
    required this.animal,
    required this.index,
    required this.tile,
    required Vector2 position,
    required this.onChosen,
  }) : super(size: Vector2.all(tile), anchor: Anchor.center, position: position);

  final Animal animal;
  final int index;
  final double tile;
  final bool Function(int index) onChosen;
  late final TextPaint _emoji;

  @override
  Future<void> onLoad() async {
    _emoji = TextPaint(style: TextStyle(fontSize: size.x * 0.56));
    await AnimalIcons.load(animal.soundKey);
  }

  @override
  void render(Canvas canvas) {
    // Арт-иконка зверя скруглённой карточкой с тенью; иначе — эмодзи.
    final icon = AnimalIcons.cached(animal.soundKey);
    if (icon != null) {
      AnimalIcons.paintRoundedCard(canvas, icon, size.x);
    } else {
      _emoji.render(canvas, animal.emoji, Vector2(size.x / 2, size.y / 2), anchor: Anchor.center);
    }
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
