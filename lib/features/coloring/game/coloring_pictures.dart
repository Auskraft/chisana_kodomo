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

/// Динамическая галерея растровых раскрасок: все картинки из `assets/coloring/`
/// (PNG/JPG). Заполняется из манифеста ассетов один раз. Контурные рисунки
/// (CC0/Magnific) кладёт владелец — появятся здесь автоматически, без правок кода.
abstract final class RasterGallery {
  static Map<int, List<String>> _byLevel = const <int, List<String>>{};
  static bool _loaded = false;

  /// Есть ли вообще растровые раскраски.
  static bool get hasImages => _byLevel.isNotEmpty;

  /// Доступные уровни сложности (по возрастанию) — те, где есть картинки.
  static List<int> get levels => _byLevel.keys.toList()..sort();

  /// Картинки уровня [level] (папка `assets/coloring/<level>/`).
  static List<String> imagesForLevel(int level) =>
      _byLevel[level] ?? const <String>[];

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final map = <int, List<String>>{};
      for (final k in manifest.listAssets()) {
        if (!k.startsWith('assets/coloring/')) continue;
        if (!(k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.jpeg'))) {
          continue;
        }
        // Путь вида assets/coloring/<уровень>/<файл> — берём номер уровня.
        final rest = k.substring('assets/coloring/'.length);
        final slash = rest.indexOf('/');
        if (slash <= 0) continue; // файл в корне (без уровня) — пропускаем
        final lvl = int.tryParse(rest.substring(0, slash));
        if (lvl == null) continue;
        (map[lvl] ??= <String>[]).add(k);
      }
      for (final list in map.values) {
        list.sort();
      }
      _byLevel = map;
    } catch (_) {
      _byLevel = const <int, List<String>>{};
    }
  }
}
