import '../../animals/logic/animals_logic.dart';
import '../../colors_shapes/logic/colors_shapes_logic.dart';
import '../../counting/logic/counting_logic.dart';
import '../../odd_one_out/logic/odd_one_out_logic.dart';
import '../../pairs/logic/pairs_logic.dart';
import '../../puzzles/logic/puzzles_logic.dart';

/// Игра, в которой копятся звёзды (наборы со звёздами). Игры-«игрушки» (Музыка,
/// Раскраска) сюда не входят — у них нет наборов/звёзд.
class StarGame {
  const StarGame({
    required this.id,
    required this.title,
    required this.emoji,
    required this.setCount,
  });

  final String id;
  final String title;
  final String emoji;

  /// Сколько наборов в игре (берётся из её `*Set.all.length`).
  final int setCount;

  /// Максимум звёзд в игре (3 за набор).
  int get maxStars => setCount * 3;
}

/// Реестр игр со звёздами. Число наборов берём прямо из логики игр — не дублируем
/// (если поменяется кривая наборов, реестр обновится сам).
abstract final class RewardsCatalog {
  static final List<StarGame> games = <StarGame>[
    StarGame(id: 'counting', title: 'Счёт', emoji: '🔢', setCount: CountSet.all.length),
    StarGame(id: 'pairs', title: 'Парочки', emoji: '🃏', setCount: PairsSet.all.length),
    StarGame(id: 'colors_shapes', title: 'Цвета и формы', emoji: '🎨', setCount: CSSet.all.length),
    StarGame(id: 'animals', title: 'Звуки животных', emoji: '🐶', setCount: AnimalSet.all.length),
    StarGame(id: 'odd_one_out', title: 'Что лишнее?', emoji: '🔎', setCount: OddSet.all.length),
    StarGame(id: 'farm', title: 'Ферма', emoji: '🐮', setCount: AnimalSet.all.length),
    StarGame(id: 'puzzles', title: 'Пазлы', emoji: '🧩', setCount: PuzzleSet.all.length),
  ];

  /// Максимум звёзд по всем играм.
  static int get maxStars =>
      games.fold(0, (int sum, StarGame g) => sum + g.maxStars);
}

/// Наклейка-награда: открывается по достижению порога суммарных звёзд.
class Sticker {
  const Sticker(this.emoji, this.starsNeeded);

  final String emoji;
  final int starsNeeded;
}

/// Коллекция наклеек (графика = эмодзи, как и везде). Пороги растут плавно;
/// последняя — за все звёзды. «Без проигрышей»: наклейки только копятся.
abstract final class Stickers {
  static const List<Sticker> all = <Sticker>[
    Sticker('🌱', 1),
    Sticker('🌸', 3),
    Sticker('🦋', 6),
    Sticker('🐤', 10),
    Sticker('⭐', 15),
    Sticker('🌈', 21),
    Sticker('🚀', 28),
    Sticker('🎈', 36),
    Sticker('🍰', 45),
    Sticker('🧁', 54),
    Sticker('🎁', 63),
    Sticker('🐢', 72),
    Sticker('🐬', 81),
    Sticker('🦄', 90),
    Sticker('🏅', 100),
    Sticker('🎖️', 110),
    Sticker('🏆', 120),
    Sticker('👑', 130),
    Sticker('💎', 138),
  ];

  /// Открыта ли наклейка при [totalStars] звёздах.
  static bool isEarned(Sticker s, int totalStars) => totalStars >= s.starsNeeded;

  /// Сколько наклеек открыто при [totalStars] звёздах.
  static int earnedCount(int totalStars) =>
      all.where((Sticker s) => isEarned(s, totalStars)).length;
}
