import 'dart:math';

/// Сколько уровней в «Пазлах»: по 1 картинке на уровень, сложность растёт.
const int kPuzzleLevels = 99;

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

  /// Сетки по возрастанию сложности (rows≥cols, портретно-удобно):
  /// 2·4·6·9·12·16·20·25·30 кусочков.
  static const List<List<int>> _grids = <List<int>>[
    <int>[2, 1], <int>[2, 2], <int>[3, 2], <int>[3, 3], <int>[4, 3],
    <int>[4, 4], <int>[5, 4], <int>[5, 5], <int>[6, 5],
  ];

  static int _gridFor(int level) =>
      (level * (_grids.length - 1) / (kPuzzleLevels - 1)).round();

  /// [kPuzzleLevels] уровней: сложность плавно растёт от 2 до 30 кусочков.
  /// Картинка на уровне — случайная из пула `assets/puzzles/` (берётся в Flame-слое).
  static final List<PuzzleSet> all = <PuzzleSet>[
    for (var i = 0; i < kPuzzleLevels; i++)
      PuzzleSet(
        index: i,
        rows: _grids[_gridFor(i)][0],
        cols: _grids[_gridFor(i)][1],
      ),
  ];
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
