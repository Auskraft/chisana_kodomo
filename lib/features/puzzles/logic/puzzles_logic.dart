import 'dart:math';

/// Набор (ступень сложности) игры «Пазлы».
///
/// Картинка режется на сетку [rows]×[cols]; малыш собирает её из кусочков.
/// Прогрессия «без проигрышей»: число кусочков растёт плавно — от 2 (картинка
/// пополам) до 16. Сетка хранится как (ряды, столбцы); кусочков = их произведение.
class PuzzleSet {
  const PuzzleSet({
    required this.index,
    required this.rows,
    required this.cols,
  })  : assert(rows >= 1),
        assert(cols >= 1);

  /// Порядковый номер набора (0-based).
  final int index;

  /// Рядов в сетке (= по сколько кусочков по вертикали).
  final int rows;

  /// Столбцов в сетке (= по сколько кусочков по горизонтали).
  final int cols;

  /// Всего кусочков (= ячеек на доске).
  int get pieces => rows * cols;

  /// Плавная длинная кривая: 2 → 4 → 6 → 9 → 12 → 16 кусочков. Сетки близки к
  /// квадрату (портретно-удобно: рядов ≥ столбцов), картинка не искажается.
  static const List<PuzzleSet> all = <PuzzleSet>[
    PuzzleSet(index: 0, rows: 2, cols: 1), // 2 — картинка пополам (верх/низ)
    PuzzleSet(index: 1, rows: 2, cols: 2), // 4
    PuzzleSet(index: 2, rows: 3, cols: 2), // 6
    PuzzleSet(index: 3, rows: 3, cols: 3), // 9
    PuzzleSet(index: 4, rows: 4, cols: 3), // 12
    PuzzleSet(index: 5, rows: 4, cols: 4), // 16
  ];

  /// Звёзды за набор по числу ошибок (промахов мимо своей ячейки). Порог
  /// масштабируется числом кусочков — у больших пазлов промахи естественны.
  /// «Без проигрышей»: всегда минимум 1 звезда.
  static int starsForMistakes(int mistakes, int pieces) {
    if (mistakes <= 0) return 3;
    if (mistakes <= pieces) return 2;
    return 1;
  }
}

/// Исход попытки положить кусочек на ячейку.
class PlaceResult {
  const PlaceResult({required this.correct, required this.isComplete});

  /// Кусочек встал на свою ячейку (новое верное размещение).
  final bool correct;

  /// Все кусочки собраны — картинка готова.
  final bool isComplete;
}

/// Чистая логика «Пазлов» без рендера и Flutter-зависимостей — полностью
/// тестируется. Геометрия доски/лотка и перетаскивание живут в Flame-слое.
///
/// Кусочки нумеруются индексом своей «домашней» ячейки (0..pieces−1): кусочек
/// `p` верен на ячейке `p`. [trayOrder] — перемешанный порядок кусочков в лотке
/// (детерминирован переданным [Random]). «Без проигрышей»: промах лишь считается
/// и возвращает кусочек, ничего не ломая.
class PuzzleSession {
  PuzzleSession(this.set, {Random? random}) : _rng = random ?? Random() {
    trayOrder = _shuffledPieces();
  }

  final PuzzleSet set;
  final Random _rng;

  /// Порядок кусочков в лотке (перемешанные индексы 0..pieces−1).
  late List<int> trayOrder;

  final Set<int> _placed = <int>{};
  int _mistakes = 0;

  /// Сколько промахов (для начисления звёзд). Копится в пределах набора —
  /// [nextPicture] его НЕ сбрасывает.
  int get mistakes => _mistakes;

  /// Сколько кусочков уже на своих местах.
  int get placedCount => _placed.length;

  /// Стоит ли кусочек [piece] на месте.
  bool isPlaced(int piece) => _placed.contains(piece);

  /// Все кусочки собраны.
  bool get isComplete => _placed.length == set.pieces;

  List<int> _shuffledPieces() =>
      <int>[for (var i = 0; i < set.pieces; i++) i]..shuffle(_rng);

  /// Положить кусочок [piece] на ячейку [cell]. Верно, если [cell] — его дом
  /// (`cell == piece`). Уже стоящий кусочек повторно не учитывается.
  PlaceResult place(int piece, int cell) {
    if (_placed.contains(piece)) {
      return PlaceResult(correct: false, isComplete: isComplete);
    }
    if (cell == piece) {
      _placed.add(piece);
      return PlaceResult(correct: true, isComplete: isComplete);
    }
    _mistakes++;
    return const PlaceResult(correct: false, isComplete: false);
  }

  /// Перейти к следующей картинке того же набора: очистить доску и заново
  /// перемешать лоток. Промахи набора сохраняются (для итоговых звёзд).
  void nextPicture() {
    _placed.clear();
    trayOrder = _shuffledPieces();
  }
}
