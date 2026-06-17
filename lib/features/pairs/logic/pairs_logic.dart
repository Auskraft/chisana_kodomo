import 'dart:math';

/// Набор (ступень сложности) игры «Парочки» (память).
///
/// Прогрессия «без проигрышей»: число пар растёт плавно, сетка остаётся
/// портретно-удобной (узкая по ширине). Промахи не штрафуются — память
/// тренируется сама.
class PairsSet {
  const PairsSet({
    required this.index,
    required this.pairs,
    required this.columns,
  })  : assert(pairs >= 2),
        assert(columns >= 2);

  /// Порядковый номер набора (0-based).
  final int index;

  /// Сколько пар в наборе (всего карточек = [pairs] * 2).
  final int pairs;

  /// Колонок в сетке — для адаптивной раскладки в Flame.
  final int columns;

  /// Всего карточек на поле.
  int get cardCount => pairs * 2;

  /// Плавная кривая: 2 → 3 → 4 → 6 пар.
  static const List<PairsSet> all = <PairsSet>[
    PairsSet(index: 0, pairs: 2, columns: 2), // 2×2
    PairsSet(index: 1, pairs: 3, columns: 2), // 2×3
    PairsSet(index: 2, pairs: 4, columns: 2), // 2×4
    PairsSet(index: 3, pairs: 6, columns: 3), // 3×4
  ];

  /// Звёзды за набор по числу несовпадений. Память: промахи — норма, поэтому
  /// порог масштабируется числом пар; всегда минимум 1 (без проигрышей).
  static int starsForMismatches(int mismatches, int pairs) {
    if (mismatches <= 0) return 3;
    if (mismatches <= pairs) return 2;
    return 1;
  }
}

/// Одна карточка на поле: какой символ под ней и её состояние.
///
/// [symbol] — индекс символа (одинаковый у пары); [id] — позиция в колоде.
class PairsCard {
  PairsCard({required this.id, required this.symbol});

  final int id;
  final int symbol;
  bool faceUp = false;
  bool matched = false;
}

/// Что произошло при перевороте карточки.
enum FlipOutcome {
  /// Тап проигнорирован (карта уже открыта/совпала или идёт блокировка).
  ignored,

  /// Открыли первую карту пары — ждём вторую.
  firstUp,

  /// Вторая карта совпала с первой — пара найдена.
  matched,

  /// Вторая карта не совпала — обе закроются после показа.
  mismatch,
}

/// Исход одного переворота.
class FlipResult {
  const FlipResult({
    required this.outcome,
    required this.index,
    this.otherIndex,
    this.allMatched = false,
  });

  final FlipOutcome outcome;

  /// Индекс карты, по которой тапнули.
  final int index;

  /// Вторая карта пары (для [FlipOutcome.matched]/[FlipOutcome.mismatch]).
  final int? otherIndex;

  /// Все пары найдены — набор пройден.
  final bool allMatched;
}

/// Чистая логика «Парочек» без рендера и Flutter-зависимостей — полностью
/// тестируется. Колода детерминирована переданным [Random].
///
/// «Без проигрышей»: лишние тапы безопасны, несовпадение лишь закрывает карты.
class PairsSession {
  PairsSession(this.set, {Random? random}) : _rng = random ?? Random() {
    _cards = _deal();
  }

  final PairsSet set;
  final Random _rng;

  late List<PairsCard> _cards;
  int? _firstUp; // индекс открытой первой карты пары
  bool _locked = false; // блокировка после несовпадения до закрытия карт
  int _mismatches = 0;

  /// Карты в порядке колоды (только для чтения).
  List<PairsCard> get cards => List<PairsCard>.unmodifiable(_cards);

  /// Сколько было несовпадений (для начисления звёзд).
  int get mismatches => _mismatches;

  /// Все пары найдены.
  bool get isComplete => _cards.every((PairsCard c) => c.matched);

  List<PairsCard> _deal() {
    final symbols = <int>[for (var i = 0; i < set.pairs; i++) i];
    final deck = <int>[...symbols, ...symbols]..shuffle(_rng);
    return <PairsCard>[
      for (var i = 0; i < deck.length; i++) PairsCard(id: i, symbol: deck[i]),
    ];
  }

  /// Перевернуть карту [index]. Состояние карт меняется здесь; закрытие после
  /// несовпадения хост делает с задержкой через [resolveMismatch].
  FlipResult flip(int index) {
    if (_locked) {
      return FlipResult(outcome: FlipOutcome.ignored, index: index);
    }
    final card = _cards[index];
    if (card.matched || card.faceUp) {
      return FlipResult(outcome: FlipOutcome.ignored, index: index);
    }

    card.faceUp = true;
    final first = _firstUp;
    if (first == null) {
      _firstUp = index;
      return FlipResult(outcome: FlipOutcome.firstUp, index: index);
    }

    _firstUp = null;
    final other = _cards[first];
    if (other.symbol == card.symbol) {
      other.matched = true;
      card.matched = true;
      return FlipResult(
        outcome: FlipOutcome.matched,
        index: index,
        otherIndex: first,
        allMatched: isComplete,
      );
    }

    _mismatches++;
    _locked = true;
    return FlipResult(
      outcome: FlipOutcome.mismatch,
      index: index,
      otherIndex: first,
    );
  }

  /// Закрыть обе карты после показа несовпадения и снять блокировку.
  void resolveMismatch(int a, int b) {
    _cards[a].faceUp = false;
    _cards[b].faceUp = false;
    _locked = false;
  }
}
