import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/music/logic/music_logic.dart';

void main() {
  group('Xylophone.cMajor', () {
    test('8 пластин, подписи не пустые, полутоны строго растут', () {
      expect(Xylophone.cMajor, hasLength(8));
      for (final n in Xylophone.cMajor) {
        expect(n.label, isNotEmpty);
      }
      for (var i = 1; i < Xylophone.cMajor.length; i++) {
        expect(Xylophone.cMajor[i].semitone,
            greaterThan(Xylophone.cMajor[i - 1].semitone));
      }
    });

    test('диапазон ровно одна октава (0..12 полутонов)', () {
      expect(Xylophone.cMajor.first.semitone, 0);
      expect(Xylophone.cMajor.last.semitone, 12);
    });
  });

  group('частоты', () {
    test('база ≈ 261.63 Гц, октава удваивает частоту', () {
      expect(Xylophone.frequency(0), closeTo(261.63, 0.01));
      expect(Xylophone.frequency(12), closeTo(261.63 * 2, 0.01));
    });

    test('частота растёт с полутоном', () {
      for (var i = 1; i <= 12; i++) {
        expect(Xylophone.frequency(i), greaterThan(Xylophone.frequency(i - 1)));
      }
    });
  });
}
