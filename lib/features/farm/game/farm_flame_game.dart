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
import '../../animals/animal_icons.dart';
import '../../animals/logic/animals_logic.dart';

/// Фаза экрана «Ферма» (квиз «угадай звук»).
enum FarmPhase { ready, playing, setDone }

/// Flame-квиз «Ферма» / «Угадай, кто это»: играет звук зверя-загадки (реальный
/// CC0-`.wav`, а пока файла нет — имя голосом), малыш выбирает нужного зверя из
/// карточек-иконок. «Сок»/пауза/звёзды как у других квизов. «Без проигрышей».
///
/// Логика раунда — общая [AnimalSession]/[AnimalSet]; здесь рендер и поток.
class FarmGame extends FlameGame {
  FarmGame({
    required this.set,
    required this.colors,
    this.roundsPerSet = 5,
    this.onSay,
    this.onCue,
    this.onStopCue,
    this.setDonePhrase = 'Молодец! Всё получилось!',
    Random? random,
  }) : _rng = random ?? Random();

  final AnimalSet set;
  final AppColors colors;
  final int roundsPerSet;
  final void Function(String text, {bool flush})? onSay;

  /// «Озвучить загадку» (звук зверя): хост играет CC0-`.wav`, а пока нет — имя.
  final void Function(Animal target)? onCue;

  /// Остановить играющую загадку (хост зовёт `SoundPool.stopAll`) — чтобы при
  /// ответе звук зверя не накладывался на голос-реплику.
  final void Function()? onStopCue;

  /// Финальная похвала за набор (согласована по полу — задаёт хост).
  final String setDonePhrase;

  final Random _rng;

  late AnimalSession _session;
  int _mistakes = 0;
  bool _locked = false;

  final ValueNotifier<FarmPhase> phase = ValueNotifier<FarmPhase>(FarmPhase.ready);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
  final ValueNotifier<int> roundNumber = ValueNotifier<int>(1);
  final ValueNotifier<int> earnedStars = ValueNotifier<int>(0);

  bool get _active => phase.value == FarmPhase.playing && !isPaused.value;

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
    phase.value = FarmPhase.playing;
    isPaused.value = false;
    paused = false;
    _buildRound();
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

  /// Повторить звук-загадку (тап по кнопке-динамику).
  void replayCue() {
    if (!_active) return;
    onCue?.call(_session.round.target);
  }

  /// Тап по варианту. true — верно (иначе карточка трясётся сама).
  bool onChoose(int index) {
    if (!_active || _locked) return true;
    onStopCue?.call(); // глушим загадку-звук, чтобы реплика не наложилась
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
    onCue?.call(_session.round.target); // проиграть загадку-звук
  }

  void _solveRound() {
    _locked = true;
    Sfx.play(SfxEvent.correct);
    Haptics.success();
    _burst(Vector2(size.x / 2, size.y * 0.3));
    onSay?.call('${animalNameCap(_session.round.target)}!', flush: true);
    if (roundNumber.value < roundsPerSet) {
      onSay?.call(Praise.pick(_rng));
    }
    // Длиннее, чтобы имя зверя + похвала договорили до следующего звука-загадки
    // (иначе остаток реплики накладывается на звук зверя нового раунда).
    add(TimerComponent(period: 2.4, removeOnFinish: true, onTick: _advance));
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
    phase.value = FarmPhase.setDone;
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

/// Контейнер раунда: кнопка-звук сверху (тап = повторить) + сетка вариантов.
class _Board extends PositionComponent {
  _Board({required this.owner, required this.round});

  final FarmGame owner;
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

    final promptSize = (shortest * 0.3).clamp(110.0, 210.0).toDouble();
    add(_SoundButton(
      colors: owner.colors,
      cardSize: promptSize,
      position: Vector2(s.x / 2, s.y * 0.24),
      onTap: owner.replayCue,
    ));

    final n = round.options.length;
    final cols = n <= 3 ? n : 2;
    final rows = (n / cols).ceil();
    const gapFactor = 0.22;
    // Плитки + промежутки должны умещаться в ~0.84 ширины. Если делить только на
    // cols, gap добавляется сверху и плитки подходят вплотную к левому/правому краю.
    final tile = (min(
      s.x * 0.84 / (cols + gapFactor * (cols - 1)),
      s.y * 0.46 / rows,
    )).clamp(64.0, 150.0).toDouble();
    final gap = tile * gapFactor;
    final topY = s.y * 0.52;
    for (var i = 0; i < n; i++) {
      final r = i ~/ cols;
      final colInRow = i % cols;
      final rowCount = (r == rows - 1) ? (n - cols * (rows - 1)) : cols;
      final rowW = rowCount * tile + (rowCount - 1) * gap;
      final cx = (s.x - rowW) / 2 + tile / 2 + colInRow * (tile + gap);
      final cy = topY + r * (tile + gap);
      add(_AnimalCard(
        animal: Animals.all[round.options[i]],
        index: i,
        tile: tile,
        position: Vector2(cx, cy),
        onChosen: owner.onChoose,
      ));
    }
  }
}

/// Кнопка-загадка «🔊» (скруглённая карточка с тенью): тап — повторить звук.
class _SoundButton extends PositionComponent with TapCallbacks {
  _SoundButton({
    required this.colors,
    required this.cardSize,
    required Vector2 position,
    required this.onTap,
  }) : super(size: Vector2.all(cardSize), anchor: Anchor.center, position: position);

  final AppColors colors;
  final double cardSize;
  final VoidCallback onTap;
  late final TextPaint _spk;

  @override
  Future<void> onLoad() async {
    _spk = TextPaint(style: TextStyle(fontSize: cardSize * 0.46));
    await UiSprites.load('sound');
  }

  @override
  void render(Canvas canvas) {
    final icon = UiSprites.cached('sound');
    if (icon != null) {
      UiSprites.paintInRect(canvas, icon, Rect.fromLTWH(0, 0, size.x, size.y));
      return;
    }
    // Запас (нет файла): белая карточка + эмодзи-динамик.
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(size.x * 0.28),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(rrect, Paint()..color = colors.surface);
    _spk.render(canvas, '🔊', Vector2(size.x / 2, size.y / 2), anchor: Anchor.center);
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

/// Карточка-вариант: арт-иконка зверя (скруглённая с тенью) или эмодзи-запас.
class _AnimalCard extends PositionComponent with TapCallbacks {
  _AnimalCard({
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
