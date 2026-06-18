import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../logic/coloring_logic.dart';

/// Палитра раскраски (детские цвета). Индексы — это «номера» для режима
/// «по номерам» (показываются как 1..N). Хардкод-контент, как [kShapeColors].
const List<Color> kColoringPalette = <Color>[
  Color(0xFFE53935), // 1 — красный
  Color(0xFFFB8C00), // 2 — оранжевый
  Color(0xFFFDD835), // 3 — жёлтый
  Color(0xFF66BB6A), // 4 — зелёный
  Color(0xFF42A5F5), // 5 — синий
  Color(0xFFAB47BC), // 6 — фиолетовый
  Color(0xFF8D6E63), // 7 — коричневый
  Color(0xFFF06292), // 8 — розовый
];

/// Область картинки с геометрией: строит [Path] под переданный квадрат [fit].
/// [labelFrac] — где (в долях [fit]) показать номер в режиме «по номерам».
/// [priority] — порядок отрисовки/тапа (выше → сверху, для вложенных областей).
class PaintableRegion {
  PaintableRegion({
    required this.id,
    required this.build,
    required this.labelFrac,
    this.targetColor = 0,
    this.priority = 0,
  });

  final int id;
  final Path Function(Rect fit) build;
  final Offset labelFrac;
  final int targetColor;
  final int priority;
}

/// Картинка-раскраска: имя + области с геометрией. [toModel] даёт чистую модель
/// для [ColoringState] (без геометрии).
class PaintablePicture {
  PaintablePicture({required this.name, required this.regions});

  final String name;
  final List<PaintableRegion> regions;

  ColoringPicture toModel() => ColoringPicture(
        name: name,
        regions: <ColorRegion>[
          for (final r in regions) ColorRegion(id: r.id, targetColor: r.targetColor),
        ],
      );
}

// ── Хелперы геометрии (координаты — доли квадрата fit) ──────────────────────────

Path _rect(Rect f, double x, double y, double w, double h) => Path()
  ..addRect(Rect.fromLTWH(
    f.left + f.width * x,
    f.top + f.height * y,
    f.width * w,
    f.height * h,
  ));

Path _circle(Rect f, double cx, double cy, double r) => Path()
  ..addOval(Rect.fromCircle(
    center: Offset(f.left + f.width * cx, f.top + f.height * cy),
    radius: f.width * r,
  ));

Path _poly(Rect f, List<List<double>> pts) {
  final p = Path();
  for (var i = 0; i < pts.length; i++) {
    final dx = f.left + f.width * pts[i][0];
    final dy = f.top + f.height * pts[i][1];
    if (i == 0) {
      p.moveTo(dx, dy);
    } else {
      p.lineTo(dx, dy);
    }
  }
  return p..close();
}

/// Маленькая галерея картинок (строятся из фигур в коде — без рисованных ассетов).
abstract final class ColoringGallery {
  /// Домик: солнце, крыша, стена, дверь, окно.
  static final PaintablePicture house = PaintablePicture(
    name: 'Домик',
    regions: <PaintableRegion>[
      PaintableRegion(
        id: 0,
        targetColor: 2, // жёлтый
        labelFrac: const Offset(0.2, 0.2),
        build: (f) => _circle(f, 0.2, 0.2, 0.1),
      ),
      PaintableRegion(
        id: 1,
        targetColor: 0, // красный
        labelFrac: const Offset(0.5, 0.35),
        build: (f) => _poly(f, <List<double>>[
          <double>[0.2, 0.46],
          <double>[0.8, 0.46],
          <double>[0.5, 0.18],
        ]),
      ),
      PaintableRegion(
        id: 2,
        targetColor: 1, // оранжевый
        labelFrac: const Offset(0.62, 0.62),
        build: (f) => _rect(f, 0.25, 0.46, 0.5, 0.34),
      ),
      PaintableRegion(
        id: 3,
        targetColor: 6, // коричневый — дверь
        priority: 1,
        labelFrac: const Offset(0.52, 0.71),
        build: (f) => _rect(f, 0.46, 0.62, 0.12, 0.18),
      ),
      PaintableRegion(
        id: 4,
        targetColor: 4, // синий — окно
        priority: 1,
        labelFrac: const Offset(0.35, 0.57),
        build: (f) => _rect(f, 0.29, 0.52, 0.12, 0.1),
      ),
    ],
  );

  /// Цветок: серединка, 5 лепестков, стебель, 2 листика.
  static final PaintablePicture flower = _buildFlower();

  static PaintablePicture _buildFlower() {
    final regions = <PaintableRegion>[
      PaintableRegion(
        id: 0,
        targetColor: 2, // серединка — жёлтая
        priority: 2,
        labelFrac: const Offset(0.5, 0.4),
        build: (f) => _circle(f, 0.5, 0.4, 0.1),
      ),
    ];
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5;
      final cx = 0.5 + 0.18 * cos(a);
      final cy = 0.4 + 0.18 * sin(a);
      regions.add(PaintableRegion(
        id: 1 + i,
        targetColor: 7, // лепестки — розовые
        priority: 1,
        labelFrac: Offset(cx, cy),
        build: (f) => _circle(f, cx, cy, 0.09),
      ));
    }
    regions.add(PaintableRegion(
      id: 6,
      targetColor: 3, // стебель — зелёный
      labelFrac: const Offset(0.5, 0.68),
      build: (f) => _rect(f, 0.47, 0.5, 0.06, 0.34),
    ));
    regions.add(PaintableRegion(
      id: 7,
      targetColor: 3, // листик слева
      labelFrac: const Offset(0.39, 0.66),
      build: (f) => _circle(f, 0.39, 0.66, 0.06),
    ));
    regions.add(PaintableRegion(
      id: 8,
      targetColor: 3, // листик справа
      labelFrac: const Offset(0.61, 0.64),
      build: (f) => _circle(f, 0.61, 0.64, 0.06),
    ));
    return PaintablePicture(name: 'Цветок', regions: regions);
  }

  /// Все картинки по порядку.
  static final List<PaintablePicture> all = <PaintablePicture>[house, flower];
}

