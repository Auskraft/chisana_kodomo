import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chisana_kodomo/core/storage/game_storage.dart';
import 'package:chisana_kodomo/core/voice/voice.dart';

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

    test('недавние цвета пикера: новые впереди, без дублей, максимум 10', () async {
      final s = GameStorage.instance;
      expect(s.coloringRecentColors, isEmpty);

      await s.addColoringRecentColor(0xFFE53935);
      await s.addColoringRecentColor(0xFF42A5F5);
      // Новый цвет — первым.
      expect(s.coloringRecentColors, <int>[0xFF42A5F5, 0xFFE53935]);

      // Повтор — поднимается вперёд, без дубля.
      await s.addColoringRecentColor(0xFFE53935);
      expect(s.coloringRecentColors, <int>[0xFFE53935, 0xFF42A5F5]);

      // Переполнение — держим только последние kColoringRecentMax.
      for (var i = 0; i < 15; i++) {
        await s.addColoringRecentColor(0xFF000000 + i);
      }
      expect(s.coloringRecentColors, hasLength(GameStorage.kColoringRecentMax));
      // Самый свежий — впереди.
      expect(s.coloringRecentColors.first, 0xFF000000 + 14);
    });

    test('встроенный голос: дефолт baya, персист, id из реестра Voice', () async {
      final s = GameStorage.instance;
      // Дефолты.
      expect(s.voiceUsePack, isFalse);
      expect(s.voicePackId, 'baya');
      // Реестр голосов и дефолт согласованы (защита от рассинхрона с паками).
      expect(Voice.packVoices, hasLength(3));
      expect(
        Voice.packVoices.map((PackVoice v) => v.id),
        containsAll(<String>['baya', 'kseniya', 'xenia']),
      );
      expect(Voice.packVoices.map((PackVoice v) => v.id),
          contains(Voice.defaultPackVoice));
      expect(s.voicePackId, Voice.defaultPackVoice);
      // Персист.
      await s.setVoiceUsePack(true);
      await s.setVoicePackId('xenia');
      expect(s.voiceUsePack, isTrue);
      expect(s.voicePackId, 'xenia');
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
