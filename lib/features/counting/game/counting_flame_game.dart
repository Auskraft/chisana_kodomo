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

/// Flame-игра «Счёт» (гибрид). Каждый раунд: малыш **тапает объекты** — голос
/// считает «один, два, три…». Затем:
/// - на ранних уровнях цифра показывается и озвучивается («Это цифра три!») —
///   знакомство без экзамена;
/// - на поздних — фаза **«найди цифру N»**: голос называет число, кнопки-цифры
///   озвучиваются по тапу, верная мягко пульсирует подсказкой.
/// Всё работает без взрослого. «Без проигрышей»: лишний/неверный тап безопасен.
class CountingGame extends FlameGame {
  CountingGame({
    required this.set,
    required this.colors,
    this.roundsPerSet = 5,
    this.onSay,
    this.setDonePhrase = 'Молодец! Всё получилось!',
    Random? random,
  }) : _rng = random ?? Random();

  final CountSet set;
  final AppColors colors;
  final int roundsPerSet;

  /// Голосовой хук (хост подключает к `Voice.instance.say`). `flush: true` —
  /// сказать сразу (счёт/цифра); по умолчанию — в очередь, без перебивания.
  final void Function(String text, {bool flush})? onSay;

  /// Финальная похвала за набор (согласована по полу — задаёт хост).
  final String setDonePhrase;

  final Random _rng;

  late final CountingSession _session;
  int _mistakes = 0;
  bool _locked = false; // блокировка после завершения раунда
  bool _choosing = false; // идёт фаза выбора цифры
  String? _lastEmoji; // чтобы соседние раунды не повторяли эмодзи
  _RoundComponent? _roundComp;

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
    _choosing = false;
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

  /// Тап по объекту (фаза счёта).
  void onObjectCounted() {
    if (!_active || _locked || _choosing) return;
    final res = _session.tap();
    Sfx.play(SfxEvent.tap);
    Haptics.tap();
    onSay?.call(_numberWord(res.counted), flush: true); // «один… два…»
    if (res.isComplete) _onCounted();
  }

  /// Все объекты посчитаны — показать цифру или открыть фазу выбора.
  void _onCounted() {
    final n = _session.round.count;
    if (_session.round.chooseDigit) {
      _startChoosing(n);
    } else {
      _revealDigit(n);
    }
  }

  /// Ранние уровни: показать и озвучить цифру (знакомство), затем дальше.
  void _revealDigit(int n) {
    _locked = true;
    _roundComp?.showDigit(n);
    onSay?.call('Это цифра ${_numberWord(n)}!', flush: true);
    _finishRound(admire: 2.0);
  }

  /// Поздние уровни: открыть кнопки-цифры, назвать число (подсказка на слух).
  void _startChoosing(int n) {
    _choosing = true;
    Haptics.tap();
    onSay?.call('Сколько получилось? Найди цифру ${_numberWord(n)}!', flush: true);
    _roundComp?.showButtons(_session.round.options);
  }

  /// Выбор цифры (фаза выбора). Возвращает `true`, если верно; при `false`
  /// кнопка трясётся сама. Каждый тап озвучивает свою цифру — учимся на слух.
  bool onNumberChosen(int value) {
    if (!_active || _locked || !_choosing) return true;
    onSay?.call(_numberWord(value), flush: true);
    final res = _session.choose(value);
    if (res.isCorrect) {
      _choosing = false;
      _locked = true;
      _finishRound(admire: 1.4);
      return true;
    }
    _mistakes++;
    Sfx.play(SfxEvent.soft);
    return false;
  }

  // ── Поток раундов ───────────────────────────────────────────────────────────

  /// Эмодзи раунда — отличный от прошлого (чтобы наборы не повторялись подряд).
  String _pickEmoji() {
    String e;
    do {
      e = _emojiPool[_rng.nextInt(_emojiPool.length)];
    } while (e == _lastEmoji && _emojiPool.length > 1);
    _lastEmoji = e;
    return e;
  }

  void _buildRound() {
    _locked = false;
    _choosing = false;
    _clearRound();
    final round = _session.round;
    _roundComp = _RoundComponent(owner: this, round: round, emoji: _pickEmoji());
    add(_roundComp!);
    onSay?.call('Посчитай!', flush: roundNumber.value == 1);
  }

  /// Раунд завершён: «сок» + похвала в очередь. Переход — после паузы
  /// «полюбоваться» ([admire] сек). На финальном раунде похвалу скажет [_finishSet].
  void _finishRound({required double admire}) {
    Sfx.play(SfxEvent.correct);
    Haptics.success();
    _burst(Vector2(size.x / 2, size.y * 0.36));
    if (roundNumber.value < roundsPerSet) {
      onSay?.call(Praise.pick(_rng)); // в очередь (flush: false)
    }
    add(TimerComponent(period: admire, removeOnFinish: true, onTick: _advance));
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
    phase.value = CountPhase.setDone;
  }

