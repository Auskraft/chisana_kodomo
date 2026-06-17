import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chisana_kodomo/core/storage/game_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameStorage.debugReset();
    await GameStorage.init();
  });

  group('GameStorage', () {
    test('дефолты: согласия нет, звук/голос/вибро вкл, тема daylight', () {
      final s = GameStorage.instance;
      expect(s.consentAccepted, isFalse);
      expect(s.soundOn, isTrue);
      expect(s.voiceOn, isTrue);
      expect(s.hapticsOn, isTrue);
      expect(s.themeId, 'daylight');
    });

    test('согласие и настройки сохраняются', () async {
      final s = GameStorage.instance;
      await s.acceptConsent();
      await s.setSoundOn(false);
      await s.setThemeId('meadow');
      expect(s.consentAccepted, isTrue);
      expect(s.soundOn, isFalse);
      expect(s.themeId, 'meadow');
    });

    test('открытые наборы: минимум 1, растут только вверх', () async {
      final s = GameStorage.instance;
      expect(s.unlockedSets('counting'), 1);
      await s.unlockSets('counting', 3);
      expect(s.unlockedSets('counting'), 3);
      await s.unlockSets('counting', 2); // не откатываемся
      expect(s.unlockedSets('counting'), 3);
    });

    test('звёзды за набор: храним максимум, сумма по наборам', () async {
      final s = GameStorage.instance;
      expect(s.setStars('counting', 0), 0);
      expect(await s.recordSetStars('counting', 0, 2), isTrue);
      expect(await s.recordSetStars('counting', 0, 1), isFalse); // меньше — игнор
      expect(s.setStars('counting', 0), 2);
      await s.recordSetStars('counting', 1, 3);
      expect(s.totalStars('counting', 5), 5);
    });

    test('звёзды клампятся в 0..3', () async {
      final s = GameStorage.instance;
      await s.recordSetStars('counting', 0, 9);
      expect(s.setStars('counting', 0), 3);
    });

    test('избранные раскраски: переключение и персист', () async {
      final s = GameStorage.instance;
      const a = 'assets/coloring/animals/1/cat.png';
      const b = 'assets/coloring/animals/2/giraffe.png';
      expect(s.coloringFavorites, isEmpty);
      expect(s.isColoringFavorite(a), isFalse);
      expect(await s.toggleColoringFavorite(a), isTrue); // добавили
      expect(s.isColoringFavorite(a), isTrue);
      await s.toggleColoringFavorite(b);
      expect(s.coloringFavorites, containsAll(<String>[a, b]));
      expect(await s.toggleColoringFavorite(a), isFalse); // убрали
      expect(s.isColoringFavorite(a), isFalse);
      expect(s.coloringFavorites, <String>[b]);
    });
  });
}
