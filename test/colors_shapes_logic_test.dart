import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/colors_shapes/logic/colors_shapes_logic.dart';

bool _matches(CSItem o, CSItem t, MatchMode m) {
  switch (m) {
    case MatchMode.color:
      return o.colorIndex == t.colorIndex;
    case MatchMode.shape:
      return o.shape == t.shape;
    case MatchMode.both:
      return o.colorIndex == t.colorIndex && o.shape == t.shape;
  }
}

void main() {
  group('CSSet.all', () {
    test('наборы по порядку; кривая color → shape → both', () {
      for (var i = 0; i < CSSet.all.length; i++) {
        expect(CSSet.all[i].index, i);
      }
      expect(CSSet.all.first.mode, MatchMode.color);
      expect(CSSet.all.last.mode, MatchMode.both);
    });
  });

  group('генерация раунда', () {
    test('варианты нужной длины, цель внутри, ровно один верный (много зёрен)',
        () {
      for (final s in CSSet.all) {
        for (var seed = 0; seed < 300; seed++) {
          final r = CSSession.generateRound(s, Random(seed));
          expect(r.options.length, s.optionCount, reason: 'набор ${s.index}');
          expect(r.answerIndex, inInclusiveRange(0, r.options.length - 1));

          // Цель присутствует среди вариантов.
          expect(
            r.options.any((o) =>
                o.colorIndex == r.target.colorIndex && o.shape == r.target.shape),
            isTrue,
            reason: 'цель должна быть среди вариантов (набор ${s.index})',
          );

          // Ровно один вариант совпадает по признаку набора, и это ответ.
          final matching = <int>[];
          for (var i = 0; i < r.options.length; i++) {
            if (_matches(r.options[i], r.target, r.mode)) matching.add(i);
          }
          expect(matching, hasLength(1), reason: 'набор ${s.index}, seed $seed');
          expect(matching.single, r.answerIndex);

          // Индексы цвета в пределах набора.
          for (final o in r.options) {
            expect(o.colorIndex, inInclusiveRange(0, s.colorCount - 1));
          }
        }
      }
    });

    test('детерминизм по seed', () {
      final a = CSSession.generateRound(CSSet.all[3], Random(7));
      final b = CSSession.generateRound(CSSet.all[3], Random(7));
      expect(a.answerIndex, b.answerIndex);
      expect(a.target.colorIndex, b.target.colorIndex);
      expect(a.target.shape, b.target.shape);
      expect(a.options.map((o) => '${o.colorIndex}_${o.shape.index}').toList(),
          b.options.map((o) => '${o.colorIndex}_${o.shape.index}').toList());
    });
  });

  group('выбор', () {
    test('верный/неверный распознаётся', () {
      final s = CSSession(CSSet.all[0], random: Random(1));
      final ans = s.round.answerIndex;
      expect(s.choose(ans).isCorrect, isTrue);
      final wrong = ans == 0 ? 1 : 0;
      expect(s.choose(wrong).isCorrect, isFalse);
    });

    test('nextRound меняет раунд (в среднем)', () {
      final s = CSSession(CSSet.all[3], random: Random(2));
      final before = '${s.round.target.colorIndex}_${s.round.target.shape.index}'
          '_${s.round.answerIndex}';
      var changed = false;
      for (var i = 0; i < 5; i++) {
        s.nextRound();
        final now = '${s.round.target.colorIndex}_${s.round.target.shape.index}'
            '_${s.round.answerIndex}';
        if (now != before) changed = true;
      }
      expect(changed, isTrue);
    });
  });

  group('имена', () {
    test('род согласован: звезда — женский, остальные — мужской', () {
      expect(csItemName(const CSItem(0, ShapeKind.circle)), 'красный круг');
      expect(csItemName(const CSItem(1, ShapeKind.star)), 'жёлтая звезда');
      expect(kColorNameM, hasLength(6));
      expect(kColorNameF, hasLength(6));
    });
  });
}
