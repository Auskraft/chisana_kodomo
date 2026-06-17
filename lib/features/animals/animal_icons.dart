import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

/// Кэш арт-иконок зверей `assets/animals/<key>.png`. Значение `null` — файла нет
/// (рисуем эмодзи-запас). Грузится один раз на ключ и шарится между играми
/// («Ферма» и квиз «Звуки животных»).
abstract final class AnimalIcons {
  static final Map<String, Image?> _cache = <String, Image?>{};
  static final Map<String, Future<Image?>> _inflight = <String, Future<Image?>>{};

  /// Уже загруженная картинка (или null) — синхронно для `render()`.
  static Image? cached(String key) => _cache[key];

  /// Загрузить иконку (с кэшем). null — если файла нет (тогда эмодзи).
  static Future<Image?> load(String key) {
    if (_cache.containsKey(key)) return Future<Image?>.value(_cache[key]);
    return _inflight[key] ??= _doLoad(key);
  }

  static Future<Image?> _doLoad(String key) async {
    Image? image;
    try {
      final data = await rootBundle.load('assets/animals/$key.png');
      final codec = await instantiateImageCodec(data.buffer.asUint8List());
      image = (await codec.getNextFrame()).image;
    } catch (_) {
      image = null;
    }
    _cache[key] = image;
    _inflight.remove(key);
    return image;
  }

  /// Нарисовать картинку, «вписав» в квадрат [side] по центру (contain).
  static void paintContained(Canvas canvas, Image image, double side) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale = side / (iw > ih ? iw : ih);
    final dst = Rect.fromCenter(
      center: Offset(side / 2, side / 2),
      width: iw * scale,
      height: ih * scale,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, iw, ih),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  /// Нарисовать иконку как **скруглённую карточку с мягкой тенью** (заполняя
  /// квадрат [side], cover). Для плиток-вариантов в квизе.
  static void paintRoundedCard(Canvas canvas, Image image, double side) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, side, side),
      Radius.circular(side * 0.22),
    );
    // Мягкая тень.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x26000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale = side / (iw < ih ? iw : ih); // cover
    final dst = Rect.fromCenter(
      center: Offset(side / 2, side / 2),
      width: iw * scale,
      height: ih * scale,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, iw, ih),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }
}
