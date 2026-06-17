/// Режим раскраски (переключается прямо в игре).
enum ColoringMode {
  /// Заливка: тап по области → выбранный цвет (любой, свободно).
  fill,

  /// По номерам: у области есть «правильный» цвет; иной мягко не применяется.
  byNumber,

  /// Свободный холст: рисование пальцем (без областей/цели).
  freeDraw,
}

/// Область картинки. Геометрия (Path) живёт в render-слое по [id]; здесь —
/// только модель: идентификатор и (для «по номерам») целевой цвет палитры.
class ColorRegion {
  const ColorRegion({required this.id, this.targetColor = 0});

  final int id;

  /// Индекс целевого цвета палитры для режима «по номерам».
  final int targetColor;
}

/// Картинка как набор областей (без геометрии — она в render-слое).
class ColoringPicture {
  const ColoringPicture({required this.name, required this.regions});

  final String name;
  final List<ColorRegion> regions;

  int get regionCount => regions.length;
}

/// Исход заливки одной области.
class FillResult {
  const FillResult({
    required this.applied,
    required this.correct,
    required this.complete,
  });

  /// Цвет применён к области.
  final bool applied;

  /// (Режим «по номерам») цвет соответствовал цели. В прочих режимах — true.
  final bool correct;

  /// Картинка завершена этой заливкой.
  final bool complete;
}

/// Состояние раскрашивания одной картинки — чистая логика, без Flutter.
///
/// «Без проигрышей»: в режиме «по номерам» неверный цвет просто не применяется
/// (мягко), область можно перекрашивать сколько угодно.
class ColoringState {
  ColoringState(this.picture, {this.mode = ColoringMode.fill});

  final ColoringPicture picture;
  final ColoringMode mode;

  final Map<int, int> _fill = <int, int>{}; // regionId → индекс цвета палитры
  final List<MapEntry<int, int?>> _history = <MapEntry<int, int?>>[]; // отмена
  final List<MapEntry<int, int?>> _redo = <MapEntry<int, int?>>[]; // возврат

  /// Текущий цвет области (или null, если не закрашена).
  int? colorOf(int regionId) => _fill[regionId];

  ColorRegion _region(int regionId) =>
      picture.regions.firstWhere((ColorRegion r) => r.id == regionId);

  /// Залить область [regionId] цветом [colorIndex].
  FillResult fill(int regionId, int colorIndex) {
    final region = _region(regionId);
    if (mode == ColoringMode.byNumber && region.targetColor != colorIndex) {
      return const FillResult(applied: false, correct: false, complete: false);
    }
    _history.add(MapEntry<int, int?>(regionId, _fill[regionId]));
    _redo.clear();
    _fill[regionId] = colorIndex;
    return FillResult(applied: true, correct: true, complete: isComplete);
  }

  /// Сколько областей считаются закрашенными (в «по номерам» — верным цветом).
  int get filledCount {
    if (mode == ColoringMode.byNumber) {
      return picture.regions
          .where((ColorRegion r) => _fill[r.id] == r.targetColor)
          .length;
    }
    return picture.regions.where((ColorRegion r) => _fill.containsKey(r.id)).length;
  }

  /// Доля готовности 0..1.
  double get progress =>
      picture.regionCount == 0 ? 1 : filledCount / picture.regionCount;

  /// Картинка завершена.
  bool get isComplete {
    if (mode == ColoringMode.byNumber) {
      return picture.regions
          .every((ColorRegion r) => _fill[r.id] == r.targetColor);
    }
    return picture.regions.every((ColorRegion r) => _fill.containsKey(r.id));
  }

  /// Сбросить все заливки (кнопка «заново»).
  void clear() {
    _fill.clear();
    _history.clear();
    _redo.clear();
  }

  bool get canUndo => _history.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Поставить области цвет [colorIndex] (или снять, если null), вернуть прежний.
  int? _restore(int regionId, int? colorIndex) {
    final cur = _fill[regionId];
    if (colorIndex == null) {
      _fill.remove(regionId);
    } else {
      _fill[regionId] = colorIndex;
    }
    return cur;
  }

  /// Отменить последнюю заливку.
  void undo() {
    if (_history.isEmpty) return;
    final e = _history.removeLast();
    _redo.add(MapEntry<int, int?>(e.key, _restore(e.key, e.value)));
  }

  /// Вернуть отменённую заливку.
  void redo() {
    if (_redo.isEmpty) return;
    final e = _redo.removeLast();
    _history.add(MapEntry<int, int?>(e.key, _restore(e.key, e.value)));
  }
}
