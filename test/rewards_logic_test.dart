import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/rewards/logic/rewards_logic.dart';

void main() {
  group('реестр игр со звёздами', () {
    test('6 игр, у каждой положительное число наборов', () {
      expect(RewardsCatalog.games, hasLength(6));
      for (final g in RewardsCatalog.games) {
        expect(g.setCount, greaterThan(0));
        expect(g.maxStars, g.setCount * 3);
      }
    });

    test('максимум звёзд = сумма по играм', () {
      final sum = RewardsCatalog.games.fold<int>(0, (a, g) => a + g.maxStars);
      expect(RewardsCatalog.maxStars, sum);
    });
  });

  group('наклейки', () {
    test('пороги строго возрастают, начинаются с 1', () {
      expect(Stickers.all.first.starsNeeded, 1);
      for (var i = 1; i < Stickers.all.length; i++) {
        expect(Stickers.all[i].starsNeeded,
            greaterThan(Stickers.all[i - 1].starsNeeded));
      }
    });

    test('последняя наклейка достижима (порог <= максимума звёзд)', () {
      expect(Stickers.all.last.starsNeeded,
          lessThanOrEqualTo(RewardsCatalog.maxStars));
    });

    test('earnedCount монотонен и согласован с isEarned', () {
      expect(Stickers.earnedCount(0), 0);
      expect(Stickers.earnedCount(1), 1);
      expect(Stickers.earnedCount(RewardsCatalog.maxStars), Stickers.all.length);
      var prev = 0;
      for (var stars = 0; stars <= RewardsCatalog.maxStars; stars++) {
        final c = Stickers.earnedCount(stars);
        expect(c, greaterThanOrEqualTo(prev));
        prev = c;
      }
      expect(Stickers.isEarned(Stickers.all.first, 1), isTrue);
      expect(Stickers.isEarned(Stickers.all.last, 0), isFalse);
    });
  });
}
