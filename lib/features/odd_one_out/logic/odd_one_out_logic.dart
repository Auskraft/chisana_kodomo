import 'dart:math';

/// Категория предметов: эмодзи одной группы. Эмодзи разных категорий **не
/// пересекаются** — иначе «лишний» был бы неоднозначным.
class OddCategory {
  const OddCategory(this.name, this.items);

  final String name;
  final List<String> items;
}

/// Группы предметов для «Что лишнее». Каждая — минимум 8 эмодзи (хватает на
/// большинство до 4 предметов).
abstract final class OddItems {
  static const List<OddCategory> categories = <OddCategory>[
    OddCategory('фрукты', <String>['🍎', '🍌', '🍓', '🍇', '🍊', '🍉', '🍐', '🍒']),
    OddCategory('звери', <String>['🐶', '🐱', '🐰', '🐮', '🐷', '🐸', '🐵', '🐯']),
    OddCategory('машинки', <String>['🚗', '🚌', '🚓', '🚒', '🚜', '🚕', '🚙', '🛵']),
    OddCategory('сладости', <String>['🍰', '🍪', '🍭', '🍬', '🍩', '🧁', '🍫', '🍦']),
    OddCategory('одежда', <String>['👕', '👗', '👚', '🧦', '🧣', '🧤', '👖', '👒']),
  ];
}

/// Набор (ступень) — растёт число предметов на экране.
class OddSet {
  const OddSet({required this.index, required this.optionCount})
      : assert(optionCount >= 3);

  final int index;

  /// Сколько предметов всего (1 лишний + остальные одной категории).
  final int optionCount;

  static const List<OddSet> all = <OddSet>[
    OddSet(index: 0, optionCount: 3),
    OddSet(index: 1, optionCount: 4),
    OddSet(index: 2, optionCount: 4),
    OddSet(index: 3, optionCount: 5),
  ];
}

/// Раунд: предметы (перемешаны) + индекс лишнего.
class OddRound {
  const OddRound({required this.items, required this.oddIndex});

  final List<String> items;
  final int oddIndex;

  String get odd => items[oddIndex];
}

/// Исход выбора.
class OddChoice {
  const OddChoice({required this.chosen, required this.isCorrect});
  final int chosen;
  final bool isCorrect;
}

/// Чистая логика «Что лишнее» (только `dart:math`). Без таймеров/проигрыша.
class OddSession {
  OddSession(this.set, {Random? random}) : _rng = random ?? Random() {
    _round = _generate();
  }

  final OddSet set;
  final Random _rng;
  late OddRound _round;

  OddRound get round => _round;

  /// Чистая генерация: (optionCount−1) предметов одной категории + 1 «лишний»
  /// из другой. Гарантирует ровно один лишний.
  static OddRound generateRound(OddSet set, Random r) {
    final cats = OddItems.categories;
    final majIdx = r.nextInt(cats.length);
    int oddIdx;
    do {
      oddIdx = r.nextInt(cats.length);
    } while (oddIdx == majIdx);

    final maj = <String>[...cats[majIdx].items]..shuffle(r);
    final odd = cats[oddIdx].items[r.nextInt(cats[oddIdx].items.length)];
    final items = <String>[...maj.take(set.optionCount - 1), odd]..shuffle(r);
    return OddRound(items: items, oddIndex: items.indexOf(odd));
  }

  OddRound _generate() => generateRound(set, _rng);

  OddChoice choose(int index) =>
      OddChoice(chosen: index, isCorrect: index == _round.oddIndex);

  void nextRound() => _round = _generate();
}
