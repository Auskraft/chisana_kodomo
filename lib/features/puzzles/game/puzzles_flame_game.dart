import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../../../core/audio/sfx.dart';
import '../../../core/feedback/haptics.dart';
import '../../../core/praise/praise.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/puzzles_logic.dart';

/// Фаза экрана игры «Пазлы».
enum PuzzlePhase { ready, playing, setDone }

/// Пользовательские картинки-пазлы `assets/puzzles/*.png|jpg`. Если папка пуста —
/// игра режет эмодзи. Список читается из манифеста один раз; картинки грузятся
/// по одной (в памяти — только текущая). Картинки лучше **квадратные**.
abstract final class PuzzlePictures {
  static List<String> _assets = const <String>[];
  static bool _loaded = false;

  static bool get hasImages => _assets.isNotEmpty;
  static List<String> get assets => _assets;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = <String>[
        for (final k in manifest.listAssets())
          if (k.startsWith('assets/puzzles/') &&
              (k.toLowerCase().endsWith('.png') ||
                  k.toLowerCase().endsWith('.jpg') ||
                  k.toLowerCase().endsWith('.jpeg')))
            k,
      ]..sort();
    } catch (_) {
      _assets = const <String>[];
    }
  }

  static Future<ui.Image?> load(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }
}

/// Flame-игра «Пазлы»: большая эмодзи-картинка режется на сетку кусочков; малыш
/// перетаскивает кусочки из лотка на доску-«призрак». Кусочек встаёт только на
/// свою ячейку (защёлк + «сок»); мимо — мягкий «пуф» и возврат. Пауза (`isPaused`),
/// «без проигрышей» (промах лишь считается). За набор — несколько картинок.
///
/// Чистая логика размещений — в [PuzzleSession]; здесь рендер, голос (через
/// [onSay]) и поощрение. Состояние наружу — через нотифаеры (для оверлеев хоста).
class PuzzlesGame extends FlameGame {
  PuzzlesGame({
    required this.set,
    required this.colors,
    this.onSay,
    this.setDonePhrase = 'Молодец! Всё получилось!',
    Random? random,
  }) : _rng = random ?? Random();

  final PuzzleSet set;
  final AppColors colors;

  /// Голосовой хук (хост подключает к `Voice.instance.say`).
  final void Function(String text, {bool flush})? onSay;

  /// Финальная похвала за набор (согласована по полу — задаёт хост).
  final String setDonePhrase;

  final Random _rng;

  late PuzzleSession _session;
  String? _lastEmoji;
  String? _lastAsset;
  int _buildGen = 0; // версия сборки картинки — гасит устаревшие async-загрузки

