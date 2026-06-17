import 'package:flutter/material.dart';

import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../counting/counting_game_screen.dart';
import '../counting/logic/counting_logic.dart';
import '../settings/settings_screen.dart';

/// Главный экран: переключаемый иллюстрированный фон (9 сцен, свайп + точки) и
/// витрина игр поверх него. Бренд тёплый/мягкий (по дизайн-референсу).
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  static const int _bgCount = 9;
  static const String _tagline = 'Играем, учимся, растём!';

  static const List<_Game> _games = <_Game>[
    _Game('counting', 'Счёт', '🔢',
        image: 'assets/games/count_main.png', playable: true),
    _Game('pairs', 'Парочки', '🃏'),
    _Game('colors_shapes', 'Цвета и формы', '🎨',
        image: 'assets/games/form-main.png'),
    _Game('animals', 'Звуки животных', '🐶'),
    _Game('music', 'Музыка', '🎹', image: 'assets/games/music-main.png'),
    _Game('coloring', 'Раскраска', '🖍️'),
  ];

  late int _index = GameStorage.instance.backgroundIndex.clamp(0, _bgCount - 1);
  late final PageController _pager = PageController(initialPage: _index);

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _onPage(int i) {
    setState(() => _index = i);
    GameStorage.instance.setBackgroundIndex(i);
  }

  void _openSettings() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );

  void _open(_Game g) {
    if (g.id == 'counting') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CountingGameScreen(set: CountSet.all.first),
        ),
      );
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
          // Фон-карусель (свайп) — 9 сцен.
          PageView.builder(
            controller: _pager,
            itemCount: _bgCount,
            onPageChanged: _onPage,
            itemBuilder: (context, i) => Image.asset(
              'assets/backgrounds/${i + 1}.png',
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
          // UI поверх фона. Пустые зоны прозрачны — свайп доходит до фона.
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
                      padding: EdgeInsets.symmetric(horizontal: pad),
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
                    SizedBox(height: gap * 1.2),
                    _Dots(
                      count: _bgCount,
                      index: _index,
                      colors: colors,
                      onTap: (i) => _pager.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                      ),
                    ),
                    SizedBox(height: gap),
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

/// Карточка игры (мягкая кремовая, иконка-иллюстрация/эмодзи + подпись).
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
    final radius = BorderRadius.circular(size * 0.26);
    final Widget icon = game.image != null
        ? Image.asset(
            game.image!,
            width: size * 0.56,
            height: size * 0.56,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                Text(game.emoji, style: TextStyle(fontSize: size * 0.34)),
          )
        : Text(game.emoji, style: TextStyle(fontSize: size * 0.34));

    final card = Container(
      width: size,
      height: size,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          icon,
          SizedBox(height: size * 0.05),
          Padding(
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
          ),
        ],
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

/// Индикатор/переключатель фона (точки).
class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.colors,
    required this.onTap,
  });

  final int count;
  final int index;
  final AppColors colors;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < count; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == index ? 10 : 7,
                height: i == index ? 10 : 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == index
                      ? colors.primary
                      : colors.onBackground.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
