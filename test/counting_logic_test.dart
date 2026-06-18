import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/counting/logic/counting_logic.dart';

void main() {
  group('CountSet.all', () {
    test('ровно kCountLevels уровней', () {
      expect(CountSet.all, hasLength(kCountLevels));
    });

    test('наборы пронумерованы по порядку с нуля', () {
      for (var i = 0; i < CountSet.all.length; i++) {
        expect(CountSet.all[i].index, i);
      }
    });

    test('инварианты каждого набора (диапазон/варианты валидны)', () {
      for (final s in CountSet.all) {
        expect(s.minCount, greaterThanOrEqualTo(1));
        expect(s.maxCount, greaterThanOrEqualTo(s.minCount));
        if (s.mode == CountMode.chooseNumeral) {
          // Вариантов не больше, чем различных чисел в диапазоне 1..maxCount.
          expect(s.optionCount, greaterThanOrEqualTo(2));
          expect(s.optionCount, lessThanOrEqualTo(s.maxCount));
        }
      }
    });

    test('счёт тапом идёт сплошным префиксом, потом только выбор цифры', () {
      var seenChoose = false;
      for (final s in CountSet.all) {
        if (s.mode == CountMode.chooseNumeral) seenChoose = true;
        if (seenChoose) {
          expect(s.mode, CountMode.chooseNumeral,
              reason: 'после выбора цифры счёт тапом не возвращается');
        }
      }
    });

    test('в фазе выбора цифры диапазон не убывает', () {
      final choose =
          CountSet.all.where((s) => s.mode == CountMode.chooseNumeral).toList();
      for (var i = 1; i < choose.length; i++) {
        expect(choose[i].maxCount, greaterThanOrEqualTo(choose[i - 1].maxCount));
      }
    });

    test('плавная кривая: начинаем счётом тапом, заканчиваем выбором до 10', () {
      expect(CountSet.all.first.mode, CountMode.tapCount);
      final last = CountSet.all.last;
      expect(last.mode, CountMode.chooseNumeral);
      expect(last.maxCount, 10);
    });

    test('у режима выбора цифры всегда ≥2 вариантов', () {
      for (final s in CountSet.all) {
        if (s.mode == CountMode.chooseNumeral) {
          expect(s.optionCount, greaterThanOrEqualTo(2));
        }
      }
    });
  });

  group('генерация раунда', () {
    test('число объектов всегда в диапазоне набора (много зёрен)', () {
      for (final s in CountSet.all) {
        for (var seed = 0; seed < 200; seed++) {
          final r = CountingSession.generateRound(s, Random(seed));
          expect(r.count, greaterThanOrEqualTo(s.minCount));
          expect(r.count, lessThanOrEqualTo(s.maxCount));
        }
      }
    });

    test('один и тот же seed даёт один и тот же раунд (детерминизм)', () {
      final s = CountSet.all.last; // выбор цифры — проверим и варианты
      final a = CountingSession.generateRound(s, Random(42));
      final b = CountingSession.generateRound(s, Random(42));
      expect(a.count, b.count);
      expect(a.options, b.options);
    });

    test('tapCount: вариантов нет', () {
      final r = CountingSession.generateRound(CountSet.all[0], Random(1));
      expect(r.mode, CountMode.tapCount);
      expect(r.options, isEmpty);
    });
  });

  group('варианты выбора цифры', () {
    test('всегда содержат правильный ответ, нужной длины, без повторов', () {
      for (final s in CountSet.all.where((e) => e.mode == CountMode.chooseNumeral)) {
        for (var seed = 0; seed < 200; seed++) {
          final r = CountingSession.generateRound(s, Random(seed));
          expect(r.options, contains(r.count), reason: 'набор ${s.index}');
          expect(r.options.length, s.optionCount, reason: 'набор ${s.index}');
          expect(r.options.toSet().length, r.options.length,
              reason: 'повторы в наборе ${s.index}');
          for (final o in r.options) {
            expect(o, inInclusiveRange(1, s.maxCount));
          }
        }
      }
    });
  });

  group('режим tapCount', () {
    test('каждый тап считает на один больше, isComplete при достижении числа', () {
      // Набор 0 (1–3). Подбираем seed, дающий count == 3, чтобы проверить путь.
      final session = CountingSession(CountSet.all[0], random: Random(0));
      final target = session.round.count;
      expect(session.counted, 0);

      for (var i = 1; i < target; i++) {
        final res = session.tap();
        expect(res.counted, i);
        expect(res.isComplete, isFalse);
      }
      final last = session.tap();
      expect(last.counted, target);
      expect(last.isComplete, isTrue);
    });

    test('лишние тапы не считаются сверх числа объектов', () {
      final session = CountingSession(CountSet.all[0], random: Random(0));
      final target = session.round.count;
      for (var i = 0; i < target + 5; i++) {
        session.tap();
      }
      expect(session.counted, target);
    });

    test('nextRound сбрасывает счётчик тапов', () {
      final session = CountingSession(CountSet.all[1], random: Random(7));
      session.tap();
      expect(session.counted, greaterThan(0));
      session.nextRound();
      expect(session.counted, 0);
    });
  });

  group('режим chooseNumeral', () {
    final chooseSet =
        CountSet.all.firstWhere((s) => s.mode == CountMode.chooseNumeral);

    test('правильная цифра распознаётся, состояние не меняется', () {
      final session = CountingSession(chooseSet, random: Random(3));
      final answer = session.round.count;
      final res = session.choose(answer);
      expect(res.isCorrect, isTrue);
      expect(res.answer, answer);
      // Раунд не сменился сам — это задача хоста.
      expect(session.round.count, answer);
    });

    test('неверная цифра помечается без штрафа', () {
      final session = CountingSession(chooseSet, random: Random(3));
      final answer = session.round.count;
      final wrong = answer == 1 ? 2 : 1;
      final res = session.choose(wrong);
      expect(res.isCorrect, isFalse);
      expect(res.chosen, wrong);
      expect(res.answer, answer);
    });
  });
}
