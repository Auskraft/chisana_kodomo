import 'dart:math';

/// Зверёк: эмодзи, ласковое имя (для голоса) и ключ звука.
///
/// Звук — содержимое Фазы 5 (CC0-файлы `assets/animals/<soundKey>.wav`); до
/// тех пор обратная связь даётся голосом (произносим имя) — игра уже работает.
class Animal {
  const Animal(this.emoji, this.name, this.soundKey);

  /// Эмодзи зверя (запасная иконка, если нет арт-картинки).
  final String emoji;

  /// Имя в именительном падеже, ласковое: «собачка». Для «Где собачка?» и как
  /// озвучка-заглушка в «Ферме», пока нет реального звука.
  final String name;

  /// Ключ звука зверя: `assets/animals/<soundKey>.wav` (CC0; и иконки `<key>.png`).
  final String soundKey;
}

/// Зверушки игры. Порядок стабилен — индексы используются в наборах/раундах.
abstract final class Animals {
  static const List<Animal> all = <Animal>[
    Animal('🐶', 'собачка', 'dog'),
    Animal('🐱', 'кошечка', 'cat'),
    Animal('🐮', 'коровка', 'cow'),
    Animal('🐷', 'свинка', 'pig'),
    Animal('🐔', 'курочка', 'hen'),
    Animal('🐸', 'лягушка', 'frog'),
    Animal('🐑', 'овечка', 'sheep'),
    Animal('🐴', 'лошадка', 'horse'),
    Animal('🐤', 'цыплёнок', 'chick'),
    Animal('🐰', 'зайка', 'rabbit'),
  ];
}

/// Набор (ступень) игры «Звуки животных».
class AnimalSet {
  const AnimalSet({
    required this.index,
    required this.optionCount,
    required this.poolSize,
  })  : assert(optionCount >= 2),
        assert(poolSize >= optionCount);

  final int index;

  /// Сколько вариантов показать.
  final int optionCount;

  /// Сколько зверей из [Animals.all] задействовано (растёт по наборам).
  final int poolSize;

  /// Плавная длинная кривая: больше вариантов и больше зверей в пуле (пул не
  /// превышает число зверей в [Animals.all] = 10).
  static const List<AnimalSet> all = <AnimalSet>[
    AnimalSet(index: 0, optionCount: 2, poolSize: 4),
    AnimalSet(index: 1, optionCount: 3, poolSize: 5),
    AnimalSet(index: 2, optionCount: 3, poolSize: 6),
    AnimalSet(index: 3, optionCount: 4, poolSize: 7),
    AnimalSet(index: 4, optionCount: 4, poolSize: 8),
    AnimalSet(index: 5, optionCount: 4, poolSize: 9),
    AnimalSet(index: 6, optionCount: 4, poolSize: 10),
  ];
}

/// Раунд: какого зверя искать + варианты (перемешаны) + индекс верного.
class AnimalRound {
  const AnimalRound({
    required this.targetIndex,
    required this.options,
    required this.answerIndex,
  });

  /// Индекс искомого зверя в [Animals.all].
  final int targetIndex;

  /// Индексы зверей-вариантов в [Animals.all] (перемешаны, содержат цель).
  final List<int> options;

  /// Позиция цели в [options].
  final int answerIndex;

  /// Искомый зверь.
  Animal get target => Animals.all[targetIndex];
}

/// Исход выбора варианта.
class AnimalChoice {
  const AnimalChoice({required this.chosen, required this.isCorrect});
  final int chosen;
  final bool isCorrect;
}

/// Чистая логика «Звуки животных» (только `dart:math`). Без таймеров/проигрыша.
class AnimalSession {
  AnimalSession(this.set, {Random? random}) : _rng = random ?? Random() {
    _round = _generate();
  }

  final AnimalSet set;
  final Random _rng;
  late AnimalRound _round;

  AnimalRound get round => _round;

  /// Чистая генерация раунда: уникальные звери из пула, ровно один — цель.
  static AnimalRound generateRound(AnimalSet set, Random r) {
    final pool = <int>[for (var i = 0; i < set.poolSize; i++) i]..shuffle(r);
    final options = pool.take(set.optionCount).toList();
    final target = options[r.nextInt(options.length)];
    options.shuffle(r);
    return AnimalRound(
      targetIndex: target,
      options: options,
      answerIndex: options.indexOf(target),
    );
  }

  int? _lastTarget;

  /// Раунд без повтора цели подряд — соседние раунды не дублируются.
  AnimalRound _generate() {
    AnimalRound r;
    var guard = 0;
    do {
      r = generateRound(set, _rng);
    } while (r.targetIndex == _lastTarget && guard++ < 20);
    _lastTarget = r.targetIndex;
    return r;
  }

  /// Выбор варианта. Состояние не меняется — переход решает хост.
  AnimalChoice choose(int optionIndex) => AnimalChoice(
        chosen: optionIndex,
        isCorrect: optionIndex == _round.answerIndex,
      );

  void nextRound() => _round = _generate();
}

/// Имя зверя с заглавной буквы (для попапа/голоса-эха): «Собачка».
String animalNameCap(Animal a) =>
    a.name.isEmpty ? a.name : a.name[0].toUpperCase() + a.name.substring(1);
