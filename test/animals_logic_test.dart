import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/animals/logic/animals_logic.dart';

void main() {
  group('Animals.all', () {
    test('у всех зверей есть эмодзи, имя и уникальный ключ звука', () {
      expect(Animals.all, isNotEmpty);
      final keys = <String>{};
      for (final a in Animals.all) {
        expect(a.emoji, isNotEmpty);
        expect(a.name, isNotEmpty);
        expect(keys.add(a.soundKey), isTrue, reason: 'дубликат ключа ${a.soundKey}');
      }
    });
  });

  group('AnimalSet.all', () {
    test('наборы по порядку; пул не меньше числа вариантов', () {
      for (var i = 0; i < AnimalSet.all.length; i++) {
        expect(AnimalSet.all[i].index, i);
        expect(AnimalSet.all[i].poolSize,
            greaterThanOrEqualTo(AnimalSet.all[i].optionCount));
        expect(AnimalSet.all[i].poolSize, lessThanOrEqualTo(Animals.all.length));
      }
    });
  });

  group('генерация раунда', () {
    test('варианты уникальны, цель внутри, ровно один верный (много зёрен)', () {
      for (final s in AnimalSet.all) {
        for (var seed = 0; seed < 200; seed++) {
          final r = AnimalSession.generateRound(s, Random(seed));
          expect(r.options.length, s.optionCount, reason: 'набор ${s.index}');
          expect(r.options.toSet().length, s.optionCount, reason: 'уникальны');
          expect(r.options.contains(r.targetIndex), isTrue);
          expect(r.answerIndex, inInclusiveRange(0, r.options.length - 1));
          expect(r.options[r.answerIndex], r.targetIndex);
          for (final o in r.options) {
            expect(o, inInclusiveRange(0, s.poolSize - 1));
          }
        }
      }
    });

    test('детерминизм по seed', () {
      final a = AnimalSession.generateRound(AnimalSet.all[2], Random(9));
      final b = AnimalSession.generateRound(AnimalSet.all[2], Random(9));
      expect(a.targetIndex, b.targetIndex);
      expect(a.answerIndex, b.answerIndex);
      expect(a.options, b.options);
    });
  });

  group('выбор', () {
    test('верный/неверный распознаётся', () {
      final s = AnimalSession(AnimalSet.all[0], random: Random(1));
      final ans = s.round.answerIndex;
      expect(s.choose(ans).isCorrect, isTrue);
      expect(s.choose(ans == 0 ? 1 : 0).isCorrect, isFalse);
    });
  });

  group('сессия', () {
    test('цель не повторяется в соседних раундах', () {
      final s = AnimalSession(AnimalSet.all[0], random: Random(3));
      var prev = s.round.targetIndex;
      for (var i = 0; i < 15; i++) {
        s.nextRound();
        expect(s.round.targetIndex, isNot(prev), reason: 'раунд $i повторил цель');
        prev = s.round.targetIndex;
      }
    });

    test('цель не повторяется, пока не показаны все из пула (сумка)', () {
      for (final seed in <int>[1, 7, 42]) {
        final set = AnimalSet.all.first; // небольшой пул (8)
        final s = AnimalSession(set, random: Random(seed));
        final seen = <int>{s.round.targetIndex};
        for (var i = 1; i < set.poolSize; i++) {
          s.nextRound();
          expect(seen.add(s.round.targetIndex), isTrue,
              reason: 'цель ${s.round.targetIndex} повторилась внутри цикла пула');
        }
        expect(seen.length, set.poolSize); // показаны все, без дублей
      }
    });
  });

  group('имена', () {
    test('заглавная буква', () {
      expect(animalNameCap(const Animal('🐶', 'собачка', 'dog')), 'Собачка');
    });
  });
}
