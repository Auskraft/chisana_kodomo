import 'package:flutter/material.dart';

import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../animals/animals_game_screen.dart';
import '../animals/logic/animals_logic.dart';
import '../coloring/coloring_game_screen.dart';
import '../colors_shapes/colors_shapes_game_screen.dart';
import '../colors_shapes/logic/colors_shapes_logic.dart';
import '../counting/counting_game_screen.dart';
import '../counting/logic/counting_logic.dart';
import '../farm/farm_game_screen.dart';
import '../music/music_game_screen.dart';
import '../odd_one_out/logic/odd_one_out_logic.dart';
import '../odd_one_out/odd_one_out_game_screen.dart';
import '../pairs/logic/pairs_logic.dart';
import '../pairs/pairs_game_screen.dart';
import '../puzzles/logic/puzzles_logic.dart';
import '../puzzles/puzzles_game_screen.dart';
import '../rewards/logic/rewards_logic.dart';
import '../rewards/rewards_screen.dart';
import '../settings/settings_screen.dart';
import 'set_picker_screen.dart';

/// Кол-во фоновых сцен (`assets/backgrounds/1..N.png`). Переключаются в Настройках.
const int kBackgroundCount = 9;

/// Насколько приподнять фон (масштаб с якорем по низу): сюжет/маскот уходит в
/// свободное место над карточками, края не оголяются. 1.0 = как есть; больше =
/// выше и чуть крупнее. Подбирается на глаз (на высоких экранах cover режет
/// бока, а не верх/низ, поэтому одним `alignment` фон не поднять).
const double _kBgRaiseScale = 1.15;

