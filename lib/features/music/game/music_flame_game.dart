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

/// Орган: тёплые «трубы» — насыщенные приглушённые тона (отличны от ярких пластин
/// ксилофона и белых клавиш пианино). Хардкод-палитра, как [kBarColors].
const List<Color> kOrganColors = <Color>[
  Color(0xFFB5651D), // медь
  Color(0xFFCC8A3C),
  Color(0xFFD9A441),
  Color(0xFF7E9A5B), // олива
  Color(0xFF4F8C7B), // тёмная бирюза
  Color(0xFF4A6FA5), // приглушённый синий
  Color(0xFF7A5C9E), // приглушённый фиолет
  Color(0xFF9E5C7A), // приглушённая роза
];

/// Колокольчики/металлофон: холодные «серебристые» тона (отличны от тёплых
/// пластин ксилофона/органа). Хардкод-палитра.
const List<Color> kBellsColors = <Color>[
  Color(0xFF90A4AE), // сине-серый
  Color(0xFFB0BEC5),
  Color(0xFF80CBC4), // светлая бирюза
  Color(0xFF4DD0E1), // циан
  Color(0xFF64B5F6), // светло-синий
  Color(0xFF7986CB), // индиго-светлый
  Color(0xFF9FA8DA), // лаванда
  Color(0xFFB39DDB), // светло-фиолетовый
];

/// Синтезатор: яркая «неоновая» палитра (электронный вид). Хардкод-палитра.
const List<Color> kSynthColors = <Color>[
  Color(0xFFFF1744), // неон-красный
  Color(0xFFFF9100), // неон-оранж
  Color(0xFFFFEA00), // неон-жёлтый
  Color(0xFF00E676), // неон-зелёный
  Color(0xFF00E5FF), // неон-циан
  Color(0xFF2979FF), // неон-синий
  Color(0xFFD500F9), // неон-фиолет
  Color(0xFFFF4081), // неон-розовый
];

/// Цвет подписи ноты: тёмный на светлой пластине/клавише, белый на тёмной.
Color _labelColorOn(Color c) =>
    c.computeLuminance() > 0.5 ? const Color(0xFF4E342E) : Colors.white;

/// Верхний отступ клавиатуры (доля высоты) — ОДИНАКОВ у всех инструментов, чтобы
/// верхняя пластина/клавиша не упиралась в шапку с табами.
const double _kKeyboardTopPad = 0.16;

/// Flame-«Музыка»: клавишный инструмент (ксилофон/пианино/орган — переключаются
/// табами). 8 нот до-мажора с подписями (до-ре-ми); тап → отскок + вспышка +
/// вибро + тон (`onNote` → сэмпл инструмента). **Без проигрышей.**
class MusicGame extends FlameGame {
  MusicGame({required this.colors, this.onNote});

  final AppColors colors;

  /// Хук на сыгранную ноту (Фаза 5 подключит синтез тона). Может быть null.
  final void Function(XyloNote note)? onNote;

