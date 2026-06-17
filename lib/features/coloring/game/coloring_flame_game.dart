import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/audio/sfx.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/coloring_logic.dart';
import '../logic/flood_fill.dart';
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
  final ValueNotifier<Color?> pickedColor = ValueNotifier<Color?>(null);
  final ValueNotifier<int> pictureIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> level = ValueNotifier<int>(1); // уровень сложности
  final ValueNotifier<bool> completed = ValueNotifier<bool>(false);

  /// Активный цвет кисти: выбранный в пикере или из палитры.
  Color get brushColor =>
      pickedColor.value ??
      kColoringPalette[selectedColor.value % kColoringPalette.length];

  /// Доступные уровни сложности раскрасок (с картинками).
  List<int> get coloringLevels => RasterGallery.levels;

  ColoringState? _state;
  bool _finishing = false; // идёт пауза «полюбоваться» до показа панели
  ColoringState? get state => _state;

  /// «Залить» использует растровые картинки `assets/coloring/`, если они есть;
  /// иначе — векторные фигуры (Домик/Цветок). «По номерам» — всегда векторные.
  bool get _useRaster =>
      mode.value == ColoringMode.fill &&
      RasterGallery.imagesForLevel(level.value).isNotEmpty;

  int get _sourceLength => _useRaster
      ? RasterGallery.imagesForLevel(level.value).length
      : ColoringGallery.all.length;

  PaintablePicture get _picture =>
      ColoringGallery.all[pictureIndex.value % ColoringGallery.all.length];

  @override
  Color backgroundColor() => colors.background;

  @override
  Future<void> onLoad() async {
    await RasterGallery.ensureLoaded();
    if (RasterGallery.hasImages) level.value = RasterGallery.levels.first;
    _rebuild();
  }

  void setMode(ColoringMode m) {
    if (mode.value == m) return;
    mode.value = m;
    pictureIndex.value = 0; // источник картинок зависит от режима
    completed.value = false;
    _rebuild();
  }

  void setColor(int i) {
    selectedColor.value = i;
    pickedColor.value = null; // выбор из палитры сбрасывает пикер
  }

  /// Произвольный цвет из колор-пикера.
  void setPickedColor(Color c) => pickedColor.value = c;

  void setPicture(int i) {
    final len = _sourceLength;
    pictureIndex.value = len == 0 ? 0 : i % len;
    completed.value = false;
    _rebuild();
  }

  void nextPicture() => setPicture(pictureIndex.value + 1);

  /// Выбрать уровень сложности раскрасок (папка `assets/coloring/<level>/`).
  void setLevel(int l) {
    if (level.value == l) return;
    level.value = l;
    pictureIndex.value = 0;
    completed.value = false;
    _rebuild();
  }

  /// Сбросить рисунок (заливки или штрихи).
  void clearArt() {
    completed.value = false;
    _finishing = false;
    if (mode.value == ColoringMode.freeDraw) {
      final canvases = children.whereType<_FreeCanvas>().toList();
      if (canvases.isNotEmpty) canvases.first.clearStrokes();
    } else if (_useRaster) {
      final pics = children.whereType<_RasterPicture>().toList();
      if (pics.isNotEmpty) pics.first.reset();
    } else {
      _state?.clear();
    }
  }

  /// Отменить последнее действие (заливку/штрих) в текущем режиме.
  void undo() {
    if (mode.value == ColoringMode.freeDraw) {
      final cs = children.whereType<_FreeCanvas>().toList();
      if (cs.isNotEmpty) cs.first.undoStroke();
    } else if (_useRaster) {
      final pics = children.whereType<_RasterPicture>().toList();
      if (pics.isNotEmpty) pics.first.undo();
    } else {
      _state?.undo();
    }
  }

  /// Вернуть отменённое действие в текущем режиме.
  void redo() {
    if (mode.value == ColoringMode.freeDraw) {
      final cs = children.whereType<_FreeCanvas>().toList();
      if (cs.isNotEmpty) cs.first.redoStroke();
    } else if (_useRaster) {
      final pics = children.whereType<_RasterPicture>().toList();
      if (pics.isNotEmpty) pics.first.redo();
    } else {
      _state?.redo();
    }
  }

  void _rebuild() {
    _finishing = false;
    for (final c in children
        .where((c) => c is _Picture || c is _FreeCanvas || c is _RasterPicture)
        .toList()) {
      c.removeFromParent();
    }
    if (mode.value == ColoringMode.freeDraw) {
      _state = null;
      add(_FreeCanvas(owner: this));
    } else if (_useRaster) {
      _state = null;
      final imgs = RasterGallery.imagesForLevel(level.value);
      add(_RasterPicture(owner: this, asset: imgs[pictureIndex.value % imgs.length]));
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
    if (res.complete && !completed.value && !_finishing) {
      _finishing = true;
      Sfx.play(SfxEvent.complete);
      Haptics.success();
      _burst(Vector2(size.x / 2, size.y * 0.42));
      // Пауза — дать полюбоваться готовой картинкой, затем панель «Красиво!».
      add(TimerComponent(
        period: 1.6,
        removeOnFinish: true,
        onTick: () {
          if (_finishing) completed.value = true;
        },
      ));
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
  final List<_Stroke> _redoStrokes = <_Stroke>[];
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
    _redoStrokes.clear();
    _current = null;
  }

  void undoStroke() {
    if (_strokes.isNotEmpty) _redoStrokes.add(_strokes.removeLast());
    _current = null;
  }

  void redoStroke() {
    if (_redoStrokes.isNotEmpty) _strokes.add(_redoStrokes.removeLast());
    _current = null;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final stroke = _Stroke(owner.brushColor)
      ..points.add(event.localPosition.toOffset());
    _strokes.add(stroke);
    _redoStrokes.clear();
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

/// Растровая раскраска: показывает контурную картинку (`assets/coloring/`) и
/// заливает область по тапу (flood fill). Координаты тапа → пиксель; буфер
/// перекрашивается и пересобирается в [ui.Image]. Завершения нет — свободное
/// раскрашивание (хит-тест/качество заливки проверяются на устройстве).
class _RasterPicture extends PositionComponent with TapCallbacks {
  _RasterPicture({required this.owner, required this.asset});

  final ColoringGame owner;
  final String asset;

  ui.Image? _display;
  Uint8List? _px;
  int _w = 0;
  int _h = 0;
  Rect _imgRect = Rect.zero;
  bool _rebuilding = false;
  final List<_FillStep> _undo = <_FillStep>[];
  final List<_FillStep> _redo = <_FillStep>[];

  @override
  Future<void> onLoad() async {
    size = owner.size;
    await _loadOriginal();
    _layout();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
    _layout();
  }

  Future<void> _loadOriginal() async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      _w = image.width;
      _h = image.height;
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      _px = bytes?.buffer.asUint8List();
      _display = image;
    } catch (_) {
      _px = null;
    }
  }

  void _layout() {
    final s = owner.size;
    final side = (s.x < s.y ? s.x : s.y) * 0.82;
    final fit = Rect.fromCenter(
      center: Offset(s.x / 2, s.y * 0.44),
      width: side,
      height: side,
    );
    if (_w == 0 || _h == 0) {
      _imgRect = fit;
      return;
    }
    final scale =
        (fit.width / _w < fit.height / _h) ? fit.width / _w : fit.height / _h;
    _imgRect = Rect.fromCenter(
      center: fit.center,
      width: _w * scale,
      height: _h * scale,
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) => _imgRect.contains(point.toOffset());

  @override
  void render(Canvas canvas) {
    final img = _display;
    if (img == null) return;
    // Белый «лист» под картинкой: line-art с прозрачным фоном выглядит как бумага.
    final paper = RRect.fromRectAndRadius(_imgRect, const Radius.circular(18));
    canvas.drawRRect(
      paper.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(paper, Paint()..color = const Color(0xFFFFFFFF));
    canvas.save();
    canvas.clipRRect(paper);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
      _imgRect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    final px = _px;
    if (px == null || _rebuilding) return;
    final lp = event.localPosition.toOffset();
    if (!_imgRect.contains(lp)) return;

    final ix = (((lp.dx - _imgRect.left) / _imgRect.width) * _w).floor();
    final iy = (((lp.dy - _imgRect.top) / _imgRect.height) * _h).floor();
    if (ix < 0 || iy < 0 || ix >= _w || iy >= _h) return;
    final startByte = (iy * _w + ix) * 4;
    final pr = px[startByte];
    final pg = px[startByte + 1];
    final pb = px[startByte + 2];

    final argb = owner.brushColor.toARGB32();
    final nr = (argb >> 16) & 0xFF;
    final ng = (argb >> 8) & 0xFF;
    final nb = argb & 0xFF;
    final filled = floodFill(px, _w, _h, ix, iy, r: nr, g: ng, b: nb, tolerance: 72);
    if (filled.isNotEmpty) {
      _undo.add(_FillStep(filled, pr, pg, pb, nr, ng, nb));
      if (_undo.length > 24) _undo.removeAt(0);
      _redo.clear();
      Sfx.play(SfxEvent.tap);
      Haptics.tap();
      _rebuildDisplay();
    } else {
      Sfx.play(SfxEvent.soft);
    }
  }

  void _paint(List<int> indices, int r, int g, int b) {
    final px = _px;
    if (px == null) return;
    for (final p in indices) {
      final i = p * 4;
      px[i] = r;
      px[i + 1] = g;
      px[i + 2] = b;
      px[i + 3] = 255;
    }
  }

  /// Отменить последнюю заливку.
  void undo() {
    if (_px == null || _undo.isEmpty) return;
    final step = _undo.removeLast();
    _paint(step.indices, step.pr, step.pg, step.pb);
    _redo.add(step);
    Haptics.tap();
    _rebuildDisplay();
  }

  /// Вернуть отменённую заливку.
  void redo() {
    if (_px == null || _redo.isEmpty) return;
    final step = _redo.removeLast();
    _paint(step.indices, step.nr, step.ng, step.nb);
    _undo.add(step);
    Haptics.tap();
    _rebuildDisplay();
  }

  void _rebuildDisplay() {
    final px = _px;
    if (px == null) return;
    _rebuilding = true;
    ui.decodeImageFromPixels(px, _w, _h, ui.PixelFormat.rgba8888,
        (ui.Image img) {
      _display = img;
      _rebuilding = false;
    });
  }

  /// Сбросить к исходной картинке (кнопка «Заново»).
  Future<void> reset() async {
    _undo.clear();
    _redo.clear();
    await _loadOriginal();
    _layout();
  }
}

/// Шаг истории растровой заливки: пиксели + прежний и новый цвет (отмена/возврат).
class _FillStep {
  _FillStep(this.indices, this.pr, this.pg, this.pb, this.nr, this.ng, this.nb);
  final List<int> indices;
  final int pr, pg, pb; // прежний цвет
  final int nr, ng, nb; // новый цвет
}
