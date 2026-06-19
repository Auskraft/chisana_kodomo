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
    // Расширение: арт-иконки `assets/animals/<key>.png` (звук — CC0 по мере
    // готовности; пока называются голосом). Порядок: от знакомых к экзотике —
    // ранние уровни (малый пул) берут зверей с начала.
    Animal('🦁', 'львёнок', 'lion'),
    Animal('🐯', 'тигрёнок', 'tiger'),
    Animal('🐘', 'слонёнок', 'elephant'),
    Animal('🐵', 'обезьянка', 'monkey'),
    Animal('🐻', 'мишка', 'bear'),
    Animal('🐺', 'волчок', 'wolf'),
    Animal('🦊', 'лисёнок', 'fox'),
    Animal('🦉', 'совёнок', 'owl'),
    Animal('🦆', 'уточка', 'duck'),
    Animal('🐓', 'петушок', 'rooster'),
    Animal('🐐', 'козлик', 'goat'),
    Animal('🫏', 'ослик', 'donkey'),
    Animal('🐭', 'мышка', 'mouse'),
    Animal('🐍', 'змейка', 'snake'),
    Animal('🐝', 'пчёлка', 'bee'),
    Animal('🦒', 'жирафик', 'giraffe'),
    Animal('🦓', 'зебра', 'zebra'),
    Animal('🦛', 'бегемотик', 'hippo'),
    Animal('🦏', 'носорог', 'rhino'),
    Animal('🐼', 'панда', 'panda'),
    Animal('🐨', 'коала', 'koala'),
    Animal('🦘', 'кенгурёнок', 'kangaroo'),
    Animal('🐊', 'крокодильчик', 'crocodile'),
    Animal('🐫', 'верблюжонок', 'camel'),
    Animal('🦌', 'оленёнок', 'deer'),
    Animal('🦝', 'енотик', 'raccoon'),
    Animal('🦔', 'ёжик', 'hedgehog'),
    Animal('🐿️', 'белочка', 'squirrel'),
    Animal('🦥', 'ленивец', 'sloth'),
    Animal('🐬', 'дельфинчик', 'dolphin'),
    Animal('🐋', 'китёнок', 'whale'),
    Animal('🦭', 'тюлень', 'seal'),
    Animal('🦭', 'морж', 'walrus'),
    Animal('🐧', 'пингвинёнок', 'penguin'),
    Animal('🐻‍❄️', 'белый мишка', 'polar_bear'),
    Animal('🐢', 'черепашка', 'turtle'),
    Animal('🦀', 'крабик', 'crab'),
    Animal('🦜', 'попугайчик', 'parrot'),
    Animal('🦚', 'павлин', 'peacock'),
    Animal('🦩', 'фламинго', 'flamingo'),
    Animal('🦢', 'лебедь', 'swan'),
    Animal('🦋', 'бабочка', 'butterfly'),
    Animal('🐞', 'божья коровка', 'ladybug'),
    Animal('🐌', 'улитка', 'snail'),
  ];
}

/// Сколько уровней в «Звуках»/«Ферме». Кривая растягивается автоматически под
/// число зверей в [Animals.all] (добавил арт — стало больше уровней).
const int kAnimalLevels = 24;

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

  /// [kAnimalLevels] уровней одной плавной кривой: число вариантов 2→5, пул
  /// 4→(все звери). Пул всегда ≥ числа вариантов и ≤ [Animals.all].length.
  static List<AnimalSet> _build() {
    final n = Animals.all.length;
    final sets = <AnimalSet>[];
    for (var i = 0; i < kAnimalLevels; i++) {
      final t = i / (kAnimalLevels - 1); // 0..1
      final opts = (2 + 3 * t).round(); // 2 → 5
      final pool = (4 + (n - 4) * t).round().clamp(opts, n); // 4 → n
      sets.add(AnimalSet(index: i, optionCount: opts, poolSize: pool));
    }
    return sets;
  }

  /// Все наборы по порядку ([kAnimalLevels] штук).
  static final List<AnimalSet> all = _build();
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