  final ValueNotifier<MusicPhase> phase =
      ValueNotifier<MusicPhase>(MusicPhase.ready);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);

  /// Текущий инструмент (переключается табами; перестраивает клавиатуру).
  final ValueNotifier<Instrument> instrument =
      ValueNotifier<Instrument>(Instrument.all.first);

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

  /// Сменить инструмент: перестраиваем клавиатуру под его вид (если уже играем).
  void setInstrument(Instrument i) {
    if (instrument.value.id == i.id) return;
    instrument.value = i;
    if (phase.value == MusicPhase.playing) _buildKeyboard();
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
    final notes = Xylophone.cMajor;
    if (owner.instrument.value.style == InstrumentStyle.bars) {
      _layoutBars(notes);
    } else {
      _layoutKeys(notes);
    }
  }

  /// Ксилофон: горизонтальные пластины «лесенкой» (низкая нота — широкая, внизу).
  void _layoutBars(List<XyloNote> notes) {
    final s = owner.size;
    final count = notes.length;
    final topPad = s.y * _kKeyboardTopPad;
    final bottomPad = s.y * 0.04;
    final areaH = s.y - topPad - bottomPad;
    final slot = areaH / count;
    final barH = slot * 0.82;
    final maxW = s.x * 0.88;
    final minW = s.x * 0.5;
    // Ксилофон — радужная палитра, колокольчики — холодная «серебристая».
    final palette =
        owner.instrument.value.id == 'bells' ? kBellsColors : kBarColors;
    for (var row = 0; row < count; row++) {
      final noteIndex = count - 1 - row; // сверху — высокие
      final note = notes[noteIndex];
      final w = maxW - (maxW - minW) * (noteIndex / (count - 1));
      final cy = topPad + slot * row + slot / 2;
      final color = palette[noteIndex % palette.length];
      add(_Pad(
        note: note,
        color: color,
        labelColor: _labelColorOn(color),
        labelYFrac: 0.5,
        radiusFrac: 0.4,
        padSize: Vector2(w, barH),
        position: Vector2(s.x / 2, cy),
        onHit: owner.onBarHit,
      ));
    }
  }

  /// Пианино/орган: вертикальные клавиши в ряд (слева — низкая «до»). Пианино —
  /// белые клавиши, орган — тёплые цветные.
  void _layoutKeys(List<XyloNote> notes) {
    final s = owner.size;
    final count = notes.length;
    final id = owner.instrument.value.id;
    final topPad = s.y * _kKeyboardTopPad;
    final bottomPad = s.y * 0.06;
    final keysH = s.y - topPad - bottomPad;
    final totalW = s.x * 0.94;
    final gap = totalW * 0.012;
    final keyW = (totalW - gap * (count - 1)) / count;
    final startX = (s.x - totalW) / 2 + keyW / 2;
    for (var i = 0; i < count; i++) {
      final note = notes[i]; // слева — низкая нота (до)
      final color = id == 'piano'
          ? const Color(0xFFF2ECDE) // мягкая «слоновая кость», не глянцевый белый
          : id == 'synth'
              ? kSynthColors[i % kSynthColors.length]
              : kOrganColors[i % kOrganColors.length];
      final cx = startX + i * (keyW + gap);
      add(_Pad(
        note: note,
        color: color,
        labelColor: _labelColorOn(color),
        borderColor: id == 'piano' ? const Color(0xFFD8D0BF) : null,
        labelYFrac: 0.86,
        radiusFrac: 0.18,
        padSize: Vector2(keyW, keysH),
        position: Vector2(cx, topPad + keysH / 2),
        onHit: owner.onBarHit,
      ));
    }
  }
}

/// Пластина (ксилофон) или клавиша (пианино/орган): цветной прямоугольник +
/// подпись ноты (до-ре-ми). Вспышка по тапу — затухающим [_lit], плюс отскок.
class _Pad extends PositionComponent with TapCallbacks {
  _Pad({
    required this.note,
    required this.color,
    required this.labelColor,
    required this.labelYFrac,
    required this.radiusFrac,
    required Vector2 padSize,
    required Vector2 position,
    required this.onHit,
    this.borderColor,
  }) : super(size: padSize, anchor: Anchor.center, position: position);

  final XyloNote note;
  final Color color;
  final Color labelColor;

  /// Обводка (для белых клавиш пианино — чтобы очерчивались, а не сливались/слепили).
  final Color? borderColor;

  /// Где подпись по вертикали (доля высоты): по центру пластины / у низа клавиши.
  final double labelYFrac;

  /// Радиус скругления как доля меньшей стороны.
  final double radiusFrac;
  final void Function(XyloNote note) onHit;

  double _lit = 0;
  late final TextPaint _labelPaint;

  @override
  Future<void> onLoad() async {
    final fs = (math.min(size.x, size.y) * 0.32).clamp(11.0, 24.0).toDouble();
    _labelPaint = TextPaint(
      style: TextStyle(
        fontSize: fs,
        fontWeight: FontWeight.w800,
        color: labelColor,
        shadows: <Shadow>[
          Shadow(
            color: (labelColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white)
                .withValues(alpha: 0.25),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  @override
  void update(double dt) {
    if (_lit > 0) _lit = math.max(0, _lit - dt * 4);
  }

  @override
  void render(Canvas canvas) {
    final col = Color.lerp(color, Colors.white, _lit * 0.5)!;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(math.min(size.x, size.y) * radiusFrac),
    );
    canvas.drawRRect(r, Paint()..color = col);
    if (borderColor != null) {
      canvas.drawRRect(
        r,
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    _labelPaint.render(
      canvas,
      note.label,
      Vector2(size.x / 2, size.y * labelYFrac),
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    _lit = 1.0;
    add(ScaleEffect.to(
      Vector2(1.0, 1.06),
      EffectController(duration: 0.08, alternate: true),
    ));
    onHit(note);
  }
}
