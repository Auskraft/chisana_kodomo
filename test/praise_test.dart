import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/core/praise/praise.dart';

void main() {
  group('Praise', () {
    test('pick детерминирован по seed и из набора фраз', () {
      expect(Praise.pick(Random(1)), Praise.pick(Random(1)));
      expect(Praise.phrases, contains(Praise.pick(Random(5))));
    });

    test('звёзды по ошибкам: 0→3, 1–2→2, 3+→1 (но всегда ≥1)', () {
      expect(Praise.starsForMistakes(0), 3);
      expect(Praise.starsForMistakes(1), 2);
      expect(Praise.starsForMistakes(2), 2);
      expect(Praise.starsForMistakes(3), 1);
      expect(Praise.starsForMistakes(99), 1);
    });
  });

  group('Gender / обращение', () {
    test('fromId: boy/girl, иначе нейтрально', () {
      expect(Gender.fromId('boy'), Gender.boy);
      expect(Gender.fromId('girl'), Gender.girl);
      expect(Gender.fromId(null), Gender.neutral);
      expect(Gender.fromId('xxx'), Gender.neutral);
    });

    test('setDone согласован по роду', () {
      expect(Praise.setDone(Gender.boy), contains('справился'));
      expect(Praise.setDone(Gender.girl), contains('справилась'));
      expect(Praise.setDone(Gender.neutral), isNot(contains('справил')));
    });

    test('фразы похвалы нейтральны (без «справил…»)', () {
      for (final p in Praise.phrases) {
        expect(p.contains('справил'), isFalse, reason: p);
      }
    });
  });
}
