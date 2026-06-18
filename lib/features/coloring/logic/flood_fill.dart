import 'dart:typed_data';

/// Заливка связной области растрового изображения (RGBA-буфер [pixels] размера
/// [w]×[h]) начиная с пикселя ([startX],[startY]) цветом ([r],[g],[b]).
///
/// Расходится по соседям, пока их цвет близок к исходному (порог [tolerance]) —
/// то есть **останавливается на тёмном контуре**. Если стартовый пиксель сам
/// тёмный (контур, яркость < [outlineLuma]) — не заливаем (тап по линии — no-op).
///
/// Меняет [pixels] на месте, **возвращает индексы закрашенных пикселей** (для
/// отмены). Чистая логика — тестируется.
List<int> floodFill(
  Uint8List pixels,
  int w,
  int h,
  int startX,
  int startY, {
  required int r,
  required int g,
  required int b,
  int tolerance = 64,
  int outlineLuma = 90,
}) {
  final filled = <int>[];
  if (startX < 0 || startY < 0 || startX >= w || startY >= h) return filled;
  if (pixels.length < w * h * 4) return filled;

  final startPixel = startY * w + startX;
  final start = startPixel * 4;
  final sr = pixels[start];
  final sg = pixels[start + 1];
  final sb = pixels[start + 2];

  // Уже целевой цвет — не заливаем повторно.
  if (sr == r && sg == g && sb == b) return filled;
  // Тап попал на тёмный контур — не заливаем (иначе перекрасит всю линию).
  if (0.299 * sr + 0.587 * sg + 0.114 * sb < outlineLuma) return filled;

  final tol2 = tolerance * tolerance * 3;

  bool matchesStart(int byteIdx) {
    final dr = pixels[byteIdx] - sr;
    final dg = pixels[byteIdx + 1] - sg;
    final db = pixels[byteIdx + 2] - sb;
    return dr * dr + dg * dg + db * db <= tol2;
  }

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
    filled.add(p);
    final x = p % w;
    final y = p ~/ w;
    if (x > 0) stack.add(p - 1);
    if (x < w - 1) stack.add(p + 1);
    if (y > 0) stack.add(p - w);
    if (y < h - 1) stack.add(p + w);
  }
  return filled;
}

/// Маска связной «заливаемой» области от пикселя ([startX],[startY]): `Uint8List`
/// размера [w]·[h], где 1 — пиксель внутри области (тот же критерий, что у
/// [floodFill]: близко к стартовому цвету и не темнее контура). Цвета НЕ меняет.
///
/// Используется как «удержание в контуре» для кистей: мазок кладём только туда,
/// где маска = 1. Считаем по ИСХОДНОМУ line-art (а не по уже закрашенному), чтобы
/// область всегда совпадала с полной фигурой. Пусто (все 0), если старт вне
/// границ или попал на тёмный контур.
Uint8List regionMask(
  Uint8List pixels,
  int w,
  int h,
  int startX,
  int startY, {
  int tolerance = 64,
  int outlineLuma = 90,
}) {
  final mask = Uint8List(w * h);
  if (startX < 0 || startY < 0 || startX >= w || startY >= h) return mask;
  if (pixels.length < w * h * 4) return mask;

  final startPixel = startY * w + startX;
  final s = startPixel * 4;
  final sr = pixels[s];
  final sg = pixels[s + 1];
  final sb = pixels[s + 2];
  if (0.299 * sr + 0.587 * sg + 0.114 * sb < outlineLuma) return mask; // контур

  final tol2 = tolerance * tolerance * 3;
  final stack = <int>[startPixel];
  while (stack.isNotEmpty) {
    final p = stack.removeLast();
    if (mask[p] == 1) continue;
    final idx = p * 4;
    final dr = pixels[idx] - sr;
    final dg = pixels[idx + 1] - sg;
    final db = pixels[idx + 2] - sb;
    if (dr * dr + dg * dg + db * db > tol2) continue; // контур/другой цвет — барьер
    mask[p] = 1;
    final x = p % w;
    final y = p ~/ w;
    if (x > 0) stack.add(p - 1);
    if (x < w - 1) stack.add(p + 1);
    if (y > 0) stack.add(p - w);
    if (y < h - 1) stack.add(p + w);
  }
  return mask;
}
