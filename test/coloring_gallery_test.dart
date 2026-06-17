import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/features/coloring/game/coloring_pictures.dart';

void main() {
  group('parseColoringAsset', () {
    test('валидный путь <тема>/<уровень>/<файл> разбирается', () {
      final r = parseColoringAsset('assets/coloring/animals/2/giraffe.png');
      expect(r, isNotNull);
      expect(r!.category, 'animals');
      expect(r.level, 2);
    });

    test('jpg/jpeg и верхний регистр расширения принимаются', () {
      expect(parseColoringAsset('assets/coloring/cars/1/x.jpg')?.level, 1);
      expect(
          parseColoringAsset('assets/coloring/cars/3/x.JPEG')?.category, 'cars');
      expect(parseColoringAsset('assets/coloring/food/5/A.PNG')?.level, 5);
    });

    test('вложенность глубже уровня всё равно даёт тему и уровень', () {
      final r = parseColoringAsset('assets/coloring/nature/4/sub/x.png');
      expect(r?.category, 'nature');
      expect(r?.level, 4);
    });

    test('не картинка / не coloring / без уровня → null', () {
      expect(parseColoringAsset('assets/coloring/animals/2/README.txt'), isNull);
      expect(parseColoringAsset('assets/coloring/README.txt'), isNull);
      expect(parseColoringAsset('assets/coloring/animals/cat.png'), isNull);
      expect(parseColoringAsset('assets/coloring/animals/easy/x.png'), isNull);
      expect(parseColoringAsset('assets/backgrounds/1.png'), isNull);
    });
  });

  group('coloringCategoryMeta', () {
    test('у каждой темы из порядка есть метаданные', () {
      for (final key in kColoringCategoryOrder) {
        expect(kColoringCategoryMeta.containsKey(key), isTrue,
            reason: 'нет метаданных для «$key» из kColoringCategoryOrder');
      }
      expect(coloringCategoryMeta('animals').label, 'Животные');
      expect(coloringCategoryMeta('cars').emoji, '🚗');
    });

    test('незнакомая тема → ключ как подпись + 🎨', () {
      final m = coloringCategoryMeta('dinosaurs');
      expect(m.label, 'dinosaurs');
      expect(m.emoji, '🎨');
    });
  });
}
