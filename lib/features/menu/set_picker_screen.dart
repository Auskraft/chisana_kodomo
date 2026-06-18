import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/feedback/haptics.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';

/// Универсальный выбор набора для игр со звёздами. Открытые наборы доступны,
/// будущие — притушены с замком («без проигрышей»: первый всегда открыт, новые
/// открываются по мере прохождения). Звёзды за набор показаны на карточке.
class SetPickerScreen extends StatefulWidget {
  const SetPickerScreen({
    super.key,
    required this.gameId,
    required this.title,
    required this.setCount,
    required this.buildGame,
    this.starsPerSet = 3,
  });

  final String gameId;
  final String title;
  final int setCount;

  /// Сколько звёзд даёт набор (кружки на карточке; у «Пазлов» — 1).
  final int starsPerSet;

  /// Построить экран игры для набора [index].
  final Widget Function(int index) buildGame;

  @override
  State<SetPickerScreen> createState() => _SetPickerScreenState();
}

class _SetPickerScreenState extends State<SetPickerScreen> {
  final GameStorage _s = GameStorage.instance;

  Future<void> _openSet(int index) async {
    Haptics.select();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => widget.buildGame(index)),
    );
    // Вернулись — звёзды/открытые наборы могли измениться.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final unlocked = _s.unlockedSets(widget.gameId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final pad = (c.maxWidth * 0.05).clamp(12.0, 28.0).toDouble();
            const cols = 2;
            final gap = pad;
            final tile = (c.maxWidth - pad * 2 - gap * (cols - 1)) / cols;
            return SingleChildScrollView(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: pad, left: 4),
                    child: Text(
                      'Выбери набор',
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
                      for (var i = 0; i < widget.setCount; i++)
                        _SetCard(
                          number: i + 1,
                          size: tile,
                          colors: colors,
                          locked: i >= unlocked,
                          stars: _s.setStars(widget.gameId, i),
                          starsPerSet: widget.starsPerSet,
                          onTap: i >= unlocked ? null : () => _openSet(i),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
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
        color: colors.surface,
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
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
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
