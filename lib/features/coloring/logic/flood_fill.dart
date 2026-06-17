import 'dart:typed_data';

/// Заливка связной области растрового изображения (RGBA-буфер [pixels] размера
/// [w]×[h]) начиная с пикселя ([startX],[startY]) цветом ([r],[g],[b]).
///
/// Расходится по соседям, пока их цвет близок к исходному (порог [tolerance] по
/// каналу) — то есть **останавливается на тёмном контуре**. Меняет [pixels] на
/// месте, возвращает число закрашенных пикселей. Чистая логика — тестируется.
int floodFill(
  Uint8List pixels,
  int w,
  int h,
  int startX,
  int startY, {
  required int r,
  required int g,
  required int b,
  int tolerance = 64,
}) {
  if (startX < 0 || startY < 0 || startX >= w || startY >= h) return 0;
  if (pixels.length < w * h * 4) return 0;

  final startPixel = startY * w + startX;
  final start = startPixel * 4;
  final sr = pixels[start];
  final sg = pixels[start + 1];
  final sb = pixels[start + 2];

  // Уже целевой цвет — не заливаем (иначе зальём весь рисунок повторно).
  if (sr == r && sg == g && sb == b) return 0;

  final tol2 = tolerance * tolerance * 3; // порог по сумме квадратов каналов

  bool matchesStart(int byteIdx) {
    final dr = pixels[byteIdx] - sr;
    final dg = pixels[byteIdx + 1] - sg;
    final db = pixels[byteIdx + 2] - sb;
    return dr * dr + dg * dg + db * db <= tol2;
  }

  var filled = 0;
  final visited = Uint8List(w * h);
  final stack = <int>[startPixel];
  while (stack.isNotEmpty) {
    final p = stack.removeLast();
    if (visited[p] == 1) continue;
    visited[p] = 1;
    final idx = p * 4;
    if (!matchesStart(idx)) continue; // контур/другой цвет — барьер
    pixels[idx] = r;
    pixels[idx + 1] = g;
    pixels[idx + 2] = b;
    pixels[idx + 3] = 255;
    filled++;
    final x = p % w;
    final y = p ~/ w;
    if (x > 0) stack.add(p - 1);
    if (x < w - 1) stack.add(p + 1);
    if (y > 0) stack.add(p - w);
    if (y < h - 1) stack.add(p + w);
  }
  return filled;
}
