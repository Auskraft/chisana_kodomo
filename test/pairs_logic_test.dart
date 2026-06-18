import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/pairs/logic/pairs_logic.dart';

void main() {
  group('PairsSet.all', () {
    test('наборы по порядку; число пар растёт', () {
      for (var i = 0; i < PairsSet.all.length; i++) {
        expect(PairsSet.all[i].index, i);
      }
      for (var i = 1; i < PairsSet.all.length; i++) {
        expect(PairsSet.all[i].pairs, greaterThanOrEqualTo(PairsSet.all[i - 1].pairs));
      }
      expect(PairsSet.all.first.cardCount, 4);
    });

  });

  group('колода', () {
    test('каждый символ ровно дважды; длина = pairs*2', () {
      for (final s in PairsSet.all) {
        final session = PairsSession(s, random: Random(1));
        expect(session.cards.length, s.cardCount);
        final counts = <int, int>{};
        for (final c in session.cards) {
          counts[c.symbol] = (counts[c.symbol] ?? 0) + 1;
        }
        expect(counts.length, s.pairs);
        expect(counts.values.every((v) => v == 2), isTrue);
      }
    });

    test('детерминизм по seed', () {
      final a = PairsSession(PairsSet.all[3], random: Random(7));
      final b = PairsSession(PairsSet.all[3], random: Random(7));
      expect(a.cards.map((c) => c.symbol).toList(),
          b.cards.map((c) => c.symbol).toList());
    });
  });

  group('перевороты', () {
    /// Найти индексы двух карт с символом [symbol].
    List<int> indicesOf(PairsSession s, int symbol) => <int>[
          for (var i = 0; i < s.cards.length; i++)
            if (s.cards[i].symbol == symbol) i,
        ];

    test('первая карта → firstUp, не завершено', () {
      final s = PairsSession(PairsSet.all[0], random: Random(1));
      final r = s.flip(0);
      expect(r.outcome, FlipOutcome.firstUp);
      expect(s.cards[0].faceUp, isTrue);
      expect(s.isComplete, isFalse);
    });

    test('совпадение помечает обе как matched', () {
      final s = PairsSession(PairsSet.all[0], random: Random(1));
      final pair = indicesOf(s, s.cards[0].symbol);
      s.flip(pair[0]);
      final r = s.flip(pair[1]);
      expect(r.outcome, FlipOutcome.matched);
      expect(r.otherIndex, pair[0]);
      expect(s.cards[pair[0]].matched, isTrue);
      expect(s.cards[pair[1]].matched, isTrue);
    });

    test('несовпадение: блокировка, +1 промах, закрытие снимает блок', () {
      final s = PairsSession(PairsSet.all[2], random: Random(3));
      // Две карты разных символов.
      final a = 0;
      final b = s.cards.indexWhere((c) => c.symbol != s.cards[a].symbol);
      s.flip(a);
      final r = s.flip(b);
      expect(r.outcome, FlipOutcome.mismatch);
      expect(s.mismatches, 1);
      // Пока заблокировано — новый тап игнорируется.
      expect(s.flip(b == 0 ? 1 : 0).outcome, FlipOutcome.ignored);
      s.resolveMismatch(a, b);
      expect(s.cards[a].faceUp, isFalse);
      expect(s.cards[b].faceUp, isFalse);
      // Блок снят — снова можно играть.
      expect(s.flip(a).outcome, FlipOutcome.firstUp);
    });

    test('тап по уже открытой/совпавшей игнорируется', () {
      final s = PairsSession(PairsSet.all[0], random: Random(1));
      s.flip(0);
      expect(s.flip(0).outcome, FlipOutcome.ignored);
    });

    test('сбор всех пар → isComplete и allMatched на последней', () {
      final s = PairsSession(PairsSet.all[1], random: Random(5));
      FlipResult? last;
      for (var sym = 0; sym < PairsSet.all[1].pairs; sym++) {
        final pair = indicesOf(s, sym);
        s.flip(pair[0]);
        last = s.flip(pair[1]);
      }
      expect(s.isComplete, isTrue);
      expect(last!.allMatched, isTrue);
      expect(s.mismatches, 0);
    });
  });
}
