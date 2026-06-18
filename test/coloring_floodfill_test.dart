import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/coloring/logic/flood_fill.dart';

/// Сплошной серый/белый RGBA-буфер [w]×[h] со значением [v] во всех каналах.
Uint8List _grid(int w, int h, int v) {
  final px = Uint8List(w * h * 4);
  for (var i = 0; i < w * h; i++) {
    px[i * 4] = v;
    px[i * 4 + 1] = v;
    px[i * 4 + 2] = v;
    px[i * 4 + 3] = 255;
  }
  return px;
}

void main() {
  test('заливка останавливается на тёмном контуре', () {
    const w = 5, h = 3;
    final px = _grid(w, h, 255); // белое поле
    // Вертикальная чёрная линия в столбце 2 — барьер.
    for (var y = 0; y < h; y++) {
      final i = (y * w + 2) * 4;
      px[i] = 0;
      px[i + 1] = 0;
      px[i + 2] = 0;
    }
    final n = floodFill(px, w, h, 0, 0, r: 255, g: 0, b: 0).length;
    expect(n, 6); // столбцы 0–1 × 3 строки

    // Левая часть стала красной.
    expect(px[0], 255);
    expect(px[1], 0);
    expect(px[2], 0);
    // Контур цел.
    final line = (0 * w + 2) * 4;
    expect(px[line], 0);
    // Правая часть не тронута (белая).
    final right = (0 * w + 3) * 4;
    expect(px[right], 255);
    expect(px[right + 1], 255);
    expect(px[right + 2], 255);
  });

  test('повторная заливка светлым тем же цветом ничего не делает', () {
    final px = _grid(2, 2, 255);
    floodFill(px, 2, 2, 0, 0, r: 200, g: 200, b: 200);
    final n = floodFill(px, 2, 2, 0, 0, r: 200, g: 200, b: 200).length;
    expect(n, 0);
  });

  test('тап по тёмному контуру не заливает', () {
    final px = _grid(3, 3, 255);
    // Центральный пиксель — чёрный «контур».
    final c = (1 * 3 + 1) * 4;
    px[c] = 0;
    px[c + 1] = 0;
    px[c + 2] = 0;
    final n = floodFill(px, 3, 3, 1, 1, r: 255, g: 0, b: 0).length;
    expect(n, 0); // старт на контуре → ничего
    expect(px[c], 0); // контур цел
  });

  test('старт вне границ — пусто', () {
    final px = _grid(2, 2, 255);
    expect(floodFill(px, 2, 2, -1, 0, r: 1, g: 2, b: 3), isEmpty);
    expect(floodFill(px, 2, 2, 5, 5, r: 1, g: 2, b: 3), isEmpty);
  });

  test('сплошное светлое поле заливается целиком', () {
    const w = 4, h = 4;
    final px = _grid(w, h, 250);
    final n = floodFill(px, w, h, 1, 1, r: 0, g: 128, b: 0).length;
    expect(n, w * h);
  });

  group('regionMask (удержание в контуре)', () {
    int count(Uint8List m) => m.where((int v) => v == 1).length;

    test('маска ограничена тёмным контуром; пиксели не меняются', () {
      const w = 5, h = 3;
      final px = _grid(w, h, 255);
      for (var y = 0; y < h; y++) {
        final i = (y * w + 2) * 4;
        px[i] = 0;
        px[i + 1] = 0;
        px[i + 2] = 0;
      }
      final m = regionMask(px, w, h, 0, 0);
      expect(count(m), 6); // столбцы 0–1 × 3 строки
      expect(m[0 * w + 0], 1);
      expect(m[0 * w + 2], 0); // контур не в маске
      expect(m[0 * w + 3], 0); // правая часть за барьером
      expect(px[0], 255); // буфер не тронут
      expect(px[(0 * w + 3) * 4], 255);
    });

    test('старт на тёмном контуре → пустая маска', () {
      final px = _grid(3, 3, 255);
      final c = (1 * 3 + 1) * 4;
      px[c] = 0;
      px[c + 1] = 0;
      px[c + 2] = 0;
      expect(count(regionMask(px, 3, 3, 1, 1)), 0);
    });

    test('вне границ → пустая маска', () {
      final px = _grid(2, 2, 255);
      expect(count(regionMask(px, 2, 2, -1, 0)), 0);
      expect(count(regionMask(px, 2, 2, 9, 9)), 0);
    });

    test('сплошное светлое поле → маска целиком', () {
      expect(count(regionMask(_grid(4, 4, 250), 4, 4, 2, 2)), 16);
    });
  });
}
