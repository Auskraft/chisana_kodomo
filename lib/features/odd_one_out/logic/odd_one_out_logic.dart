import 'dart:math';

/// Категория предметов: эмодзи одной группы. Эмодзи разных категорий **не
/// пересекаются** — иначе «лишний» был бы неоднозначным.
class OddCategory {
  const OddCategory(this.name, this.items);

  final String name;
  final List<String> items;
}

/// Группы предметов для «Что лишнее». Каждая — 8 эмодзи (хватает на большинство
/// до 8 предметов). Категории заметно различаются между собой, чтобы «лишний»
/// был однозначным даже для малыша.
abstract final class OddItems {
  static const List<OddCategory> categories = <OddCategory>[
    OddCategory('фрукты', <String>['🍎', '🍌', '🍓', '🍇', '🍊', '🍉', '🍐', '🍒']),
    OddCategory('звери', <String>['🐶', '🐱', '🐰', '🐮', '🐷', '🐸', '🐵', '🐯']),
    OddCategory('машинки', <String>['🚗', '🚌', '🚓', '🚒', '🚜', '🚕', '🚙', '🛵']),
    OddCategory('сладости', <String>['🍰', '🍪', '🍭', '🍬', '🍩', '🧁', '🍫', '🍦']),
    OddCategory('одежда', <String>['👕', '👗', '👚', '🧦', '🧣', '🧤', '👖', '👒']),
    OddCategory('игрушки', <String>['🧸', '🪁', '🎲', '🪀', '🎯', '🪅', '🎀', '🪄']),
    OddCategory('музыка', <String>['🥁', '🎺', '🎸', '🎻', '🎹', '🎷', '🎤', '🎼']),
    OddCategory('спорт', <String>['⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱']),
    OddCategory('космос', <String>['🚀', '🪐', '🌙', '🌟', '🌠', '🔭', '🛸', '🌌']),
  ];
}

/// Сколько уровней в «Лишнем»: число предметов на экране плавно растёт.
const int kOddLevels = 99;

/// Потолок предметов на экране: лишний (1) + большинство (optionCount−1) одной
/// категории; в категории 8 эмодзи, значит optionCount−1 ≤ 8 → не больше 9.
const int _kOddMaxOptions = 9;

/// Набор (ступень) — растёт число предметов на экране.
class OddSet {
  const OddSet({required this.index, required this.optionCount})
      : assert(optionCount >= 3);

  final int index;

  /// Сколько предметов всего (1 лишний + остальные одной категории).
  final int optionCount;

  /// [kOddLevels] уровней: число предметов плавно растёт от 3 до
  /// [_kOddMaxOptions] (потолок — размер категории).
  static final List<OddSet> all = <OddSet>[
    for (var i = 0; i < kOddLevels; i++)
      OddSet(
        index: i,
        optionCount: 3 + (i * (_kOddMaxOptions - 3) / (kOddLevels - 1)).round(),
      ),
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
