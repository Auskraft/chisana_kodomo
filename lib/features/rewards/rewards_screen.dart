import 'package:flutter/material.dart';

import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import 'logic/rewards_logic.dart';

/// Экран наград: суммарные звёзды, коллекция наклеек (открываются по звёздам) и
/// разбивка по играм. Только показывает прогресс — без давления.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final s = GameStorage.instance;

    final total = RewardsCatalog.games
        .fold<int>(0, (int sum, StarGame g) => sum + s.totalStars(g.id, g.setCount));
    final maxStars = RewardsCatalog.maxStars;

    return Scaffold(
      appBar: AppBar(title: const Text('Награды')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Суммарные звёзды.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.onBackground.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Icon(Icons.star_rounded, color: colors.accent, size: 64),
                const SizedBox(height: 6),
                Text(
                  '$total / $maxStars',
                  style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'звёздочек собрано',
                  style: text.titleMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Наклейки',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              for (final sticker in Stickers.all)
                _StickerTile(
                  sticker: sticker,
                  earned: Stickers.isEarned(sticker, total),
                  colors: colors,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Звёзды по играм',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final g in RewardsCatalog.games)
            ListTile(
              leading: Text(g.emoji, style: const TextStyle(fontSize: 30)),
              title: Text(g.title),
              trailing: Text(
                '${s.totalStars(g.id, g.setCount)} / ${g.maxStars}',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({
    required this.sticker,
    required this.earned,
    required this.colors,
  });

  final Sticker sticker;
  final bool earned;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: earned
            ? colors.accent.withValues(alpha: 0.18)
            : colors.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: earned ? colors.accent : colors.onSurface.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Opacity(
            opacity: earned ? 1 : 0.35,
            child: Text(
              earned ? sticker.emoji : '🔒',
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '⭐${sticker.starsNeeded}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
