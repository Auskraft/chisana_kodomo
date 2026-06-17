import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Лобби-заглушка приложения «Chisana kodomo».
///
/// Базовый скелет: тёплый дружелюбный экран с маскотом и «витриной-тизером»
/// будущих игр. Сами игры и навигация появятся на следующих этапах — пока это
/// пустой запуск-заглушка, на которой проверяется бренд/палитра.
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  /// Планируемые мини-игры (тизер). Пока неактивны — «скоро».
  static const List<_GameTeaser> _teasers = <_GameTeaser>[
    _GameTeaser('🔢', 'Счёт'),
    _GameTeaser('🃏', 'Парочки'),
    _GameTeaser('🎨', 'Цвета и формы'),
    _GameTeaser('🐶', 'Звуки животных'),
    _GameTeaser('🎹', 'Музыка'),
  ];

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.daylight;
    final media = MediaQuery.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFFFF6EC), Color(0xFFFFE3C7)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              media.padding.top > 0 ? 12 : 24,
              24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 8),
                // Маскот-заглушка (эмодзи; настоящий арт — на этапе стора).
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('🐻', style: TextStyle(fontSize: 76)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chisana kodomo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onBackground,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ちいさなこども',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Развивающие игры для малышей',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onBackground.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        runSpacing: 14,
                        children: <Widget>[
                          for (final _GameTeaser t in _teasers)
                            _TeaserCard(teaser: t, colors: colors),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Скоро здесь появятся игры! 🌟',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onBackground.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Тизер одной будущей игры: эмодзи + подпись.
class _GameTeaser {
  const _GameTeaser(this.emoji, this.title);

  final String emoji;
  final String title;
}

/// Неактивная карточка-тизер игры.
class _TeaserCard extends StatelessWidget {
  const _TeaserCard({required this.teaser, required this.colors});

  final _GameTeaser teaser;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.onBackground.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(teaser.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              teaser.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
