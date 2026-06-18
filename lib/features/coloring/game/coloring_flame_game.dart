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
  final ValueNotifier<String> category = ValueNotifier<String>(''); // тема раскрасок
  final ValueNotifier<int> level = ValueNotifier<int>(1); // уровень сложности
  final ValueNotifier<bool> completed = ValueNotifier<bool>(false);

  /// Инструмент в режиме «Раскрасить» и толщина мазка (0..2).
  final ValueNotifier<PaintTool> tool = ValueNotifier<PaintTool>(PaintTool.fill);
  final ValueNotifier<int> brushSize = ValueNotifier<int>(1);

  /// Активный цвет кисти: выбранный в пикере или из палитры.
  Color get brushColor =>
      pickedColor.value ??
      kColoringPalette[selectedColor.value % kColoringPalette.length];

  /// Доступные темы раскрасок (с картинками).
  List<String> get coloringCategories => RasterGallery.categories;

  /// Доступные уровни сложности в текущей теме (с картинками).
  List<int> get coloringLevels => RasterGallery.levelsFor(category.value);

  /// Картинки текущей темы по порядку уровня — для пикера (карусели).
  List<ColoringPick> picksForCurrentCategory() => <ColoringPick>[
        for (final lvl in RasterGallery.levelsFor(category.value))
          for (final asset in RasterGallery.imagesFor(category.value, lvl))
            ColoringPick(asset: asset, level: lvl),
      ];

  /// Можно ли открыть пикер картинок (есть растровые картинки в режиме «Залить»).
  bool get canPickRaster =>
      mode.value == ColoringMode.fill && picksForCurrentCategory().isNotEmpty;

  /// Текущий выбранный ассет (подсветка в пикере), либо null (векторный режим).
  String? get currentAsset {
    if (!_useRaster) return null;
    final imgs = RasterGallery.imagesFor(category.value, level.value);
    return imgs.isEmpty ? null : imgs[pictureIndex.value % imgs.length];
  }

  ColoringState? _state;
  bool _finishing = false; // идёт пауза «полюбоваться» до показа панели
  ColoringState? get state => _state;

  /// «Залить» использует растровые картинки `assets/coloring/`, если они есть;
  /// иначе — векторные фигуры (Домик/Цветок). «По номерам» — всегда векторные.
  bool get _useRaster =>
      mode.value == ColoringMode.fill &&
      RasterGallery.imagesFor(category.value, level.value).isNotEmpty;

  int get _sourceLength => _useRaster
      ? RasterGallery.imagesFor(category.value, level.value).length
      : ColoringGallery.all.length;

  PaintablePicture get _picture =>
      ColoringGallery.all[pictureIndex.value % ColoringGallery.all.length];

  @override
  Color backgroundColor() => colors.background;

  @override
  Future<void> onLoad() async {
    await RasterGallery.ensureLoaded();
    if (RasterGallery.hasImages) {
      category.value = RasterGallery.categories.first;
      final levels = RasterGallery.levelsFor(category.value);
      if (levels.isNotEmpty) level.value = levels.first;
    }
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

  void setTool(PaintTool t) => tool.value = t;
  void setBrushSize(int i) => brushSize.value = i < 0 ? 0 : (i > 2 ? 2 : i);

  void setPicture(int i) {
    final len = _sourceLength;
    pictureIndex.value = len == 0 ? 0 : i % len;
    completed.value = false;
    _rebuild();
  }

  void nextPicture() => setPicture(pictureIndex.value + 1);

  /// Выбрать тему раскрасок (`assets/coloring/<тема>/`). Сбрасывает уровень на
  /// первый доступный в новой теме.
  void setCategory(String c) {
    if (category.value == c) return;
    category.value = c;
    final levels = RasterGallery.levelsFor(c);
    level.value = levels.isEmpty ? 1 : levels.first;
    pictureIndex.value = 0;
    completed.value = false;
    _rebuild();
  }

  /// Выбрать уровень сложности раскрасок в текущей теме
  /// (`assets/coloring/<тема>/<level>/`).
  void setLevel(int l) {
    if (level.value == l) return;
    level.value = l;
    pictureIndex.value = 0;
    completed.value = false;
    _rebuild();
  }

  /// Выбрать конкретную картинку из пикера: ставит её уровень и индекс в уровне.
  void selectRasterPicture(int lvl, String asset) {
    final imgs = RasterGallery.imagesFor(category.value, lvl);
    final idx = imgs.indexOf(asset);
    if (idx < 0) return;
    level.value = lvl;
    pictureIndex.value = idx;
    completed.value = false;
    _rebuild();
  }

  // ── Ввод растрового холста (от хост-Listener; 1 палец рисует) ───────────────
  _RasterPicture? get _raster {
    final list = children.whereType<_RasterPicture>();
    return list.isEmpty ? null : list.first;
  }

  /// Можно ли рисовать по растровой картинке (режим «Раскрасить» с картинкой).
  bool get canPaintRaster => mode.value == ColoringMode.fill && _raster != null;

  void canvasDown(Offset local) =>
      _raster?.beginStroke(local, tool.value, brushColor, brushSize.value);
  void canvasMove(Offset local) =>
      _raster?.extendStroke(local, tool.value, brushColor, brushSize.value);
  void canvasUp() => _raster?.endStroke();
  void canvasCancel() => _raster?.cancelStroke();

  void zoomBegin(Offset focal) => _raster?.zoomBegin(focal);
  void zoomUpdate(double factor, Offset focal) =>
      _raster?.zoomUpdate(factor, focal);

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
      final imgs = RasterGallery.imagesFor(category.value, level.value);
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

// ── Параметры кистей (подобраны «на глаз», легко править на устройстве) ───────
const int _kMaskTolerance = 72; // тот же порог, что у заливки

/// Прозрачность мазка по инструменту (0..1). Акварель — низкая (копится слоями).
double _toolAlpha(PaintTool t) {
  switch (t) {
    case PaintTool.pencil:
      return 0.90;
    case PaintTool.marker:
      return 0.85;
    case PaintTool.watercolor:
      return 0.16;
    case PaintTool.gouache:
      return 0.80;
    case PaintTool.fill:
      return 1.0;
  }
}

/// Вес мазка от центра (1) к краю (0) — «мягкость» кисти ([d2]/[r2] — квадраты).
double _toolEdge(PaintTool t, double d2, double r2) {
  final dist = r2 <= 0 ? 0.0 : sqrt(d2 / r2); // 0 центр .. 1 край
  switch (t) {
    case PaintTool.pencil:
      return dist <= 0.85 ? 1.0 : 0.0; // жёсткий край
    case PaintTool.marker:
      return dist <= 0.90 ? 1.0 : (1 - dist) / 0.10; // почти жёсткий
    case PaintTool.gouache:
      return dist <= 0.80 ? 1.0 : (1 - dist) / 0.20; // плотный, лёгкое перо
    case PaintTool.watercolor:
      return (1 - dist) * (1 - dist); // мягкая растушёвка
    case PaintTool.fill:
      return 1.0;
  }
}

/// Растровая раскраска «Раскрасить»: контурная картинка + инструменты [PaintTool].
/// Заливка — по тапу; кисти (карандаш/маркер/акварель/гуашь) кладут мазки ТОЛЬКО
/// внутри области, по которой ведёт малыш ([regionMask] по исходному line-art →
/// «удержание в контуре»: неровные движения остаются аккуратными). Ввод приходит
/// от хост-Listener. Перерисовка дросселируется в [update].
class _RasterPicture extends PositionComponent {
  _RasterPicture({required this.owner, required this.asset});

  final ColoringGame owner;
  final String asset;

  ui.Image? _display;
  Uint8List? _orig; // пристина line-art (для масок областей)
  Uint8List? _px; // рабочий буфер (рисуем и показываем)
  int _w = 0;
  int _h = 0;
  Rect _baseRect = Rect.zero; // «лист», куда картинка вписана при зуме 1.0

  // Вид (зум/панорама): 2 пальца. 1.0 / ноль — без зума.
  double _scale = 1;
  Offset _pan = Offset.zero;
  double _zStartScale = 1;
  Offset _zStartFrac = const Offset(0.5, 0.5); // доля картинки под фокусом жеста

  bool _decoding = false;
  bool _dirty = false;

  // Активный мазок кистью.
  Uint8List? _mask;
  bool _stroking = false;
  int _lastIx = 0;
  int _lastIy = 0;
  Map<int, int> _before = <int, int>{};
  Map<int, int> _after = <int, int>{};

  final List<_PaintStep> _undo = <_PaintStep>[];
  final List<_PaintStep> _redo = <_PaintStep>[];
  static const int _maxUndo = 10;

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
      final view = bytes?.buffer.asUint8List();
      if (view != null) {
        _orig = Uint8List.fromList(view);
        _px = Uint8List.fromList(view);
      }
      _display = image;
    } catch (_) {
      _orig = null;
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
      _baseRect = fit;
      return;
    }
    final scale =
        (fit.width / _w < fit.height / _h) ? fit.width / _w : fit.height / _h;
    _baseRect = Rect.fromCenter(
      center: fit.center,
      width: _w * scale,
      height: _h * scale,
    );
  }

  Rect get _drawRect => (_scale == 1 && _pan == Offset.zero)
      ? _baseRect
      : Rect.fromCenter(
          center: _baseRect.center + _pan,
          width: _baseRect.width * _scale,
          height: _baseRect.height * _scale,
        );

  /// Пиксель картинки под точкой холста [p] (с учётом зума) либо null.
  (int, int)? _pixelAt(Offset p) {
    if (_w == 0 || !_baseRect.contains(p)) return null;
    final dr = _drawRect;
    final fx = (p.dx - dr.left) / dr.width;
    final fy = (p.dy - dr.top) / dr.height;
    if (fx < 0 || fy < 0 || fx >= 1 || fy >= 1) return null;
    return ((fx * _w).floor(), (fy * _h).floor());
  }

  // ── Зум/панорама (2 пальца) ──────────────────────────────────────────────────

  void zoomBegin(Offset focal) {
    _zStartScale = _scale;
    final dr = _drawRect;
    if (dr.width <= 0 || dr.height <= 0) {
      _zStartFrac = const Offset(0.5, 0.5);
      return;
    }
    _zStartFrac = Offset(
      ((focal.dx - dr.left) / dr.width).clamp(0.0, 1.0).toDouble(),
      ((focal.dy - dr.top) / dr.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  /// [factor] — отношение текущего расстояния между пальцами к стартовому.
  /// Держим точку под фокусом на месте; «лист» не отрывается от краёв.
  void zoomUpdate(double factor, Offset focal) {
    final newScale = (_zStartScale * factor).clamp(1.0, 4.0).toDouble();
    final newW = _baseRect.width * newScale;
    final newH = _baseRect.height * newScale;
    final left = focal.dx - _zStartFrac.dx * newW;
    final top = focal.dy - _zStartFrac.dy * newH;
    final pan = Offset(left + newW / 2, top + newH / 2) - _baseRect.center;
    final maxX = _baseRect.width * (newScale - 1) / 2;
    final maxY = _baseRect.height * (newScale - 1) / 2;
    _scale = newScale;
    _pan = Offset(
      pan.dx.clamp(-maxX, maxX).toDouble(),
      pan.dy.clamp(-maxY, maxY).toDouble(),
    );
  }

  double _dabRadius(PaintTool t, int sizeIdx) {
    final imgMin = (_w < _h ? _w : _h).toDouble();
    const frac = <double>[0.012, 0.020, 0.030]; // S / M / L (доля картинки)
    const k = <PaintTool, double>{
      PaintTool.pencil: 0.55,
      PaintTool.marker: 1.20,
      PaintTool.watercolor: 1.50,
      PaintTool.gouache: 1.10,
      PaintTool.fill: 1.0,
    };
    final si = sizeIdx < 0 ? 0 : (sizeIdx > 2 ? 2 : sizeIdx);
    return frac[si] * imgMin * (k[t] ?? 1.0);
  }

  // ── Ввод (от хоста) ─────────────────────────────────────────────────────────

  void beginStroke(Offset local, PaintTool t, Color color, int sizeIdx) {
    final orig = _orig;
    if (orig == null || _px == null) return;
    final pix = _pixelAt(local);
    if (pix == null) return;
    final (ix, iy) = pix;
    if (t == PaintTool.fill) {
      _fillRegion(ix, iy, color);
      return;
    }
    final mask = regionMask(orig, _w, _h, ix, iy, tolerance: _kMaskTolerance);
    if (mask[iy * _w + ix] == 0) {
      Sfx.play(SfxEvent.soft); // попали на контур — мазок не начинаем
      return;
    }
    _mask = mask;
    _stroking = true;
    _before = <int, int>{};
    _after = <int, int>{};
    _lastIx = ix;
    _lastIy = iy;
    _dab(ix, iy, t, color, sizeIdx);
    Sfx.play(SfxEvent.tap);
    Haptics.tap();
    _dirty = true;
  }

  void extendStroke(Offset local, PaintTool t, Color color, int sizeIdx) {
    if (!_stroking) return;
    final pix = _pixelAt(local);
    if (pix == null) return;
    final (ix, iy) = pix;
    _dabLine(_lastIx, _lastIy, ix, iy, t, color, sizeIdx);
    _lastIx = ix;
    _lastIy = iy;
    _dirty = true;
  }

  void endStroke() {
    if (!_stroking) return;
    _stroking = false;
    _mask = null;
    if (_before.isNotEmpty) _pushUndo(_PaintStep(_before, _after));
    _before = <int, int>{};
    _after = <int, int>{};
  }

  /// Откатить незавершённый мазок (напр. лёг второй палец → пойдёт зум).
  void cancelStroke() {
    if (!_stroking) return;
    _stroking = false;
    _mask = null;
    final px = _px;
    if (px != null) {
      _before.forEach((p, packed) => _writePacked(px, p, packed));
      _dirty = true;
    }
    _before = <int, int>{};
    _after = <int, int>{};
  }

  void _fillRegion(int ix, int iy, Color color) {
    final px = _px;
    final orig = _orig;
    if (px == null || orig == null) return;
    final mask = regionMask(orig, _w, _h, ix, iy, tolerance: _kMaskTolerance);
    if (mask[iy * _w + ix] == 0) {
      Sfx.play(SfxEvent.soft);
      return;
    }
    final argb = color.toARGB32();
    final nr = (argb >> 16) & 0xFF;
    final ng = (argb >> 8) & 0xFF;
    final nb = argb & 0xFF;
    final newPacked = (nr << 16) | (ng << 8) | nb;
    final before = <int, int>{};
    final after = <int, int>{};
    final n = _w * _h;
    for (var p = 0; p < n; p++) {
      if (mask[p] == 0) continue;
      final i = p * 4;
      final old = (px[i] << 16) | (px[i + 1] << 8) | px[i + 2];
      if (old == newPacked) continue;
      before[p] = old;
      px[i] = nr;
      px[i + 1] = ng;
      px[i + 2] = nb;
      px[i + 3] = 255;
      after[p] = newPacked;
    }
    if (before.isNotEmpty) {
      _pushUndo(_PaintStep(before, after));
      Sfx.play(SfxEvent.tap);
      Haptics.tap();
      _dirty = true;
    }
  }

  void _dab(int cx, int cy, PaintTool t, Color color, int sizeIdx) {
    final px = _px;
    final mask = _mask;
    if (px == null || mask == null) return;
    final r = _dabRadius(t, sizeIdx).round();
    if (r < 1) return;
    final r2 = (r * r).toDouble();
    final baseA = _toolAlpha(t);
    final argb = color.toARGB32();
    final br = (argb >> 16) & 0xFF;
    final bg = (argb >> 8) & 0xFF;
    final bb = argb & 0xFF;
    final x0 = max(0, cx - r);
    final x1 = min(_w - 1, cx + r);
    final y0 = max(0, cy - r);
    final y1 = min(_h - 1, cy + r);
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final ddx = (x - cx).toDouble();
        final ddy = (y - cy).toDouble();
        final d2 = ddx * ddx + ddy * ddy;
        if (d2 > r2) continue;
        final p = y * _w + x;
        if (mask[p] == 0) continue;
        final a = baseA * _toolEdge(t, d2, r2);
        if (a <= 0) continue;
        final i = p * 4;
        _before.putIfAbsent(
            p, () => (px[i] << 16) | (px[i + 1] << 8) | px[i + 2]);
        px[i] = (px[i] * (1 - a) + br * a).round();
        px[i + 1] = (px[i + 1] * (1 - a) + bg * a).round();
        px[i + 2] = (px[i + 2] * (1 - a) + bb * a).round();
        px[i + 3] = 255;
        _after[p] = (px[i] << 16) | (px[i + 1] << 8) | px[i + 2];
      }
    }
  }

  void _dabLine(
      int x0, int y0, int x1, int y1, PaintTool t, Color color, int sizeIdx) {
    final r = _dabRadius(t, sizeIdx);
    final spacing = (r * 0.35) < 1.0 ? 1.0 : r * 0.35;
    final dx = (x1 - x0).toDouble();
    final dy = (y1 - y0).toDouble();
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < spacing) {
      _dab(x1, y1, t, color, sizeIdx);
      return;
    }
    final steps = (dist / spacing).ceil();
    for (var s = 1; s <= steps; s++) {
      final f = s / steps;
      _dab((x0 + dx * f).round(), (y0 + dy * f).round(), t, color, sizeIdx);
    }
  }

  // ── Отмена / возврат / сброс ────────────────────────────────────────────────

  void undo() {
    if (_undo.isEmpty) return;
    final step = _undo.removeLast();
    _applyPacked(step.before);
    _redo.add(step);
    Haptics.tap();
    _dirty = true;
  }

  void redo() {
    if (_redo.isEmpty) return;
    final step = _redo.removeLast();
    _applyPacked(step.after);
    _undo.add(step);
    Haptics.tap();
    _dirty = true;
  }

  Future<void> reset() async {
    _undo.clear();
    _redo.clear();
    final orig = _orig;
    if (orig != null) {
      _px = Uint8List.fromList(orig);
      _dirty = true;
    } else {
      await _loadOriginal();
      _layout();
    }
  }

  void _pushUndo(_PaintStep step) {
    _undo.add(step);
    if (_undo.length > _maxUndo) _undo.removeAt(0);
    _redo.clear();
  }

  void _applyPacked(Map<int, int> m) {
    final px = _px;
    if (px == null) return;
    m.forEach((p, packed) => _writePacked(px, p, packed));
  }

  void _writePacked(Uint8List px, int p, int packed) {
    final i = p * 4;
    px[i] = (packed >> 16) & 0xFF;
    px[i + 1] = (packed >> 8) & 0xFF;
    px[i + 2] = packed & 0xFF;
    px[i + 3] = 255;
  }

  // ── Рендер ──────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_dirty && !_decoding) {
      final px = _px;
      if (px == null) {
        _dirty = false;
        return;
      }
      _dirty = false;
      _decoding = true;
      ui.decodeImageFromPixels(px, _w, _h, ui.PixelFormat.rgba8888,
          (ui.Image img) {
        _display = img;
        _decoding = false;
      });
    }
  }

  @override
  void render(Canvas canvas) {
    final img = _display;
    if (img == null) return;
    // Белый «лист»: line-art с прозрачным фоном выглядит как бумага.
    final paper = RRect.fromRectAndRadius(_baseRect, const Radius.circular(18));
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
      _drawRect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }
}

/// Шаг истории растрового рисования: упакованные RGB (0xRRGGBB) до/после по
/// затронутым пикселям. [before] — для отмены, [after] — для возврата.
class _PaintStep {
  _PaintStep(this.before, this.after);
  final Map<int, int> before;
  final Map<int, int> after;
}
