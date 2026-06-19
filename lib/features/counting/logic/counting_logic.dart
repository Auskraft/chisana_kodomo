import 'dart:math';

/// Сколько уровней в «Счёте»: длинная плавная кривая. Гибрид — ядро всегда счёт
/// тапом (работает без взрослого), на поздних уровнях после счёта добавляется
/// озвученный выбор цифры. Растёт вместе с ребёнком.
const int kCountLevels = 30;

/// Набор (ступень сложности) игры «Счёт».
///
/// Каждый раунд начинается со **счёта тапом** (тап по объекту → голос считает).
/// На ранних уровнях после пересчёта цифра просто показывается и озвучивается
/// (знакомство, без экзамена). На поздних — [chooseDigit] включает фазу «найди
/// цифру N» с озвучкой кнопок и подсказкой. «Без проигрышей».
class CountSet {
  const CountSet({
    required this.index,
    required this.minCount,
    required this.maxCount,
    this.chooseDigit = false,
    this.optionCount = 0,
  })  : assert(minCount >= 1),
        assert(maxCount >= minCount),
        assert(
          !chooseDigit || optionCount >= 2,
          'фаза выбора цифры требует минимум 2 варианта',
        );

  /// Порядковый номер набора (0-based).
  final int index;

  /// Наименьшее число объектов в раунде.
  final int minCount;

  /// Наибольшее число объектов в раунде.
  final int maxCount;

  /// После счёта — фаза «найди цифру N» (с озвучкой). На ранних уровнях `false`:
  /// цифра только показывается и проговаривается.
  final bool chooseDigit;

  /// Сколько цифр-вариантов в фазе выбора (включая правильную). 0, если
  /// [chooseDigit] == false.
  final int optionCount;

  /// Первые [_countOnlyLevels] уровней — только счёт тапом (цифра показывается и
  /// озвучивается). Дальше добавляется выбор цифры.
  static const int _countOnlyLevels = 10;

  /// [kCountLevels] уровней одной плавной кривой: сперва счёт тапом (объектов
  /// 3→8), затем счёт + выбор цифры (диапазон 1..6 → 5..10, вариантов 2 → 5).
  /// Вариантов не больше, чем чисел в диапазоне; диапазон всегда шире одного.
  static List<CountSet> _build() {
    final sets = <CountSet>[];
    for (var i = 0; i < kCountLevels; i++) {
      if (i < _countOnlyLevels) {
        final maxC = 3 + (i * 5 / (_countOnlyLevels - 1)).round(); // 3 → 8
        sets.add(CountSet(index: i, minCount: 1, maxCount: maxC));
      } else {
        final t = (i - _countOnlyLevels) /
            (kCountLevels - 1 - _countOnlyLevels); // 0..1
        final maxC = (6 + 4 * t).round(); // 6 → 10
        final minC = (1 + 4 * t).round(); // 1 → 5
        final opts = (2 + 3 * t).round(); // 2 → 5
        sets.add(CountSet(
          index: i,
          minCount: min(minC, maxC - 1),
          maxCount: maxC,
          chooseDigit: true,
          optionCount: min(opts, maxC),
        ));
      }
    }
    return sets;
  }

  /// Все наборы по порядку ([kCountLevels] штук).
  static final List<CountSet> all = _build();
}

/// Один раунд: сколько объектов на экране и (для фазы выбора) какие цифры-варианты.
class CountRound {
  const CountRound({
    required this.count,
    required this.chooseDigit,
    required this.options,
  });

  /// Истинное число объектов на экране.
  final int count;

  /// Есть ли после счёта фаза выбора цифры (наследуется от набора).
  final bool chooseDigit;

  /// Цифры-варианты для фазы выбора (перемешаны, содержат правильный [count]).
  /// Пустой список, если [chooseDigit] == false.
  final List<int> options;
}

/// Исход одного тапа по объекту (фаза счёта).
class TapResult {
  const TapResult({required this.counted, required this.isComplete});

  /// Сколько объектов посчитано после этого тапа (для голоса «…три!»).
  final int counted;

  /// Все объекты посчитаны — фаза счёта завершена.
  final bool isComplete;
}

/// Исход выбора цифры (фаза выбора).
class ChoiceResult {
  const ChoiceResult({
    required this.chosen,
    required this.answer,
    required this.isCorrect,
  });

  /// Цифра, которую выбрал малыш.
  final int chosen;

  /// Правильный ответ.
  final int answer;

  /// Совпал ли выбор. При `false` — мягко, без штрафа.
  final bool isCorrect;
}

/// Чистая логика игры «Счёт» без рендера и Flutter-зависимостей —
/// поэтому полностью тестируется. Рендер, голос и «сок» живут в Flame-слое.
///
/// Сессия держит текущий раунд и сколько уже посчитано.
/// «Без проигрышей»: лишние тапы не считаются, неверный выбор ничего не ломает.
class CountingSession {
  CountingSession(this.set, {Random? random}) : _rng = random ?? Random() {
    _round = _generate();
  }

  /// Набор, по правилам которого генерируются раунды.
  final CountSet set;
  final Random _rng;

  late CountRound _round;
  int _counted = 0;

  /// Текущий раунд.
  CountRound get round => _round;

  /// Сколько объектов уже посчитано в текущем раунде.
  int get counted => _counted;

  /// Сгенерировать раунд по правилам [set] и переданному [random] — чистая
  /// функция (та же логика, что использует сессия), удобна для тестов.
  static CountRound generateRound(CountSet set, Random random) {
    final count = set.minCount + random.nextInt(set.maxCount - set.minCount + 1);
    if (!set.chooseDigit) {
      return CountRound(count: count, chooseDigit: false, options: const <int>[]);
    }
    return CountRound(
      count: count,
      chooseDigit: true,
      options: _buildOptions(count, set.maxCount, set.optionCount, random),
    );
  }

  CountRound _generate() => generateRound(set, _rng);

  /// Тап по объекту (фаза счёта). Считает на один больше, не превышая числа
  /// объектов на экране (лишние тапы игнорируются).
  TapResult tap() {
    if (_counted < _round.count) _counted++;
    return TapResult(counted: _counted, isComplete: _counted == _round.count);
  }

  /// Выбор цифры (фаза выбора). Состояние не меняется — хост сам решает,
  /// переходить ли к следующему раунду при правильном ответе.
  ChoiceResult choose(int numeral) {
    return ChoiceResult(
      chosen: numeral,
      answer: _round.count,
      isCorrect: numeral == _round.count,
    );
  }

  /// Перейти к следующему раунду этого набора (сбрасывает счётчик тапов).
  void nextRound() {
    _round = _generate();
    _counted = 0;
  }

  /// Собрать варианты-цифры: правильный [answer] + случайные различные
  /// «отвлекалки» из 1..[maxOption], всего [optionCount], перемешанные.
  static List<int> _buildOptions(
    int answer,
    int maxOption,
    int optionCount,
    Random rng,
  ) {
    final chosen = <int>{answer};
    final candidates = <int>[for (var i = 1; i <= maxOption; i++) i]
      ..remove(answer)
      ..shuffle(rng);
    for (final c in candidates) {
      if (chosen.length >= optionCount) break;
      chosen.add(c);
    }
    return chosen.toList()..shuffle(rng);
  }
}
