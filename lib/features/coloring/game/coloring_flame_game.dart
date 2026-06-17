import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/sfx.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/coloring_logic.dart';
import 'coloring_pictures.dart';

/// Flame-холст «Раскраска»: три режима за переключателем.
/// - [ColoringMode.fill] — тап по области → выбранный цвет (свободно);
/// - [ColoringMode.byNumber] — область принимает только свой цвет (мягко);
/// - [ColoringMode.freeDraw] — рисование пальцем по чистому холсту.
///
/// Чистая модель заливки — в [ColoringState]; здесь геометрия, хит-тест и «сок».
/// «Без проигрышей»: ошибиться нельзя, завершение — «Готово! Красиво!».
class ColoringGame extends FlameGame {
  ColoringGame({required this.colors, Random? random}) : _rng = random ?? Random();

  final AppColors colors;
  final Random _rng;

  /// Текущий режим, выбранный цвет (индекс палитры), картинка и факт завершения.
  final ValueNotifier<ColoringMode> mode =
      ValueNotifier<ColoringMode>(ColoringMode.fill);
  final ValueNotifier<int> selectedColor = ValueNotifier<int>(0);
  final ValueNotifier<int> pictureIndex = ValueNotifier<int>(0);
  final ValueNotifier<bool> completed = ValueNotifier<bool>(false);

  ColoringState? _state;
  ColoringState? get state => _state;

  PaintablePicture get _picture => ColoringGallery.all[pictureIndex.value];

  @override
  Color backgroundColor() => colors.background;

  @override
  Future<void> onLoad() async => _rebuild();

  void setMode(ColoringMode m) {
    if (mode.value == m) return;
    mode.value = m;
    completed.value = false;
    _rebuild();
  }

  void setColor(int i) => selectedColor.value = i;

  void setPicture(int i) {
    pictureIndex.value = i % ColoringGallery.all.length;
    completed.value = false;
    _rebuild();
  }

  void nextPicture() => setPicture(pictureIndex.value + 1);

  /// Сбросить рисунок (заливки или штрихи).
  void clearArt() {
    completed.value = false;
    if (mode.value == ColoringMode.freeDraw) {
      final canvases = children.whereType<_FreeCanvas>().toList();
      if (canvases.isNotEmpty) canvases.first.clearStrokes();
    } else {
      _state?.clear();
    }
  }

  void _rebuild() {
    for (final c in children
        .where((c) => c is _Picture || c is _FreeCanvas)
        .toList()) {
      c.removeFromParent();
    }
    if (mode.value == ColoringMode.freeDraw) {
      _state = null;
      add(_FreeCanvas(owner: this));
    } else {
      _state = ColoringState(_picture.toModel(), mode: mode.value);
      add(_Picture(owner: this, picture: _picture));
    }
  }

  /// Тап по области (зовётся компонентом области).
  void onRegionTap(int id) {
    final st = _state;
    if (st == null) return;
    final res = st.fill(id, selectedColor.value);
    if (!res.applied) {
      Sfx.play(SfxEvent.soft); // «по номерам»: не тот цвет — мягко
      return;
    }
    Sfx.play(SfxEvent.tap);
    Haptics.tap();
    if (res.complete && !completed.value) {
      completed.value = true;
      Sfx.play(SfxEvent.complete);
      Haptics.success();
      _burst(Vector2(size.x / 2, size.y * 0.42));
    }
  }

  void _burst(Vector2 at) {
    final palette = <Color>[colors.accent, colors.primary, colors.secondary, colors.success];
    final particle = Particle.generate(
      count: 26,
      generator: (int i) {
        final angle = _rng.nextDouble() * pi * 2;
        final speed = 90 + _rng.nextDouble() * 180;
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

/// Контейнер картинки: строит области под квадрат [fit], центрированный чуть
/// выше середины (снизу — палитра в оверлее). Перестраивается при ресайзе.
class _Picture extends PositionComponent {
  _Picture({required this.owner, required this.picture});

  final ColoringGame owner;
  final PaintablePicture picture;

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
    final side = min(s.x, s.y) * 0.82;
    final fit = Rect.fromCenter(
      center: Offset(s.x / 2, s.y * 0.44),
      width: side,
      height: side,
    );
    for (final r in picture.regions) {
      add(_Region(
        owner: owner,
        regionId: r.id,
        targetColor: r.targetColor,
        path: r.build(fit),
        labelPos: Vector2(
          fit.left + fit.width * r.labelFrac.dx,
          fit.top + fit.height * r.labelFrac.dy,
        ),
        numberSize: side * 0.07,
        gameSize: s,
      )..priority = r.priority);
    }
  }
}

/// Область картинки: хит-тест по [Path]; заливается цветом из [ColoringState].
class _Region extends PositionComponent with TapCallbacks {
  _Region({
    required this.owner,
    required this.regionId,
    required this.targetColor,
    required this.path,
    required this.labelPos,
    required this.numberSize,
    required Vector2 gameSize,
  }) : super(size: gameSize);

  final ColoringGame owner;
  final int regionId;
  final int targetColor;
  final Path path;
  final Vector2 labelPos;
  final double numberSize;
  late final TextPaint _num;

  @override
  Future<void> onLoad() async {
    _num = TextPaint(
      style: TextStyle(
        fontSize: numberSize,
        fontWeight: FontWeight.w900,
        color: owner.colors.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) => path.contains(point.toOffset());

  @override
  void render(Canvas canvas) {
    final idx = owner.state?.colorOf(regionId);
    final fill = idx == null
        ? owner.colors.surface
        : kColoringPalette[idx % kColoringPalette.length];
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = owner.colors.onSurface.withValues(alpha: 0.55),
    );
    if (owner.mode.value == ColoringMode.byNumber && idx == null) {
      _num.render(canvas, '${targetColor + 1}', labelPos, anchor: Anchor.center);
    }
  }

  @override
  void onTapDown(TapDownEvent event) => owner.onRegionTap(regionId);
}

/// Один штрих свободного рисования.
class _Stroke {
  _Stroke(this.color);
  final Color color;
  final List<Offset> points = <Offset>[];
}

/// Чистый холст: рисование пальцем. Штрихи накапливаются и рисуются полилиниями.
class _FreeCanvas extends PositionComponent with DragCallbacks {
  _FreeCanvas({required this.owner});

  final ColoringGame owner;
  final List<_Stroke> _strokes = <_Stroke>[];
  _Stroke? _current;

  @override
  Future<void> onLoad() async {
    size = owner.size;
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }

  void clearStrokes() {
    _strokes.clear();
    _current = null;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final stroke = _Stroke(
      kColoringPalette[owner.selectedColor.value % kColoringPalette.length],
    )..points.add(event.localPosition.toOffset());
    _strokes.add(stroke);
    _current = stroke;
    Haptics.tap();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _current?.points.add(event.localEndPosition.toOffset());
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _current = null;
  }

  @override
  void render(Canvas canvas) {
    final w = (size.x * 0.018).clamp(4.0, 12.0).toDouble();
    for (final s in _strokes) {
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, w / 2, Paint()..color = s.color);
        continue;
      }
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }
}
