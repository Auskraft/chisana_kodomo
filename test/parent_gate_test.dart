import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/core/parent_gate/parent_gate.dart';

void main() {
  group('ParentGateChallenge', () {
    test('ответ = a×b; вопрос содержит множители', () {
      const ch = ParentGateChallenge(a: 6, b: 7, options: <int>[42, 40, 41, 43]);
      expect(ch.answer, 42);
      expect(ch.question, '6 × 7');
      expect(ch.isCorrect(42), isTrue);
      expect(ch.isCorrect(43), isFalse);
    });

    test('генерация: 4 различных положительных варианта, верный внутри (зёрна)', () {
      for (var seed = 0; seed < 300; seed++) {
        final ch = ParentGateChallenge.generate(Random(seed));
        expect(ch.options, hasLength(4));
        expect(ch.options.toSet(), hasLength(4), reason: 'все различны');
        expect(ch.options.every((o) => o > 0), isTrue);
        expect(ch.options.contains(ch.answer), isTrue);
        expect(ch.a, inInclusiveRange(3, 9));
        expect(ch.b, inInclusiveRange(3, 9));
      }
    });

    test('детерминизм по seed', () {
      final a = ParentGateChallenge.generate(Random(11));
      final b = ParentGateChallenge.generate(Random(11));
      expect(a.a, b.a);
      expect(a.b, b.b);
      expect(a.options, b.options);
    });
  });
}