  void _clearRound() {
    for (final c in children.whereType<_RoundComponent>().toList()) {
      c.removeFromParent();
    }
    _roundComp = null;
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

/// Контейнер одного раунда: объекты-эмодзи сверху (тап → счёт), а после счёта —
/// крупная цифра (знакомство) или ряд кнопок-цифр (выбор). Раскладка — доли от
/// размера игры (адаптивно). Цифра/кнопки добавляются позже методами ниже.
class _RoundComponent extends PositionComponent {
  _RoundComponent({
    required this.owner,
    required this.round,
    required this.emoji,
  });

  final CountingGame owner;
  final CountRound round;
  final String emoji;

  int? _digit; // показанная крупная цифра (ранние уровни)
  List<int>? _buttons; // показанные кнопки-цифры (поздние уровни)

  @override
  Future<void> onLoad() async => _layout();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isMounted) _layout();
  }

  /// Показать крупную цифру (с поп-анимацией) после пересчёта.
  void showDigit(int n) {
    _digit = n;
    _addDigit(n, pop: true);
  }

  /// Открыть кнопки-цифры (фаза выбора) + подсказку-пульс верной по таймеру.
  void showButtons(List<int> opts) {
    _buttons = opts;
    _addButtons(opts, appear: true);
    add(TimerComponent(
      period: 5,
      removeOnFinish: true,
      onTick: () {
        if (owner._choosing) _pulseCorrect(round.count);
      },
    ));
  }

  void _pulseCorrect(int n) {
    for (final b in children.whereType<_NumberButton>()) {
      if (b.value == n) b.pulse();
    }
  }

  void _layout() {
    for (final c in children.toList()) {
      c.removeFromParent();
    }
    _layoutObjects();
    if (_digit != null) _addDigit(_digit!, pop: false);
    if (_buttons != null) _addButtons(_buttons!, appear: false);
  }

  void _layoutObjects() {
    final s = owner.size;
    final n = round.count;
    final cols = min(n, 5);
    final rows = (n / cols).ceil();
    final topPad = s.y * 0.14;
    final objAreaH = s.y * 0.46;
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
      add(_TapEmoji(
        side: side,
        emoji: emoji,
        colors: owner.colors,
        position: Vector2(cx, cy),
        onCount: owner.onObjectCounted,
      ));
    }
  }

  void _addDigit(int n, {required bool pop}) {
    final s = owner.size;
    final comp = TextComponent(
      text: '$n',
      anchor: Anchor.center,
      position: Vector2(s.x / 2, s.y * 0.76),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: (s.y * 0.16).clamp(64.0, 150.0).toDouble(),
          fontWeight: FontWeight.w900,
          color: owner.colors.primary,
        ),
      ),
    );
    add(comp);
    if (pop) {
      comp.scale = Vector2.zero();
      comp.add(ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.35, curve: Curves.easeOutBack),
      ));
    }
  }

  void _addButtons(List<int> opts, {required bool appear}) {
    final s = owner.size;
    final bw = (s.x * 0.8 / opts.length).clamp(48.0, 120.0).toDouble();
    final bh = (bw * 0.9).clamp(48.0, 110.0).toDouble();
    final gap = bw * 0.28;
    final totalW = opts.length * bw + (opts.length - 1) * gap;
    final startX = (s.x - totalW) / 2 + bw / 2;
    final by = s.y * 0.8;
    for (var i = 0; i < opts.length; i++) {
      final btn = _NumberButton(
        value: opts[i],
        fill: owner.colors.primary,
        textColor: owner.colors.onPrimary,
        buttonSize: Vector2(bw, bh),
        position: Vector2(startX + i * (bw + gap), by),
        onChosen: owner.onNumberChosen,
      );
      add(btn);
      if (appear) {
        btn.scale = Vector2.zero();
        btn.add(ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: 0.28,
            startDelay: 0.05 * i,
            curve: Curves.easeOutBack,
          ),
        ));
      }
    }
  }
}

/// Тап-объект (эмодзи) для фазы счёта. Один тап — поп-анимация + колбэк.
class _TapEmoji extends PositionComponent with TapCallbacks {
  _TapEmoji({
    required double side,
    required this.emoji,
    required this.colors,
    required this.onCount,
    super.position,
  }) : super(size: Vector2.all(side), anchor: Anchor.center);

  final String emoji;
  final AppColors colors;
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
    // Посчитанный объект гасим (вуаль) и ставим галочку — видно, что нажат
    // и нельзя нажать повторно.
    add(CircleComponent(
      radius: size.x * 0.5,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..color = colors.background.withValues(alpha: 0.62),
    ));
    add(TextComponent(
      text: '✓',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: size.x * 0.5,
          color: colors.success,
          fontWeight: FontWeight.w900,
        ),
      ),
    ));
    onCount();
  }
}

/// Кнопка-цифра для фазы выбора. Тап → колбэк; неверная трясётся, верную можно
/// подсветить пульсом-подсказкой.
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

  /// Подсказка: мягкий пульс (увеличение туда-обратно).
  void pulse() {
    add(ScaleEffect.to(
      Vector2.all(1.18),
      EffectController(duration: 0.35, alternate: true, repeatCount: 2),
    ));
  }
}
