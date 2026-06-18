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
    this.starsPerSet = 3,
  });

  final String id;
  final String title;
  final String emoji;

  /// Сколько наборов в игре (берётся из её `*Set.all.length`).
  final int setCount;

  /// Сколько звёзд даёт один набор (обычно 3; у «Пазлов» — 1 за уровень).
  final int starsPerSet;

  /// Максимум звёзд в игре.
  int get maxStars => setCount * starsPerSet;
}

/// Реестр игр со звёздами. Число наборов берём прямо из логики игр — не дублируем
/// (если поменяется кривая наборов, реестр обновится сам).
abstract final class RewardsCatalog {
  static final List<StarGame> games = <StarGame>[
    StarGame(id: 'counting', title: 'Счёт', emoji: '🔢', setCount: CountSet.all.length),
    StarGame(id: 'pairs', title: 'Парочки', emoji: '🃏', setCount: PairsSet.all.length, starsPerSet: 1),
    StarGame(id: 'colors_shapes', title: 'Угадай-ка', emoji: '🎨', setCount: CSSet.all.length),
    StarGame(id: 'animals', title: 'Звуки', emoji: '🐶', setCount: AnimalSet.all.length),
    StarGame(id: 'odd_one_out', title: 'Лишнее', emoji: '🔎', setCount: OddSet.all.length),
    StarGame(id: 'farm', title: 'Ферма', emoji: '🐮', setCount: AnimalSet.all.length),
    StarGame(id: 'puzzles', title: 'Пазлы', emoji: '🧩', setCount: PuzzleSet.all.length, starsPerSet: 1),
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
    Sticker('🌟', 150),
    Sticker('🎯', 165),
    Sticker('🦁', 180),
    Sticker('🐉', 195),
    Sticker('🚂', 210),
    Sticker('🏰', 225),
    Sticker('🎪', 240),
    Sticker('🦕', 255),
    Sticker('🛸', 270),
    Sticker('🎢', 285),
    Sticker('🌍', 300),
    Sticker('🏵️', 315),
  ];

  /// Открыта ли наклейка при [totalStars] звёздах.
  static bool isEarned(Sticker s, int totalStars) => totalStars >= s.starsNeeded;

  /// Сколько наклеек открыто при [totalStars] звёздах.
  static int earnedCount(int totalStars) =>
      all.where((Sticker s) => isEarned(s, totalStars)).length;
}
