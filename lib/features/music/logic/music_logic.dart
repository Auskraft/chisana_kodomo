import 'dart:math' as math;

/// Пластина ксилофона: подпись (сольфеджио) + полутон от «до» и частота.
///
/// Частота нужна для **процедурного тона в Фазе 5**; подпись — для возможной
/// озвучки названия ноты. Сейчас инструмент откликается цветом/отскоком/вибро.
class XyloNote {
  const XyloNote(this.label, this.semitone);

  /// Подпись ноты («до», «ре», …).
  final String label;

  /// Полутонов от базовой «до» (C4).
  final int semitone;
}

/// Ксилофон в детской раскладке.
abstract final class Xylophone {
  /// До-мажор, одна октава — 8 пластин (привычно и радостно звучит детям).
  static const List<XyloNote> cMajor = <XyloNote>[
    XyloNote('до', 0),
    XyloNote('ре', 2),
    XyloNote('ми', 4),
    XyloNote('фа', 5),
    XyloNote('соль', 7),
    XyloNote('ля', 9),
    XyloNote('си', 11),
    XyloNote('до²', 12),
  ];

  /// Базовая частота «до» (C4), Гц.
  static const double baseHz = 261.63;

  /// Частота ноты по полутону (равномерная темперация) — для тона в Фазе 5.
  static double frequency(int semitone) =>
      baseHz * math.pow(2, semitone / 12).toDouble();
}
