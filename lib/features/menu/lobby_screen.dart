import 'package:flutter/material.dart';

import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../animals/animals_game_screen.dart';
import '../animals/logic/animals_logic.dart';
import '../colors_shapes/colors_shapes_game_screen.dart';
import '../colors_shapes/logic/colors_shapes_logic.dart';
import '../counting/counting_game_screen.dart';
import '../counting/logic/counting_logic.dart';
import '../pairs/logic/pairs_logic.dart';
import '../pairs/pairs_game_screen.dart';
import '../settings/settings_screen.dart';

/// Кол-во фоновых сцен (`assets/backgrounds/1..N.png`). Переключаются в Настройках.
const int kBackgroundCount = 9;

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
        image: 'assets/games/count_main.png', playable: true),
    _Game('pairs', 'Парочки', '🃏', playable: true),
    _Game('colors_shapes', 'Цвета и формы', '🎨',
        image: 'assets/games/form-main.png', playable: true),
    _Game('animals', 'Звуки животных', '🐶', playable: true),
    _Game('music', 'Музыка', '🎹', image: 'assets/games/music-main.png'),
    _Game('coloring', 'Раскраска', '🖍️'),
  ];

  late int _bg = GameStorage.instance.backgroundIndex.clamp(0, kBackgroundCount - 1);

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    // Вернулись из настроек — фон мог поменяться.
    if (mounted) {
      setState(() => _bg =
          GameStorage.instance.backgroundIndex.clamp(0, kBackgroundCount - 1));
    }
  }

  void _open(_Game g) {
    switch (g.id) {
      case 'counting':
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => CountingGameScreen(set: CountSet.all.first),
        ));
      case 'colors_shapes':
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ColorsShapesGameScreen(set: CSSet.all.first),
        ));
      case 'pairs':
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PairsGameScreen(set: PairsSet.all.first),
        ));
      case 'animals':
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AnimalsGameScreen(set: AnimalSet.all.first),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Выбранный фон.
          Image.asset(
            'assets/backgrounds/${_bg + 1}.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(color: colors.background),
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
                final tile = (w - pad * 2 - gap * (cols - 1)) / cols;

                return Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 4, pad, 0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _RoundIconButton(
                          icon: Icons.settings_rounded,
                          colors: colors,
                          onTap: _openSettings,
                        ),
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
                    Text(
                      _tagline,
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, gap * 1.5),
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
                              onTap: () => _open(g),
                            ),
                        ],
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
        maxLines: 1,
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
              Image.asset(
                game.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(game.emoji, style: TextStyle(fontSize: size * 0.34)),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: colors.surface.withValues(alpha: 0.9),
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
          color: colors.surface.withValues(alpha: 0.92),
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

/// Круглая кнопка (шестерёнка) поверх фона.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: colors.onSurface.withValues(alpha: 0.7), size: 22),
        ),
      ),
    );
  }
}
