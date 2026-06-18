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

/// Вид раскладки инструмента: «лесенка» цветных пластин (ксилофон) или ряд
/// вертикальных клавиш (пианино/орган).
enum InstrumentStyle { bars, keys }

/// Клавишный инструмент «Музыки»: вид раскладки + набор сэмплов. Ноты (до-мажор,
/// 8 — [Xylophone.cMajor]) общие для всех; различаются вид и тембр
/// (`assets/notes/<soundPrefix>_0..7.wav`, генерит `tool/gen_notes.py`).
class Instrument {
  const Instrument({
    required this.id,
    required this.name,
    required this.soundPrefix,
    required this.style,
  });

  /// Технический id (для табов/сравнения).
  final String id;

  /// Подпись таба.
  final String name;

  /// Префикс файлов нот: `assets/notes/<soundPrefix>_N.wav`.
  final String soundPrefix;

  /// Вид раскладки.
  final InstrumentStyle style;

  /// Три инструмента в порядке табов.
  static const List<Instrument> all = <Instrument>[
    Instrument(
        id: 'xylophone',
        name: 'Ксилофон',
        soundPrefix: 'note',
        style: InstrumentStyle.bars),
    Instrument(
        id: 'piano',
        name: 'Пианино',
        soundPrefix: 'piano',
        style: InstrumentStyle.keys),
    Instrument(
        id: 'organ',
        name: 'Орган',
        soundPrefix: 'organ',
        style: InstrumentStyle.keys),
  ];
}
