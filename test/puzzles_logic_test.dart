import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/puzzles/logic/puzzles_logic.dart';

void main() {
  group('PuzzleSet.all', () {
    test('кусочки растут плавно, сетка валидна, рядов ≥ столбцов', () {
      var prev = 0;
      for (var i = 0; i < PuzzleSet.all.length; i++) {
        final s = PuzzleSet.all[i];
        expect(s.index, i);
        expect(s.rows, greaterThanOrEqualTo(1));
        expect(s.cols, greaterThanOrEqualTo(1));
        expect(s.pieces, s.rows * s.cols);
        expect(s.rows, greaterThanOrEqualTo(s.cols),
            reason: 'портретно-удобно: рядов не меньше столбцов');
        expect(s.pieces, greaterThan(prev), reason: 'кривая монотонна');
        prev = s.pieces;
      }
    });

    test('звёзды по промахам: 0→3, ≤pieces→2, иначе 1 (минимум 1)', () {
      expect(PuzzleSet.starsForMistakes(0, 9), 3);
      expect(PuzzleSet.starsForMistakes(1, 9), 2);
      expect(PuzzleSet.starsForMistakes(9, 9), 2);
      expect(PuzzleSet.starsForMistakes(10, 9), 1);
      expect(PuzzleSet.starsForMistakes(999, 4), 1);
    });
  });

  group('PuzzleSession', () {
    test('лоток — перестановка 0..pieces−1, детерминирован по seed', () {
      final set = PuzzleSet.all[3]; // 9 кусочков
      final a = PuzzleSession(set, random: Random(7)).trayOrder;
      final b = PuzzleSession(set, random: Random(7)).trayOrder;
      expect(a, b, reason: 'один seed → одинаковый лоток');
      expect(a..sort(), <int>[for (var i = 0; i < set.pieces; i++) i],
          reason: 'все индексы ровно один раз');
    });

    test('верное размещение копит progress и завершает картинку', () {
      final set = PuzzleSet.all[1]; // 4 кусочка
      final s = PuzzleSession(set, random: Random(1));
      for (var p = 0; p < set.pieces; p++) {
        expect(s.isPlaced(p), isFalse);
        final r = s.place(p, p); // кусочек p на свою ячейку p
        expect(r.correct, isTrue);
        expect(s.isPlaced(p), isTrue);
        expect(r.isComplete, p == set.pieces - 1);
      }
      expect(s.isComplete, isTrue);
      expect(s.placedCount, set.pieces);
      expect(s.mistakes, 0);
    });

    test('промах: +1 ошибка, кусочек не встаёт, без завершения', () {
      final s = PuzzleSession(PuzzleSet.all[1], random: Random(2));
      final r = s.place(0, 2); // не на свою ячейку
      expect(r.correct, isFalse);
      expect(r.isComplete, isFalse);
      expect(s.isPlaced(0), isFalse);
      expect(s.mistakes, 1);
    });

    test('повторная установка уже стоящего кусочка игнорируется', () {
      final s = PuzzleSession(PuzzleSet.all[1], random: Random(3));
      expect(s.place(0, 0).correct, isTrue);
      final again = s.place(0, 0);
      expect(again.correct, isFalse, reason: 'не считается повторно');
      expect(s.placedCount, 1);
      expect(s.mistakes, 0, reason: 'повтор — не промах');
    });

    test('nextPicture очищает доску и перемешивает, но хранит промахи', () {
      final set = PuzzleSet.all[3];
      final s = PuzzleSession(set, random: Random(5));
      s.place(0, 1); // промах
      s.place(0, 0); // верно
      expect(s.mistakes, 1);
      expect(s.placedCount, 1);

      s.nextPicture();
      expect(s.placedCount, 0, reason: 'доска очищена');
      expect(s.isComplete, isFalse);
      expect(s.mistakes, 1, reason: 'промахи набора сохраняются');
      expect(s.trayOrder..sort(), <int>[for (var i = 0; i < set.pieces; i++) i]);
    });
  });
}