// ── Категории раскрасок (тема × уровень сложности) ──────────────────────────────

/// Метаданные категории для селектора: подпись (RU) и эмодзи-иконка.
class ColoringCategoryMeta {
  const ColoringCategoryMeta(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Известные темы: подпись + эмодзи. Папка — `assets/coloring/<ключ>/<уровень>/`.
/// Незнакомый ключ-папка тоже работает (подпись = ключ, иконка 🎨).
const Map<String, ColoringCategoryMeta> kColoringCategoryMeta =
    <String, ColoringCategoryMeta>{
  'animals': ColoringCategoryMeta('Животные', '🐶'),
  'cars': ColoringCategoryMeta('Транспорт', '🚗'),
  'nature': ColoringCategoryMeta('Природа', '🌼'),
  'food': ColoringCategoryMeta('Еда', '🍎'),
  'sea': ColoringCategoryMeta('Море', '🌊'),
  'space': ColoringCategoryMeta('Космос', '🚀'),
};

/// Порядок тем в селекторе: известные — в этом порядке, прочие — после.
const List<String> kColoringCategoryOrder = <String>[
  'animals', 'cars', 'nature', 'food', 'sea', 'space',
];

/// Метаданные темы по ключу (с фолбэком для незнакомых папок).
ColoringCategoryMeta coloringCategoryMeta(String key) =>
    kColoringCategoryMeta[key] ?? ColoringCategoryMeta(key, '🎨');

/// Разобрать путь ассета раскраски `assets/coloring/<кат>/<уровень>/<файл>`.
/// Возвращает (категория, уровень) либо null, если путь не подходит (не картинка,
/// нет сегмента темы/уровня). Чистая функция — тестируется без бандла.
({String category, int level})? parseColoringAsset(String path) {
  const prefix = 'assets/coloring/';
  if (!path.startsWith(prefix)) return null;
  final lower = path.toLowerCase();
  if (!(lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg'))) {
    return null;
  }
  final parts = path.substring(prefix.length).split('/');
  if (parts.length < 3) return null; // нужно <кат>/<уровень>/<файл>
  final category = parts[0];
  final level = int.tryParse(parts[1]);
  if (category.isEmpty || level == null) return null;
  return (category: category, level: level);
}

/// Один пункт пикера картинок: ассет-раскраска + её уровень (для группировки и
/// порядка) + ключ темы (чтобы выбрать картинку из любой темы через табы).
class ColoringPick {
  const ColoringPick({
    required this.asset,
    required this.level,
    required this.category,
  });
  final String asset;
  final int level;
  final String category;
}

/// Динамическая галерея растровых раскрасок: картинки из
/// `assets/coloring/<тема>/<уровень>/` (PNG/JPG), сгруппированные по теме и
/// уровню. Заполняется из манифеста ассетов один раз. Контурные рисунки
/// (CC0/Magnific) кладёт владелец — появляются здесь автоматически, без правок кода.
abstract final class RasterGallery {
  static Map<String, Map<int, List<String>>> _byCat =
      const <String, Map<int, List<String>>>{};
  static bool _loaded = false;

  /// Есть ли вообще растровые раскраски.
  static bool get hasImages => _byCat.isNotEmpty;

  /// Темы с картинками — известные в заданном порядке, прочие после (по алфавиту).
  static List<String> get categories {
    final present = _byCat.keys.toSet();
    final ordered = <String>[
      for (final k in kColoringCategoryOrder)
        if (present.contains(k)) k,
    ];
    final extras =
        present.where((k) => !kColoringCategoryOrder.contains(k)).toList()
          ..sort();
    return <String>[...ordered, ...extras];
  }

  /// Уровни темы [category] с картинками (по возрастанию).
  static List<int> levelsFor(String category) =>
      (_byCat[category]?.keys.toList() ?? <int>[])..sort();

  /// Картинки темы [category] и уровня [level].
  static List<String> imagesFor(String category, int level) =>
      _byCat[category]?[level] ?? const <String>[];

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final map = <String, Map<int, List<String>>>{};
      for (final k in manifest.listAssets()) {
        final parsed = parseColoringAsset(k);
        if (parsed == null) continue;
        ((map[parsed.category] ??= <int, List<String>>{})[parsed.level] ??=
            <String>[])
            .add(k);
      }
      for (final byLevel in map.values) {
        for (final list in byLevel.values) {
          list.sort();
        }
      }
      _byCat = map;
    } catch (_) {
      _byCat = const <String, Map<int, List<String>>>{};
    }
  }
}