/// Главный экран: иллюстрированный фон (выбирается в Настройках) + витрина игр.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  static const String _tagline = 'Играем, учимся, растём!';

  static const List<_Game> _games = <_Game>[
    _Game('counting', 'Счёт', '🔢',
        image: 'assets/games/counting.png', playable: true),
    _Game('pairs', 'Парочки', '🃏',
        image: 'assets/games/pairs.png', playable: true),
    _Game('colors_shapes', 'Угадай-ка', '🎨',
        image: 'assets/games/colors_shapes.png', playable: true),
    _Game('animals', 'Звуки', '🐶',
        image: 'assets/games/animals.png', playable: true),
    _Game('music', 'Музыка', '🎹',
        image: 'assets/games/music.png', playable: true),
    _Game('coloring', 'Раскраска', '🖍️',
        image: 'assets/games/coloring.png', playable: true),
    _Game('farm', 'Ферма', '🐮',
        image: 'assets/games/farm.png', playable: true),
    _Game('odd_one_out', 'Лишнее', '🔎',
        image: 'assets/games/odd_one_out.png', playable: true),
    _Game('puzzles', 'Пазлы', '🧩',
        image: 'assets/games/puzzles.png', playable: true),
  ];

  late int _bg = GameStorage.instance.backgroundIndex.clamp(0, kBackgroundCount - 1);
  late int _stars = _computeStars();

  int _computeStars() {
    final s = GameStorage.instance;
    return RewardsCatalog.games
        .fold<int>(0, (int a, StarGame g) => a + s.totalStars(g.id, g.setCount));
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    // Вернулись из настроек — фон мог поменяться, прогресс мог сброситься.
    if (mounted) {
      setState(() {
        _bg = GameStorage.instance.backgroundIndex.clamp(0, kBackgroundCount - 1);
        _stars = _computeStars();
      });
    }
  }

  Future<void> _openRewards() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RewardsScreen()),
    );
    if (mounted) setState(() => _stars = _computeStars());
  }

  /// Открыть игру. Игры со звёздами идут через выбор набора; игрушки — напрямую.
  Future<void> _openGame(_Game g) async {
    switch (g.id) {
      case 'counting':
        await _openSets(g, CountSet.all.length,
            (int i) => CountingGameScreen(set: CountSet.all[i]));
      case 'pairs':
        await _openSets(g, PairsSet.all.length,
            (int i) => PairsGameScreen(set: PairsSet.all[i]));
      case 'colors_shapes':
        await _openSets(g, CSSet.all.length,
            (int i) => ColorsShapesGameScreen(set: CSSet.all[i]));
      case 'animals':
        await _openSets(g, AnimalSet.all.length,
            (int i) => AnimalsGameScreen(set: AnimalSet.all[i]));
      case 'music':
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const MusicGameScreen(),
        ));
      case 'coloring':
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const ColoringGameScreen(),
        ));
      case 'farm':
        await _openSets(g, AnimalSet.all.length,
            (int i) => FarmGameScreen(set: AnimalSet.all[i]));
      case 'odd_one_out':
        await _openSets(g, OddSet.all.length,
            (int i) => OddOneOutGameScreen(set: OddSet.all[i]));
      case 'puzzles':
        await _openSets(g, PuzzleSet.all.length,
            (int i) => PuzzlesGameScreen(set: PuzzleSet.all[i]),
            starsPerSet: 1);
    }
    if (mounted) setState(() => _stars = _computeStars());
  }

  Future<void> _openSets(_Game g, int setCount, Widget Function(int) build,
      {int starsPerSet = 3}) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SetPickerScreen(
        gameId: g.id,
        title: g.title,
        setCount: setCount,
        buildGame: build,
        starsPerSet: starsPerSet,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Выбранный фон, слегка приподнят (маскот/сюжет — в свободном месте над
          // карточками). Якорь по низу: поднимает и чуть увеличивает, края целы.
          Transform.scale(
            scale: _kBgRaiseScale,
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/backgrounds/${_bg + 1}.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(color: colors.background),
            ),
          ),
          // Лёгкий скрим сверху — читаемость заголовка на любом фоне.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: <Color>[
                    colors.background.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final shortest = c.biggest.shortestSide;
                final pad = (w * 0.05).clamp(12.0, 32.0).toDouble();
                final gap = (shortest * 0.03).clamp(8.0, 18.0).toDouble();
                const cols = 3;
                // Подложка-плашка: в размере карточки учитываем и внутренний
                // отступ, и рамку плашки (+запас на округление) — иначе сетка
                // переносится из 3×3 в 2 колонки.
                final trayPad = gap;
                const trayBorder = 2.0; // фактически 1.5 + запас
                final tile = (w -
                        pad * 2 -
                        trayPad * 2 -
                        trayBorder * 2 -
                        gap * (cols - 1)) /
                    cols;

                return Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 4, pad, 0),
                      child: Row(
                        children: <Widget>[
                          _StarsPill(
                            stars: _stars,
                            colors: colors,
                            onTap: _openRewards,
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _openSettings,
                            child: Image.asset(
                              'assets/ui/settings.png',
                              width: 48,
                              height: 48,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Chisana\nkodomo',
                      textAlign: TextAlign.center,
                      style: text.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: colors.onBackground,
                      ),
                    ),
                    SizedBox(height: shortest * 0.012),
                    Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        // Белая обводка ~3px — слоган читается на любом фоне.
                        Text(
                          _tagline,
                          textAlign: TextAlign.center,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..strokeJoin = StrokeJoin.round
                              ..color = colors.surface,
                          ),
                        ),
                        Text(
                          _tagline,
                          textAlign: TextAlign.center,
                          style: text.titleMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, gap * 1.4),
                      child: Container(
                        padding: EdgeInsets.all(trayPad),
                        decoration: BoxDecoration(
                          // Тёплая кремово-песочная плашка: фон + золотистый accent
                          // (а не к коричневому — тот обесцвечивает в серость).
                          // Цвета из темы → реколорятся со сменой темы.
                          color: Color.lerp(
                              colors.background, colors.accent, 0.25),
                          borderRadius: BorderRadius.circular(tile * 0.34),
                          border: Border.all(
                            color: Color.lerp(
                                colors.background, colors.accent, 0.5)!,
                            width: 1.5,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: colors.onBackground.withValues(alpha: 0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          alignment: WrapAlignment.center,
                          children: <Widget>[
                            for (final _Game g in _games)
                              _GameCard(
                                game: g,
                                size: tile,
                                colors: colors,
                                onTap: () => _openGame(g),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Запись об игре в витрине.
class _Game {
  const _Game(this.id, this.title, this.emoji, {this.image, this.playable = false});

  final String id;
  final String title;
  final String emoji;
  final String? image;
  final bool playable;
}

/// Карточка игры. С иконкой-иллюстрацией картинка **заполняет** карточку (её фон
/// = фон карточки, без «коробки»), подпись — полоской снизу. С эмодзи —
/// кремовая карточка с эмодзи по центру.
class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.size,
    required this.colors,
    required this.onTap,
  });

  final _Game game;
  final double size;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.24);
    final label = Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.08),
      child: Text(
        game.title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
      ),
    );

    final Widget inner = game.image != null
        ? Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Padding(
                // Иконка ~60% карточки (отступ 20% с каждой стороны).
                // Подпись — отдельный слой Stack, остаётся на месте.
                padding: EdgeInsets.all(size * 0.2),
                child: Image.asset(
                  game.image!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(game.emoji,
                        style: TextStyle(fontSize: size * 0.34)),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: colors.surface.withValues(alpha: 0.1),
                  padding: EdgeInsets.symmetric(vertical: size * 0.05),
                  child: label,
                ),
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(game.emoji, style: TextStyle(fontSize: size * 0.34)),
              SizedBox(height: size * 0.05),
              label,
            ],
          );

    final card = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Карточка — в цвет кремового фона иконок (фон+accent ≈ #FCEDCA),
          // чтобы вокруг ужатой иконки не было белого канта. Цвет из темы.
          color: Color.lerp(colors.background, colors.accent, 0.17),
          borderRadius: radius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.12),
              blurRadius: size * 0.1,
              offset: Offset(0, size * 0.05),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: radius, child: inner),
      ),
    );

    if (!game.playable) {
      return Opacity(opacity: 0.55, child: card);
    }
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: card),
    );
  }
}

/// Пилюля со звёздами (поверх фона) — открывает экран наград.
class _StarsPill extends StatelessWidget {
  const _StarsPill({required this.stars, required this.colors, required this.onTap});

  final int stars;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.star_rounded, color: colors.accent, size: 22),
              const SizedBox(width: 5),
              Text(
                '$stars',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

