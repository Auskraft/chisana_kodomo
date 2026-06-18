import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Переиспользуемые элементы оверлеев игр: тёплые, крупные, **адаптивные**
/// (размеры — доли от экрана) и в цветах активной темы (`context.appColors`).
///
/// «Без проигрышей»: вместо Game Over — [PraisePanel] с похвалой и звёздами.

double _unit(BuildContext c) => MediaQuery.sizeOf(c).shortestSide;

double _frac(BuildContext c, double f, double lo, double hi) =>
    (_unit(c) * f).clamp(lo, hi).toDouble();

/// Тёплая полупрозрачная подложка поверх игры; по центру — карточка-контент.
class GameScrim extends StatelessWidget {
  const GameScrim({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      color: colors.onBackground.withValues(alpha: 0.42),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(_frac(context, 0.06, 16, 48)),
        child: _PanelCard(child: child),
      ),
    );
  }
}

/// Белая скруглённая карточка под содержимое панели.
class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: EdgeInsets.all(_frac(context, 0.07, 20, 40)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_frac(context, 0.06, 20, 36)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.onBackground.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Крупная скруглённая кнопка действия (можно с эмодзи прямо в [label]).
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 4,
        padding: EdgeInsets.symmetric(
          horizontal: _frac(context, 0.08, 28, 56),
          vertical: _frac(context, 0.035, 14, 22),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        textStyle: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      child: Text(label),
    );
  }
}

/// Мягкая второстепенная кнопка-ссылка (заново / выйти).
class SoftTextButton extends StatelessWidget {
  const SoftTextButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Ряд из [total] звёзд, [filled] из которых заполнены (награда за набор).
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.filled, this.total = 3, this.size});
  final int filled;
  final int total;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final s = size ?? _frac(context, 0.12, 36, 72);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < total; i++)
          Icon(
            i < filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: s,
            color: i < filled
                ? colors.accent
                : colors.onSurface.withValues(alpha: 0.22),
          ),
      ],
    );
  }
}

/// Компактный чип статистики для HUD (набор / звёзды).
class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.onBackground.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color ?? colors.onSurface,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

/// Круглая кнопка паузы для HUD.
class PauseButton extends StatelessWidget {
  const PauseButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset('assets/ui/pause.png', width: 44, height: 44),
    );
  }
}

/// Стартовая панель: эмодзи, название, подсказка, большая кнопка «Играть».
class ReadyPanel extends StatelessWidget {
  const ReadyPanel({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onStart,
    this.startLabel = 'Играть',
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onStart;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return GameScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(emoji, style: TextStyle(fontSize: _frac(context, 0.22, 56, 110))),
          SizedBox(height: _frac(context, 0.02, 8, 20)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: _frac(context, 0.012, 4, 12)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.65),
            ),
          ),
          SizedBox(height: _frac(context, 0.035, 16, 32)),
          BigButton(label: startLabel, onTap: onStart),
        ],
      ),
    );
  }
}

/// Панель паузы: продолжить / заново / выйти.
class PausePanel extends StatelessWidget {
  const PausePanel({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return GameScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('⏸️', style: TextStyle(fontSize: _frac(context, 0.16, 44, 84))),
          SizedBox(height: _frac(context, 0.012, 4, 12)),
          Text(
            'Пауза',
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: _frac(context, 0.03, 14, 28)),
          BigButton(label: 'Продолжить', onTap: onResume),
          SoftTextButton(label: 'Заново', onTap: onRestart),
          SoftTextButton(label: 'Выйти', onTap: onExit),
        ],
      ),
    );
  }
}

/// Панель похвалы (вместо Game Over): радостный эмодзи, фраза, звёзды и
/// кнопки «дальше / ещё разок / выйти».
class PraisePanel extends StatelessWidget {
  const PraisePanel({
    super.key,
    required this.title,
    required this.stars,
    required this.onNext,
    required this.onAgain,
    required this.onExit,
    this.emoji = '🌟',
    this.nextLabel = 'Дальше',
  });

  final String title;
  final int stars;
  final VoidCallback onNext;
  final VoidCallback onAgain;
  final VoidCallback onExit;
  final String emoji;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return GameScrim(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(emoji, style: TextStyle(fontSize: _frac(context, 0.2, 52, 100))),
          SizedBox(height: _frac(context, 0.015, 6, 16)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
          SizedBox(height: _frac(context, 0.02, 10, 22)),
          StarRow(filled: stars),
          SizedBox(height: _frac(context, 0.035, 16, 32)),
          BigButton(label: nextLabel, onTap: onNext),
          SoftTextButton(label: 'Ещё разок', onTap: onAgain),
          SoftTextButton(label: 'Выйти', onTap: onExit),
        ],
      ),
    );
  }
}
