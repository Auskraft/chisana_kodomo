import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/odd_one_out/logic/odd_one_out_logic.dart';

/// Индекс категории предмета (или -1).
int _catOf(String emoji) {
  for (var i = 0; i < OddItems.categories.length; i++) {
    if (OddItems.categories[i].items.contains(emoji)) return i;
  }
  return -1;
}

void main() {
  group('OddItems', () {
    test('≥2 категорий; эмодзи не пересекаются между категориями', () {
      expect(OddItems.categories.length, greaterThanOrEqualTo(2));
      final seen = <String>{};
      for (final c in OddItems.categories) {
        expect(c.items.length, greaterThanOrEqualTo(4));
        for (final e in c.items) {
          expect(e, isNotEmpty);
          expect(seen.add(e), isTrue, reason: 'эмодзи $e в двух категориях');
        }
      }
    });
  });

  group('OddSet.all', () {
    test('ровно kOddLevels уровней', () {
      expect(OddSet.all, hasLength(kOddLevels));
    });

    test('по порядку, optionCount ≥ 3', () {
      for (var i = 0; i < OddSet.all.length; i++) {
        expect(OddSet.all[i].index, i);
        expect(OddSet.all[i].optionCount, greaterThanOrEqualTo(3));
      }
    });

    test('optionCount−1 ≤ размера наименьшей категории (генерация заполнима)', () {
      final minCat = OddItems.categories
          .map((c) => c.items.length)
          .reduce((a, b) => a < b ? a : b);
      for (final s in OddSet.all) {
        // (optionCount−1) предметов берутся из категории-большинства.
        expect(s.optionCount - 1, lessThanOrEqualTo(minCat), reason: 'набор ${s.index}');
      }
    });

    test('сложность не убывает; растёт от 3 до потолка', () {
      expect(OddSet.all.first.optionCount, 3);
      for (var i = 1; i < OddSet.all.length; i++) {
        expect(OddSet.all[i].optionCount,
            greaterThanOrEqualTo(OddSet.all[i - 1].optionCount));
      }
      expect(OddSet.all.last.optionCount, greaterThan(3));
    });
  });

  group('генерация раунда', () {
    test('ровно один лишний; длина и индекс верны (много зёрен)', () {
      for (final s in OddSet.all) {
        for (var seed = 0; seed < 300; seed++) {
          final r = OddSession.generateRound(s, Random(seed));
          expect(r.items.length, s.optionCount, reason: 'набор ${s.index}');
          expect(r.oddIndex, inInclusiveRange(0, r.items.length - 1));

          // Ровно две категории: большинство (optionCount-1) и лишний (1).
          final byCat = <int, int>{};
          for (final e in r.items) {
            final c = _catOf(e);
            byCat[c] = (byCat[c] ?? 0) + 1;
          }
          expect(byCat.length, 2, reason: 'набор ${s.index}, seed $seed');
          final oddCat = _catOf(r.odd);
          expect(byCat[oddCat], 1, reason: 'лишний должен быть один');
        }
      }
    });

    test('детерминизм по seed', () {
      final a = OddSession.generateRound(OddSet.all[3], Random(8));
      final b = OddSession.generateRound(OddSet.all[3], Random(8));
      expect(a.items, b.items);
      expect(a.oddIndex, b.oddIndex);
    });
  });

  group('выбор', () {
    test('верный/неверный распознаётся', () {
      final s = OddSession(OddSet.all[1], random: Random(2));
      final odd = s.round.oddIndex;
      expect(s.choose(odd).isCorrect, isTrue);
      expect(s.choose(odd == 0 ? 1 : 0).isCorrect, isFalse);
    });
  });
}
