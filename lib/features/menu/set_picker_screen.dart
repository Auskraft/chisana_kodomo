import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/feedback/haptics.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';

/// Одна вкладка выбора уровня: своя «колода» и свой прогресс (отдельный
/// [gameId] в хранилище). Напр. «Иконки» (`pairs`) и «Животные» (`pairs_animals`).
class SetPickerTab {
  const SetPickerTab({
    required this.label,
    required this.gameId,
    required this.setCount,
    required this.buildGame,
    this.starsPerSet = 3,
  });

  /// Подпись на табе.
  final String label;

  /// id для прогресса в `GameStorage` (открытые уровни + звёзды).
  final String gameId;

  final int setCount;
  final int starsPerSet;

  /// Построить экран игры для уровня [index].
  final Widget Function(int index) buildGame;
}

/// Выбор уровня для игр со звёздами. Если вкладок больше одной (напр.
/// Иконки/Животные) — показывает табы; каждая вкладка ведёт **свой** прогресс.
/// «Без проигрышей»: первый уровень открыт, новые открываются по прохождению.
class SetPickerScreen extends StatelessWidget {
  const SetPickerScreen({super.key, required this.title, required this.tabs})
      : assert(tabs.length > 0);

  final String title;
  final List<SetPickerTab> tabs;

  @override
  Widget build(BuildContext context) {
    if (tabs.length == 1) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(child: _LevelGrid(tab: tabs.first)),
      );
    }
    final colors = context.appColors;
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: TabBar(
            labelColor: colors.primary,
            unselectedLabelColor: colors.onBackground.withValues(alpha: 0.5),
            indicatorColor: colors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: <Widget>[for (final t in tabs) Tab(text: t.label)],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: <Widget>[for (final t in tabs) _LevelGrid(tab: t)],
          ),
        ),
      ),
    );
  }
}

/// Сетка уровней одной вкладки.
class _LevelGrid extends StatefulWidget {
  const _LevelGrid({required this.tab});

  final SetPickerTab tab;

  @override
  State<_LevelGrid> createState() => _LevelGridState();
}

class _LevelGridState extends State<_LevelGrid> {
  final GameStorage _s = GameStorage.instance;

  Future<void> _openSet(int index) async {
    Haptics.select();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => widget.tab.buildGame(index)),
    );
    // Вернулись — звёзды/открытые уровни могли измениться.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tab = widget.tab;
    final unlocked = _s.unlockedSets(tab.gameId);

    return LayoutBuilder(
      builder: (context, c) {
        final pad = (c.maxWidth * 0.05).clamp(12.0, 28.0).toDouble();
        const cols = 5;
        final gap = pad * 0.5;
        final tile = (c.maxWidth - pad * 2 - gap * (cols - 1)) / cols;
        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: pad, left: 4),
                child: Text(
                  'Выбери уровень',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onBackground.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <Widget>[
                  for (var i = 0; i < tab.setCount; i++)
                    _SetCard(
                      number: i + 1,
                      size: tile,
                      colors: colors,
                      locked: i >= unlocked,
                      stars: _s.setStars(tab.gameId, i),
                      starsPerSet: tab.starsPerSet,
                      onTap: i >= unlocked ? null : () => _openSet(i),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.number,
    required this.size,
    required this.colors,
    required this.locked,
    required this.stars,
    required this.starsPerSet,
    required this.onTap,
  });

  final int number;
  final double size;
  final AppColors colors;
  final bool locked;
  final int stars;
  final int starsPerSet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.16);
    final card = Container(
      width: size,
      height: size * 0.74,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.onBackground.withValues(alpha: 0.1),
            blurRadius: size * 0.06,
            offset: Offset(0, size * 0.025),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (locked)
            Icon(Icons.lock_rounded,
                size: size * 0.26, color: colors.onSurface.withValues(alpha: 0.3))
          else ...<Widget>[
            Text(
              '$number',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                color: colors.primary,
              ),
            ),
            SizedBox(height: size * 0.03),
            StarRow(filled: stars, total: starsPerSet, size: size * 0.13),
          ],
        ],
      ),
    );

    if (locked) return Opacity(opacity: 0.6, child: card);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: card),
    );
  }
}
