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

/// Сколько уровней в «Счёте»: длинная плавная кривая — от счёта тапом до
/// выбора цифры до 10.
const int kCountLevels = 30;

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

  /// Первые [_tapLevels] уровней — счёт тапом (учим сам процесс счёта),
  /// остальные — выбор цифры с плавно растущим диапазоном и числом вариантов.
  static const int _tapLevels = 6;

  /// [kCountLevels] уровней одной плавной кривой: счёт тапом (число объектов
  /// 3→6), затем выбор цифры (диапазон 1..5 → 5..10, вариантов 2 → 5). Вариантов
  /// не больше, чем чисел в диапазоне; диапазон всегда шире одного числа.
  static List<CountSet> _build() {
    final sets = <CountSet>[];
    for (var i = 0; i < kCountLevels; i++) {
      if (i < _tapLevels) {
        final maxC = 3 + (i * 3 / (_tapLevels - 1)).round(); // 3 → 6
        sets.add(CountSet(
          index: i,
          mode: CountMode.tapCount,
          minCount: 1,
          maxCount: maxC,
        ));
      } else {
        final t = (i - _tapLevels) / (kCountLevels - 1 - _tapLevels); // 0..1
        final maxC = (5 + 5 * t).round(); // 5 → 10
        final minC = (1 + 4 * t).round(); // 1 → 5
        final opts = (2 + 3 * t).round(); // 2 → 5
        sets.add(CountSet(
          index: i,
          mode: CountMode.chooseNumeral,
          minCount: min(minC, maxC - 1),
          maxCount: maxC,
          optionCount: min(opts, maxC),
        ));
      }
    }
    return sets;
  }

  /// Все наборы по порядку ([kCountLevels] штук).
  static final List<CountSet> all = _build();
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
