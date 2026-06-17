import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/coloring/logic/coloring_logic.dart';

/// Тестовая картинка из 3 областей с целевыми цветами 0,1,2.
ColoringPicture _pic() => const ColoringPicture(
      name: 'тест',
      regions: <ColorRegion>[
        ColorRegion(id: 0, targetColor: 0),
        ColorRegion(id: 1, targetColor: 1),
        ColorRegion(id: 2, targetColor: 2),
      ],
    );

void main() {
  group('режим заливки (свободно)', () {
    test('любой цвет применяется; полнота при всех закрашенных', () {
      final s = ColoringState(_pic(), mode: ColoringMode.fill);
      expect(s.isComplete, isFalse);
      expect(s.fill(0, 5).applied, isTrue);
      expect(s.colorOf(0), 5);
      expect(s.filledCount, 1);
      s.fill(1, 3);
      final last = s.fill(2, 0);
      expect(last.complete, isTrue);
      expect(s.isComplete, isTrue);
      expect(s.progress, 1.0);
    });

    test('перекраска области меняет цвет, не увеличивая счётчик', () {
      final s = ColoringState(_pic(), mode: ColoringMode.fill);
      s.fill(0, 1);
      s.fill(0, 4);
      expect(s.colorOf(0), 4);
      expect(s.filledCount, 1);
    });
  });

  group('режим «по номерам»', () {
    test('неверный цвет мягко не применяется', () {
      final s = ColoringState(_pic(), mode: ColoringMode.byNumber);
      final r = s.fill(0, 2); // цель области 0 — цвет 0
      expect(r.applied, isFalse);
      expect(r.correct, isFalse);
      expect(s.colorOf(0), isNull);
      expect(s.filledCount, 0);
    });

    test('верный цвет применяется; полнота только при всех верных', () {
      final s = ColoringState(_pic(), mode: ColoringMode.byNumber);
      expect(s.fill(0, 0).applied, isTrue);
      expect(s.fill(1, 1).applied, isTrue);
      expect(s.isComplete, isFalse);
      final last = s.fill(2, 2);
      expect(last.complete, isTrue);
      expect(s.isComplete, isTrue);
    });
  });

  test('clear сбрасывает заливки', () {
    final s = ColoringState(_pic(), mode: ColoringMode.fill);
    s.fill(0, 1);
    s.fill(1, 2);
    s.clear();
    expect(s.filledCount, 0);
    expect(s.colorOf(0), isNull);
    expect(s.isComplete, isFalse);
  });

  test('progress = доля закрашенных', () {
    final s = ColoringState(_pic(), mode: ColoringMode.fill);
    s.fill(0, 0);
    expect(s.progress, closeTo(1 / 3, 1e-9));
  });
}
