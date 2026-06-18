import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

/// Кэш PNG-иконок `assets/ui/<name>.png` для рисования прямо в Flame-канвасе
/// (напр. звук-кнопка «динамик» в «Ферме» и «Звуках животных»). Значение `null` —
/// файла нет (рисуем эмодзи-запас). Грузится один раз на имя и шарится.
abstract final class UiSprites {
  static final Map<String, Image?> _cache = <String, Image?>{};
  static final Map<String, Future<Image?>> _inflight =
      <String, Future<Image?>>{};

  /// Уже загруженная картинка (или null) — синхронно для `render()`.
  static Image? cached(String name) => _cache[name];

  /// Загрузить иконку (с кэшем). null — если файла нет.
  static Future<Image?> load(String name) {
    if (_cache.containsKey(name)) return Future<Image?>.value(_cache[name]);
    return _inflight[name] ??= _doLoad(name);
  }

  static Future<Image?> _doLoad(String name) async {
    Image? image;
    try {
      final data = await rootBundle.load('assets/ui/$name.png');
      final codec = await instantiateImageCodec(data.buffer.asUint8List());
      image = (await codec.getNextFrame()).image;
    } catch (_) {
      image = null;
    }
    _cache[name] = image;
    _inflight.remove(name);
    return image;
  }

  /// Нарисовать иконку, вписав её по центру прямоугольника [box] (contain —
  /// пропорции сохраняются, прозрачность остаётся).
  static void paintInRect(Canvas canvas, Image image, Rect box) {
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale =
        (box.width / iw < box.height / ih) ? box.width / iw : box.height / ih;
    final dst = Rect.fromCenter(
      center: box.center,
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
}
