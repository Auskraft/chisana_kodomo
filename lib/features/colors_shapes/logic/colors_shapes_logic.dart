import 'dart:math';

/// Вид фигуры.
enum ShapeKind { circle, square, triangle, star, diamond, oval }

/// По какому признаку ищем совпадение в раунде.
enum MatchMode { color, shape, both }

/// Объект: индекс цвета (в палитре) + форма.
class CSItem {
  const CSItem(this.colorIndex, this.shape);

  final int colorIndex;
  final ShapeKind shape;
}

/// Набор (ступень) игры «Цвета и формы».
class CSSet {
  const CSSet({
    required this.index,
    required this.mode,
    required this.optionCount,
    required this.colorCount,
  })  : assert(optionCount >= 2),
        assert(colorCount >= 2);

  final int index;
  final MatchMode mode;

  /// Сколько вариантов показать.
  final int optionCount;

  /// Сколько цветов палитры задействовано (растёт по наборам).
  final int colorCount;

  /// Плавная длинная кривая: сперва по цвету, потом по форме, затем по обоим
  /// (сложнее), с ростом числа цветов и вариантов.
  static const List<CSSet> all = <CSSet>[
    CSSet(index: 0, mode: MatchMode.color, optionCount: 3, colorCount: 4),
    CSSet(index: 1, mode: MatchMode.color, optionCount: 4, colorCount: 5),
    CSSet(index: 2, mode: MatchMode.shape, optionCount: 3, colorCount: 4),
    CSSet(index: 3, mode: MatchMode.shape, optionCount: 4, colorCount: 5),
    CSSet(index: 4, mode: MatchMode.shape, optionCount: 5, colorCount: 6),
    CSSet(index: 5, mode: MatchMode.both, optionCount: 3, colorCount: 5),
    CSSet(index: 6, mode: MatchMode.both, optionCount: 4, colorCount: 6),
    CSSet(index: 7, mode: MatchMode.both, optionCount: 4, colorCount: 7),
    CSSet(index: 8, mode: MatchMode.both, optionCount: 5, colorCount: 7),
    CSSet(index: 9, mode: MatchMode.both, optionCount: 5, colorCount: 8),
  ];
}

/// Раунд: цель + варианты (перемешаны) + индекс верного.
class CSRound {
  const CSRound({
    required this.target,
    required this.options,
    required this.mode,
    required this.answerIndex,
  });

  final CSItem target;
  final List<CSItem> options;
  final MatchMode mode;
  final int answerIndex;
}

/// Исход выбора варианта.
class CSChoice {
  const CSChoice({required this.chosen, required this.isCorrect});
  final int chosen;
  final bool isCorrect;
}

/// Чистая логика «Цвета и формы» (только `dart:math`). Без таймеров/проигрыша.
class CSSession {
  CSSession(this.set, {Random? random}) : _rng = random ?? Random() {
    _round = _generate();
  }

  final CSSet set;
  final Random _rng;
  late CSRound _round;

  CSRound get round => _round;

  /// Чистая генерация раунда (та же, что использует сессия). Гарантирует
  /// ровно один верный вариант по признаку набора.
  static CSRound generateRound(CSSet set, Random r) {
    final shapes = ShapeKind.values;
    final colorT = r.nextInt(set.colorCount);
    final shapeT = shapes[r.nextInt(shapes.length)];
    final target = CSItem(colorT, shapeT);
    final options = <CSItem>[target];

    switch (set.mode) {
      case MatchMode.color:
        // Та же форма, другие цвета — отличается только цвет.
        final colors = <int>[for (var i = 0; i < set.colorCount; i++) i]
          ..remove(colorT)
          ..shuffle(r);
        for (final c in colors) {
          if (options.length >= set.optionCount) break;
          options.add(CSItem(c, shapeT));
        }
      case MatchMode.shape:
        // Тот же цвет, другие формы — отличается только форма.
        final others = <ShapeKind>[...shapes]
          ..remove(shapeT)
          ..shuffle(r);
        for (final s in others) {
          if (options.length >= set.optionCount) break;
          options.add(CSItem(colorT, s));
        }
      case MatchMode.both:
        // Различные пары (цвет, форма), не равные цели.
        final seen = <String>{'${colorT}_${shapeT.index}'};
        var guard = 0;
        while (options.length < set.optionCount && guard++ < 500) {
          final c = r.nextInt(set.colorCount);
          final s = shapes[r.nextInt(shapes.length)];
          if (seen.add('${c}_${s.index}')) options.add(CSItem(c, s));
        }
    }

    options.shuffle(r);
    final answerIndex =
        options.indexWhere((o) => _matches(o, target, set.mode));
    return CSRound(
      target: target,
      options: options,
      mode: set.mode,
      answerIndex: answerIndex,
    );
  }

  static bool _matches(CSItem o, CSItem t, MatchMode m) {
    switch (m) {
      case MatchMode.color:
        return o.colorIndex == t.colorIndex;
      case MatchMode.shape:
        return o.shape == t.shape;
      case MatchMode.both:
        return o.colorIndex == t.colorIndex && o.shape == t.shape;
    }
  }

  CSRound _generate() => generateRound(set, _rng);

  /// Выбор варианта. Состояние не меняется — переход к раунду решает хост.
  CSChoice choose(int optionIndex) => CSChoice(
        chosen: optionIndex,
        isCorrect: optionIndex == _round.answerIndex,
      );

  void nextRound() => _round = _generate();
}

// ── Имена для голоса (чистые строки; цвета — в render-слое) ────────────────────

/// Названия цветов (мужской род — для круга/квадрата/треугольника/ромба/овала).
const List<String> kColorNameM = <String>[
  'красный', 'жёлтый', 'синий', 'зелёный', 'оранжевый', 'фиолетовый',
  'розовый', 'коричневый',
];

/// Названия цветов (женский род — для звезды).
const List<String> kColorNameF = <String>[
  'красная', 'жёлтая', 'синяя', 'зелёная', 'оранжевая', 'фиолетовая',
  'розовая', 'коричневая',
];

extension ShapeKindX on ShapeKind {
  /// Существительное-название фигуры (именительный падеж).
  String get noun {
    switch (this) {
      case ShapeKind.circle:
        return 'круг';
      case ShapeKind.square:
        return 'квадрат';
      case ShapeKind.triangle:
        return 'треугольник';
      case ShapeKind.star:
        return 'звезда';
      case ShapeKind.diamond:
        return 'ромб';
      case ShapeKind.oval:
        return 'овал';
    }
  }

  bool get isFeminine => this == ShapeKind.star;
}

/// Имя объекта в именительном падеже, грамматически согласованное:
/// «синий круг», «жёлтая звезда». Для голоса: «Где {имя}?».
String csItemName(CSItem item) {
  final color =
      (item.shape.isFeminine ? kColorNameF : kColorNameM)[item.colorIndex];
  return '$color ${item.shape.noun}';
}