  final ValueNotifier<PuzzlePhase> phase = ValueNotifier<PuzzlePhase>(
    PuzzlePhase.ready,
  );
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);

  /// Номер текущей картинки в наборе (1-based) — для HUD.
  final ValueNotifier<int> pictureNumber = ValueNotifier<int>(1);
  final ValueNotifier<int> earnedStars = ValueNotifier<int>(0);

  static const List<String> _emojiPool = <String>[
    '🍎', '🐶', '🚗', '⭐', '🐱', '🌸', '🐟', '🎈',
    '🍓', '🦋', '🐢', '🌈', '🐤', '🍉', '🚀', '🌞',
  ];

  /// Сколько картинок собрать в наборе: у мелких сеток больше, у крупных меньше —
  /// чтобы сессия оставалась посильной по числу перетаскиваний.
  int get picturesPerSet {
    final p = set.pieces;
    if (p <= 4) return 4;
    if (p <= 9) return 3;
    return 2;
  }

  bool get _active => phase.value == PuzzlePhase.playing && !isPaused.value;

  @override
  Color backgroundColor() => colors.background;

  @override
  Future<void> onLoad() async {
    await PuzzlePictures.ensureLoaded();
  }

  /// Начать/перезапустить набор (новая сессия, первая картинка).
  void start() {
    _session = PuzzleSession(set, random: _rng);
    pictureNumber.value = 1;
    phase.value = PuzzlePhase.playing;
    isPaused.value = false;
    paused = false;
    unawaited(_buildPicture(announce: true));
  }

  void togglePause() {
    if (phase.value != PuzzlePhase.playing) return;
    isPaused.value = !isPaused.value;
    paused = isPaused.value;
  }

  void resume() {
    if (!isPaused.value) return;
    isPaused.value = false;
    paused = false;
  }

  // ── Картинки набора ───────────────────────────────────────────────────────

  String _pickEmoji() {
    String e;
    do {
      e = _emojiPool[_rng.nextInt(_emojiPool.length)];
    } while (e == _lastEmoji && _emojiPool.length > 1);
    _lastEmoji = e;
    return e;
  }

  String _pickAsset() {
    final list = PuzzlePictures.assets;
    String a;
    do {
      a = list[_rng.nextInt(list.length)];
    } while (a == _lastAsset && list.length > 1);
    _lastAsset = a;
    return a;
  }

  /// Нарисовать эмодзи в квадратную картинку [px]×[px] (синхронно — без ожидания).
  ui.Image _renderEmojiImage(String emoji, int px) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: px * 0.82)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((px - tp.width) / 2, (px - tp.height) / 2));
    return recorder.endRecording().toImageSync(px, px);
  }

  /// Построить картинку: пользовательский PNG (если есть) или эмодзи-запас.
  /// Async из-за загрузки PNG; [_buildGen] гасит устаревшие вызовы (рестарт/выход).
  Future<void> _buildPicture({bool announce = false}) async {
    final gen = ++_buildGen;
    ui.Image img;
    if (PuzzlePictures.hasImages) {
      final loaded = await PuzzlePictures.load(_pickAsset());
      if (gen != _buildGen || !isMounted) {
        loaded?.dispose();
        return;
      }
      img = loaded ?? _renderEmojiImage(_pickEmoji(), 600);
    } else {
      img = _renderEmojiImage(_pickEmoji(), 600);
    }
    if (gen != _buildGen || !isMounted) {
      img.dispose();
      return;
    }
    _clearSurface();
    add(_PuzzleSurface(owner: this, image: img));
    onSay?.call('Собери картинку!', flush: announce);
  }

  // ── Ввод (зовётся поверхностью) ───────────────────────────────────────────

  /// Кусочек встал на своё место.
  void onPiecePlaced(Vector2 at, {required bool isComplete}) {
    Sfx.play(SfxEvent.correct);
    _burst(at);
    if (isComplete) {
      Haptics.success(); // тёплый «успех» — за собранную картинку
      if (pictureNumber.value < picturesPerSet) {
        onSay?.call(Praise.pick(_rng));
      }
      add(TimerComponent(period: 1.3, removeOnFinish: true, onTick: _advance));
    } else {
      Haptics.select(); // лёгкий клик — за кусочек
    }
  }

  /// Кусочек уронили мимо своей ячейки (на доску) — мягко, без штрафа.
  void onWrongDrop() {
    Sfx.play(SfxEvent.soft);
    Haptics.tap();
  }

  void _advance() {
    if (pictureNumber.value >= picturesPerSet) {
      _finishSet();
    } else {
      pictureNumber.value += 1;
      _session.nextPicture();
      unawaited(_buildPicture());
    }
  }

  void _finishSet() {
    _clearSurface();
    earnedStars.value = PuzzleSet.starsForMistakes(_session.mistakes, set.pieces);
    Sfx.play(SfxEvent.complete);
    onSay?.call(setDonePhrase);
    phase.value = PuzzlePhase.setDone;
  }

  void _clearSurface() {
    for (final c in children.whereType<_PuzzleSurface>().toList()) {
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
      count: 22,
      generator: (int i) {
        final angle = _rng.nextDouble() * pi * 2;
        final speed = 90 + _rng.nextDouble() * 160;
        return AcceleratedParticle(
          acceleration: Vector2(0, 240),
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

/// Поверхность игры: рисует доску-«призрак» (бледная картинка-образец + сетка) и
/// держит кусочки (как детей). Полноэкранный [DragCallbacks]-компонент сам ловит
/// перетаскивание и хит-тестит кусочки (координаты — в его системе, = экранные).
class _PuzzleSurface extends PositionComponent with DragCallbacks {
  _PuzzleSurface({required this.owner, required this.image});

  final PuzzlesGame owner;
  final ui.Image image;

  final List<_Piece> _pieces = <_Piece>[];
  _Piece? _grabbed;
  Vector2 _grabOffset = Vector2.zero();

  // Геометрия доски (заполняется в _layout).
  double _boardLeft = 0;
  double _boardTop = 0;
  double _boardSide = 0;
  double _cellW = 1;
  double _cellH = 1;

  @override
  Future<void> onLoad() async {
    size = owner.size;
    _layout();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
    if (isMounted) _layout();
  }

  @override
  void onRemove() {
    image.dispose();
    super.onRemove();
  }

  Rect get _boardRect =>
      Rect.fromLTWH(_boardLeft, _boardTop, _boardSide, _boardSide);

  void _layout() {
    for (final p in _pieces) {
      p.removeFromParent();
    }
    _pieces.clear();
    _grabbed = null;

    final s = owner.size;
    final cols = owner.set.cols;
    final rows = owner.set.rows;
    final pieces = owner.set.pieces;

    final hudPad = s.y * 0.1; // верх: место под HUD (набор/пауза)
    final bottomPad = s.y * 0.05; // низ: чтобы лоток не липнул к краю
    final boardGap = s.y * 0.04; // между доской и лотком
    final trayGap = s.x * 0.025; // зазор между кусочками в лотке (чтоб не слипались)
    final trayAreaW = s.x * 0.96;
    final avail = s.y - hudPad - bottomPad;

    // Доска — на 15% меньше прежнего максимума; дальше ужимаем, только если
    // доска + лоток не влезают в доступную высоту.
    var side = min(s.x * 0.92, s.y * 0.5) * 0.85;
    var cellW = side / cols;
    var cellH = side / rows;
    var trayCols = max(1, ((trayAreaW + trayGap) / (cellW + trayGap)).floor());
    var trayRows = (pieces / trayCols).ceil();
    var contentH = side + boardGap + trayRows * cellH + (trayRows - 1) * trayGap;
    for (var attempt = 0; attempt < 40; attempt++) {
      cellW = side / cols;
      cellH = side / rows;
      trayCols = max(1, ((trayAreaW + trayGap) / (cellW + trayGap)).floor());
      trayRows = (pieces / trayCols).ceil();
      contentH = side + boardGap + trayRows * cellH + (trayRows - 1) * trayGap;
      if (contentH <= avail) break;
      side *= 0.94;
    }

    // Блок «доска + лоток» центрируем по вертикали между HUD и низом — доска
    // опускается от верха, лоток поднимается от низа.
    final startY = hudPad + (avail - contentH) / 2;
    final trayTop = startY + side + boardGap;

    _boardSide = side;
    _boardLeft = (s.x - side) / 2;
    _boardTop = startY;
    _cellW = cellW;
    _cellH = cellH;

    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final order = owner._session.trayOrder;

    for (var slot = 0; slot < order.length; slot++) {
      final piece = order[slot]; // id кусочка = индекс его домашней ячейки
      final r = piece ~/ cols;
      final c = piece % cols;
      final src = Rect.fromLTWH(c * iw / cols, r * ih / rows, iw / cols, ih / rows);
      final homeCenter = Vector2(
        _boardLeft + c * _cellW + _cellW / 2,
        _boardTop + r * _cellH + _cellH / 2,
      );
      final tr = slot ~/ trayCols;
      final tc = slot % trayCols;
      // Центрируем каждый ряд лотка (последний может быть неполным) + зазор.
      final inRow = min(trayCols, order.length - tr * trayCols);
      final rowW = inRow * cellW + (inRow - 1) * trayGap;
      final trayCenter = Vector2(
        (s.x - rowW) / 2 + tc * (cellW + trayGap) + cellW / 2,
        trayTop + tr * (cellH + trayGap) + cellH / 2,
      );
      final placed = owner._session.isPlaced(piece);
      final view = _Piece(
        image: image,
        src: src,
        colors: owner.colors,
        home: piece,
        homeCenter: homeCenter,
        trayCenter: trayCenter,
        cellSize: Vector2(cellW, cellH),
        startCenter: placed ? homeCenter : trayCenter,
        placed: placed,
      );
      _pieces.add(view);
      add(view);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_boardSide <= 0) return;
    final rect = _boardRect;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(_boardSide * 0.04));

    // Подложка доски + бледная картинка-образец («крышка коробки»).
    canvas.drawRRect(
      rrect,
      Paint()..color = owner.colors.surface.withValues(alpha: 0.55),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.20),
    );
    canvas.restore();

    // Сетка-направляющая.
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _boardSide * 0.006
      ..color = owner.colors.onSurface.withValues(alpha: 0.16);
    for (var i = 1; i < owner.set.cols; i++) {
      final x = _boardLeft + i * _cellW;
      canvas.drawLine(Offset(x, _boardTop), Offset(x, _boardTop + _boardSide), grid);
    }
    for (var i = 1; i < owner.set.rows; i++) {
      final y = _boardTop + i * _cellH;
      canvas.drawLine(Offset(_boardLeft, y), Offset(_boardLeft + _boardSide, y), grid);
    }

    // Рамка доски.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _boardSide * 0.012
        ..color = owner.colors.primary.withValues(alpha: 0.55),
    );
  }

  // ── Перетаскивание ────────────────────────────────────────────────────────

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!owner._active) return;
    final p = event.localPosition;
    for (var i = _pieces.length - 1; i >= 0; i--) {
      final pc = _pieces[i];
      if (!pc.placed && pc.containsPoint(p)) {
        _grabbed = pc;
        _grabOffset = p - pc.position;
        pc.priority = 100;
        pc.lift();
        Sfx.play(SfxEvent.tap);
        Haptics.tap();
        break;
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final g = _grabbed;
    if (g == null) return;
    final target = event.localEndPosition - _grabOffset;
    g.position = Vector2(
      target.x.clamp(g.size.x / 2, size.x - g.size.x / 2).toDouble(),
      target.y.clamp(g.size.y / 2, size.y - g.size.y / 2).toDouble(),
    );
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _finishDrag();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _finishDrag();
  }

  void _finishDrag() {
    final g = _grabbed;
    if (g == null) return;
    _grabbed = null;
    g.priority = 0;
    g.drop();
    _resolveDrop(g);
  }

  void _resolveDrop(_Piece g) {
    final center = g.position;
    if (_boardRect.contains(Offset(center.x, center.y))) {
      final c = ((center.x - _boardLeft) / _cellW)
          .floor()
          .clamp(0, owner.set.cols - 1)
          .toInt();
      final r = ((center.y - _boardTop) / _cellH)
          .floor()
          .clamp(0, owner.set.rows - 1)
          .toInt();
      final cell = r * owner.set.cols + c;
      final res = owner._session.place(g.home, cell);
      if (res.correct) {
        g.snapTo(g.homeCenter);
        g.placed = true;
        owner.onPiecePlaced(g.homeCenter.clone(), isComplete: res.isComplete);
        return;
      }
      owner.onWrongDrop();
    }
    // Мимо доски или не на свою ячейку — мягко вернуть в лоток (без потери прогресса).
    g.returnToTray();
  }
}

/// Кусочек пазла: ломтик картинки (src-прямоугольник) в скруглённой плитке.
/// Перетаскивание/защёлк/возврат — управляет [_PuzzleSurface].
class _Piece extends PositionComponent {
  _Piece({
    required this.image,
    required this.src,
    required this.colors,
    required this.home,
    required this.homeCenter,
    required this.trayCenter,
    required Vector2 cellSize,
    required Vector2 startCenter,
    required this.placed,
  }) : super(size: cellSize, anchor: Anchor.center, position: startCenter);

  final ui.Image image;
  final Rect src;
  final AppColors colors;

  /// Индекс домашней ячейки (= id кусочка).
  final int home;
  final Vector2 homeCenter;
  final Vector2 trayCenter;

  /// Стоит ли на своём месте (нельзя двигать).
  bool placed;
  bool _lifted = false;

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final radius = Radius.circular(min(size.x, size.y) * 0.12);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    if (_lifted) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.shift(Offset(0, size.y * 0.05)), radius),
        Paint()
          ..color = colors.onBackground.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Кремовая подложка плитки: у эмодзи есть поля — без неё крайние кусочки
    // были бы полупрозрачными «пустыми».
    canvas.drawRRect(rrect, Paint()..color = colors.surface);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawImageRect(
      image,
      src,
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();

    // Светлая «фаска» + тонкий контур — кусочки читаются как отдельные плитки.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.x * 0.04
        ..color = colors.surface,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.x * 0.012
        ..color = colors.onSurface.withValues(alpha: 0.18),
    );
  }

  void lift() => _lifted = true;

  void drop() => _lifted = false;

  void snapTo(Vector2 center) {
    add(MoveToEffect(center, EffectController(duration: 0.12, curve: Curves.easeOut)));
    add(ScaleEffect.to(
      Vector2.all(1.12),
      EffectController(duration: 0.12, alternate: true),
    ));
  }

  void returnToTray() {
    add(MoveToEffect(
      trayCenter,
      EffectController(duration: 0.18, curve: Curves.easeOut),
    ));
  }
}
