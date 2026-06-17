import 'dart:math';

/// Режим раунда игры «Счёт».
enum CountMode {
  /// Малыш тапает каждый объект по очереди; голос считает «один, два, три…».
  /// Учит самому процессу счёта. Используется в ранних наборах.
  tapCount,

  /// Показываем N объектов; малыш выбирает правильную цифру из вариантов.
  /// Проверяет узнавание числа. Используется в поздних наборах.
  chooseNumeral,
}

/// Набор (ступень сложности) игры «Счёт».
///
/// Прогрессия «без проигрышей»: наборы открываются по мере игры, сложность
/// растёт плавно — от счёта тапом 1–3 до выбора цифры до 10.
class CountSet {
  const CountSet({
    required this.index,
    required this.mode,
    required this.minCount,
    required this.maxCount,
    this.optionCount = 0,
  }) : assert(minCount >= 1),
       assert(maxCount >= minCount),
       assert(
         mode == CountMode.tapCount || optionCount >= 2,
         'chooseNumeral требует минимум 2 варианта',
       );

  /// Порядковый номер набора (0-based).
  final int index;

  /// Режим раунда.
  final CountMode mode;

  /// Наименьшее число объектов в раунде.
  final int minCount;

  /// Наибольшее число объектов в раунде.
  final int maxCount;

  /// Для [CountMode.chooseNumeral] — сколько цифр-вариантов показать
  /// (включая правильную). Для [CountMode.tapCount] не используется (0).
  final int optionCount;

  /// Все наборы по порядку. Плавная кривая: учим считать тапом (1–3, затем
  /// 1–5), потом узнавать цифру (выбор из 2, из 3), и наконец до 10.
  static const List<CountSet> all = <CountSet>[
    CountSet(index: 0, mode: CountMode.tapCount, minCount: 1, maxCount: 3),
    CountSet(index: 1, mode: CountMode.tapCount, minCount: 1, maxCount: 5),
    CountSet(
      index: 2,
      mode: CountMode.chooseNumeral,
      minCount: 1,
      maxCount: 5,
      optionCount: 2,
    ),
    CountSet(
      index: 3,
      mode: CountMode.chooseNumeral,
      minCount: 2,
      maxCount: 5,
      optionCount: 3,
    ),
    CountSet(
      index: 4,
      mode: CountMode.chooseNumeral,
      minCount: 3,
      maxCount: 10,
      optionCount: 3,
    ),
  ];
}

/// Один раунд: сколько объектов на экране и (для выбора цифры) какие варианты.
class CountRound {
  const CountRound({
    required this.count,
    required this.mode,
    required this.options,
  });

  /// Истинное число объектов на экране.
  final int count;

  /// Режим этого раунда (наследуется от набора).
  final CountMode mode;

  /// Варианты-цифры для [CountMode.chooseNumeral] (перемешаны, содержат
  /// правильный [count]). Для [CountMode.tapCount] — пустой список.
  final List<int> options;
}

/// Исход одного тапа в режиме [CountMode.tapCount].
class TapResult {
  const TapResult({required this.counted, required this.isComplete});

  /// Сколько объектов посчитано после этого тапа (для голоса «…три!»).
  final int counted;

  /// Все объекты посчитаны — раунд решён.
  final bool isComplete;
}

/// Исход выбора цифры в режиме [CountMode.chooseNumeral].
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

  /// Совпал ли выбор. При `false` — мягкое «попробуй ещё», без штрафа.
  final bool isCorrect;
}

/// Чистая логика игры «Счёт» без рендера и Flutter-зависимостей —
/// поэтому полностью тестируется. Рендер, голос и «сок» живут в Flame-слое.
///
/// Сессия держит текущий раунд и (для tapCount) сколько уже посчитано.
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

  /// Сколько объектов уже посчитано в текущем раунде (режим tapCount).
  int get counted => _counted;

  /// Сгенерировать раунд по правилам [set] и переданному [random] — чистая
  /// функция (та же логика, что использует сессия), удобна для тестов.
  static CountRound generateRound(CountSet set, Random random) {
    final count = set.minCount + random.nextInt(set.maxCount - set.minCount + 1);
    if (set.mode == CountMode.tapCount) {
      return CountRound(count: count, mode: set.mode, options: const <int>[]);
    }
    return CountRound(
      count: count,
      mode: set.mode,
      options: _buildOptions(count, set.maxCount, set.optionCount, random),
    );
  }

  CountRound _generate() => generateRound(set, _rng);

  /// Тап по объекту (режим tapCount). Считает на один больше, не превышая
  /// числа объектов на экране (лишние тапы игнорируются).
  TapResult tap() {
    if (_counted < _round.count) _counted++;
    return TapResult(counted: _counted, isComplete: _counted == _round.count);
  }

  /// Выбор цифры (режим chooseNumeral). Состояние не меняется — хост сам решает,
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
