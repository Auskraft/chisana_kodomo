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
}
