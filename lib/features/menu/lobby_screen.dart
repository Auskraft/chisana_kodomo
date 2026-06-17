import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../counting/counting_game_screen.dart';
import '../counting/logic/counting_logic.dart';

/// Лобби-заглушка приложения «Chisana kodomo».
///
/// Базовый скелет: тёплый дружелюбный экран с маскотом и «витриной-тизером»
/// будущих игр. Вёрстка **адаптивная** (размеры — доли от экрана, без
/// абсолютных значений), цвета берутся из активной темы через `context.appColors`,
/// поэтому экран корректно выглядит на разных телефонах и в любой из тем.
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  /// Игры: играбельные открываются по тапу, остальные — «скоро».
  static const List<_GameTeaser> _teasers = <_GameTeaser>[
    _GameTeaser('counting', '🔢', 'Счёт', playable: true),
    _GameTeaser('pairs', '🃏', 'Парочки'),
    _GameTeaser('colors_shapes', '🎨', 'Цвета и формы'),
    _GameTeaser('animals', '🐶', 'Звуки животных'),
    _GameTeaser('music', '🎹', 'Музыка'),
    _GameTeaser('coloring', '🖍️', 'Раскраска'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colors.background,
              Color.lerp(colors.background, colors.primary, 0.12)!,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final shortest = constraints.biggest.shortestSide;

              // Все размеры — доли от экрана с разумными границами (clamp),
              // чтобы хорошо смотрелось и на узких, и на крупных телефонах.
              final pad = (w * 0.06).clamp(12.0, 40.0).toDouble();
              final gap = (shortest * 0.035).clamp(8.0, 22.0).toDouble();
              final vGap = (shortest * 0.025).clamp(6.0, 22.0).toDouble();
              final mascot = (shortest * 0.34).clamp(96.0, 220.0).toDouble();
              final cols = w >= 600 ? 5 : 3;
              final innerW = w - pad * 2;
              final tile = (innerW - gap * (cols - 1)) / cols;

              return Padding(
                padding: EdgeInsets.fromLTRB(pad, vGap, pad, pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _Mascot(diameter: mascot, colors: colors),
                    SizedBox(height: vGap),
                    Text(
                      'Chisana kodomo',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onBackground,
                      ),
                    ),
                    Text(
                      'ちいさなこども',
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: vGap * 0.4),
                    Text(
                      'Развивающие игры для малышей',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: colors.onBackground.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: vGap * 1.5),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: gap,
                            runSpacing: gap,
                            children: <Widget>[
                              for (final _GameTeaser t in _teasers)
                                _TeaserCard(teaser: t, size: tile, colors: colors),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: vGap),
                    Text(
                      'Выбирай и играй! 🌟',
                      textAlign: TextAlign.center,
                      style: text.titleSmall?.copyWith(
                        color: colors.onBackground.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Маскот-заглушка (эмодзи; настоящий арт — на этапе стора).
class _Mascot extends StatelessWidget {
  const _Mascot({required this.diameter, required this.colors});

  final double diameter;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: diameter * 0.18,
            offset: Offset(0, diameter * 0.08),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text('🐻', style: TextStyle(fontSize: diameter * 0.56)),
    );
  }
}

/// Тизер игры: id, эмодзи, подпись и флаг «играбельна» (иначе — «скоро»).
class _GameTeaser {
  const _GameTeaser(this.id, this.emoji, this.title, {this.playable = false});

  final String id;
  final String emoji;
  final String title;
  final bool playable;
}

/// Карточка-тизер игры. Играбельная — тапается и ведёт в игру; остальные
/// притушены («скоро»). Размер задаётся снаружи (доля от экрана).
class _TeaserCard extends StatelessWidget {
  const _TeaserCard({
    required this.teaser,
    required this.size,
    required this.colors,
  });

  final _GameTeaser teaser;
  final double size;
  final AppColors colors;

  void _open(BuildContext context) {
    switch (teaser.id) {
      case 'counting':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CountingGameScreen(set: CountSet.all.first),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    final card = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.onBackground.withValues(alpha: 0.08),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(teaser.emoji, style: TextStyle(fontSize: size * 0.4)),
          SizedBox(height: size * 0.06),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.06),
            child: Text(
              teaser.title,
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

    if (!teaser.playable) {
      return SizedBox(
        width: size,
        height: size,
        child: Opacity(opacity: 0.5, child: card),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: () => _open(context), child: card),
      ),
    );
  }
}
