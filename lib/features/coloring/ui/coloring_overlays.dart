import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../game/coloring_pictures.dart';
import '../logic/coloring_logic.dart';

String _modeLabel(ColoringMode m) {
  switch (m) {
    case ColoringMode.fill:
      return 'Залить';
    case ColoringMode.byNumber:
      return 'По номерам';
    case ColoringMode.freeDraw:
      return 'Рисовать';
  }
}

/// Верхняя панель: «домой» + переключатель режима + замок. При включённом
/// «детском замке» прячем всё, кроме «держи, чтобы открыть» (малыш не выйдет).
class ColoringTopBar extends StatelessWidget {
  const ColoringTopBar({
    super.key,
    required this.mode,
    required this.onMode,
    required this.onHome,
    required this.locked,
    required this.onLock,
    required this.onUnlock,
  });

  final ColoringMode mode;
  final ValueChanged<ColoringMode> onMode;
  final VoidCallback onHome;
  final bool locked;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (locked) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _HoldToUnlock(colors: colors, onUnlock: onUnlock),
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            _RoundBtn(icon: Icons.home_rounded, colors: colors, onTap: onHome),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final m in ColoringMode.values)
                      Padding(
                        // Воздух сверху/снизу: иначе горизонтальный скролл
                        // обрезает тень чипа снизу (выглядит как срез).
                        padding: const EdgeInsets.fromLTRB(3, 4, 3, 10),
                        child: _ModeChip(
                          label: _modeLabel(m),
                          selected: m == mode,
                          colors: colors,
                          onTap: () => onMode(m),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _RoundBtn(
              icon: Icons.lock_outline_rounded,
              colors: colors,
              onTap: onLock,
            ),
          ],
        ),
      ),
    );
  }
}

/// «Держи, чтобы открыть»: удержание ~1.8 с снимает детский замок (родителю
/// легко, малышу — трудно). Кольцо-прогресс рисуется вокруг замочка. Слушаем
/// сырые pointer-события (Listener), чтобы лёгкое смещение пальца не сбрасывало.
class _HoldToUnlock extends StatefulWidget {
  const _HoldToUnlock({required this.colors, required this.onUnlock});

  final AppColors colors;
  final VoidCallback onUnlock;

  @override
  State<_HoldToUnlock> createState() => _HoldToUnlockState();
}

class _HoldToUnlockState extends State<_HoldToUnlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) {
        widget.onUnlock();
        _c.reset();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Listener(
      onPointerDown: (_) => _c.forward(),
      onPointerUp: (_) => _c.reverse(),
      onPointerCancel: (_) => _c.reverse(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 26,
              height: 26,
              child: AnimatedBuilder(
                animation: _c,
                builder: (BuildContext context, Widget? child) => Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (_c.value > 0)
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          value: _c.value,
                          strokeWidth: 3,
                          color: colors.primary,
                          backgroundColor:
                              colors.onSurface.withValues(alpha: 0.12),
                        ),
                      ),
                    Icon(Icons.lock_rounded,
                        size: 16, color: colors.onSurface.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Держи, чтобы открыть',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Нижняя панель: палитра + действия (заново / следующая картинка).
class ColoringBottomBar extends StatelessWidget {
  const ColoringBottomBar({
    super.key,
    required this.mode,
    required this.selectedColor,
    required this.pickedColor,
    required this.category,
    required this.categories,
    required this.level,
    required this.availableLevels,
    required this.onColor,
    required this.onPick,
    required this.onCategory,
    required this.onLevel,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onPicture,
    required this.locked,
  });

  final ColoringMode mode;
  final int selectedColor;
  final Color? pickedColor;
  final String category;
  final List<String> categories;
  final int level;
  final List<int> availableLevels;
  final ValueChanged<int> onColor;
  final VoidCallback onPick;
  final ValueChanged<String> onCategory;
  final ValueChanged<int> onLevel;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  /// Действие кнопки «Картинка»: открыть пикер (растровые) или следующая (вектор).
  final VoidCallback onPicture;

  /// «Детский замок»: прячем навигацию/деструктив (темы/уровни/Заново/Картинка),
  /// оставляем палитру и отмену/возврат — малыш просто продолжает раскрашивать.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 14),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(26),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!locked && mode == ColoringMode.fill) ...<Widget>[
              // Лента выбора темы (показываем, если тем с картинками ≥ 2).
              if (categories.length >= 2) ...<Widget>[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final c in categories)
                      _CategoryChip(
                        categoryKey: c,
                        selected: c == category,
                        colors: colors,
                        onTap: () => onCategory(c),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Уровень сложности внутри темы (показываем, если уровней ≥ 2).
              if (availableLevels.length >= 2) ...<Widget>[
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'Уровень',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    for (var l = 1; l <= 5; l++)
                      _LevelChip(
                        n: l,
                        selected: l == level,
                        enabled: availableLevels.contains(l),
                        colors: colors,
                        onTap: () => onLevel(l),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
            Wrap(
              spacing: 10,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (var i = 0; i < kColoringPalette.length; i++)
                  _Swatch(
                    index: i,
                    color: kColoringPalette[i],
                    selected: pickedColor == null && i == selectedColor,
                    showNumber: mode == ColoringMode.byNumber,
                    colors: colors,
                    onTap: () => onColor(i),
                  ),
                if (mode != ColoringMode.byNumber)
                  _PickerSwatch(
                    active: pickedColor != null,
                    color: pickedColor,
                    colors: colors,
                    onTap: onPick,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: <Widget>[
                _NavIconBtn(asset: 'assets/ui/back.png', onTap: onUndo),
                _NavIconBtn(asset: 'assets/ui/forward.png', onTap: onRedo),
                if (!locked)
                  _ActionBtn(icon: Icons.refresh_rounded, label: 'Заново', colors: colors, onTap: onClear),
                if (!locked && mode != ColoringMode.freeDraw)
                  _ActionBtn(
                    icon: Icons.image_rounded,
                    label: 'Картинка',
                    colors: colors,
                    onTap: onPicture,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.index,
    required this.color,
    required this.selected,
    required this.showNumber,
    required this.colors,
    required this.onTap,
  });

  final int index;
  final Color color;
  final bool selected;
  final bool showNumber;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? colors.onSurface : Colors.white.withValues(alpha: 0.8),
            width: selected ? 4 : 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.18),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: showNumber
            ? Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  shadows: <Shadow>[Shadow(color: Colors.black38, blurRadius: 2)],
                ),
              )
            : null,
      ),
    );
  }
}

class _PickerSwatch extends StatelessWidget {
  const _PickerSwatch({
    required this.active,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  final bool active;
  final Color? color;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          gradient: color == null
              ? const SweepGradient(colors: <Color>[
                  Color(0xFFE53935),
                  Color(0xFFFFEB3B),
                  Color(0xFF66BB6A),
                  Color(0xFF42A5F5),
                  Color(0xFFAB47BC),
                  Color(0xFFE53935),
                ])
              : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? colors.onSurface : Colors.white.withValues(alpha: 0.8),
            width: active ? 4 : 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.18),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(Icons.colorize_rounded, size: 18, color: Colors.white.withValues(alpha: 0.95)),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.n,
    required this.selected,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  final int n;
  final bool selected;
  final bool enabled;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.primary : colors.onSurface.withValues(alpha: 0.15),
              width: 2,
            ),
          ),
          child: Text(
            '$n',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? colors.onPrimary : colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

/// Чип выбора темы раскрасок: эмодзи + название (из [coloringCategoryMeta]).
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.categoryKey,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String categoryKey;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = coloringCategoryMeta(categoryKey);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.primary : colors.onSurface.withValues(alpha: 0.12),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(meta.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              meta.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? colors.onPrimary
                        : colors.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Круглая нав-кнопка из картинки (назад/вперёд) — без Material-подложки.
class _NavIconBtn extends StatelessWidget {
  const _NavIconBtn({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Image.asset(asset, width: 44, height: 44),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: colors.onSurface.withValues(alpha: 0.75),
        textStyle: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.colors, required this.onTap});

  final IconData icon;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface.withValues(alpha: 0.92),
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

/// Открыть пикер картинок (карусель миниатюр) по кнопке «Картинка». Миниатюры
/// идут по порядку уровня; тап по карточке — выбрать, сердечко — в избранное.
/// [currentAsset] подсвечивается рамкой.
Future<void> showColoringPicturePicker(
  BuildContext context, {
  required List<ColoringPick> picks,
  required String? currentAsset,
  required bool Function(String asset) isFavorite,
  required Future<void> Function(String asset) onToggleFavorite,
  required void Function(ColoringPick pick) onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PicturePickerSheet(
      picks: picks,
      currentAsset: currentAsset,
      isFavorite: isFavorite,
      onToggleFavorite: onToggleFavorite,
      onSelect: (pick) {
        Navigator.of(ctx).pop();
        onSelect(pick);
      },
    ),
  );
}

class _PicturePickerSheet extends StatefulWidget {
  const _PicturePickerSheet({
    required this.picks,
    required this.currentAsset,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onSelect,
  });

  final List<ColoringPick> picks;
  final String? currentAsset;
  final bool Function(String asset) isFavorite;
  final Future<void> Function(String asset) onToggleFavorite;
  final void Function(ColoringPick pick) onSelect;

  @override
  State<_PicturePickerSheet> createState() => _PicturePickerSheetState();
}

class _PicturePickerSheetState extends State<_PicturePickerSheet> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Выбери картинку',
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: widget.picks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final pick = widget.picks[i];
                  return _PicturePickerCard(
                    pick: pick,
                    selected: pick.asset == widget.currentAsset,
                    favorite: widget.isFavorite(pick.asset),
                    colors: colors,
                    onTap: () => widget.onSelect(pick),
                    onToggleFavorite: () async {
                      await widget.onToggleFavorite(pick.asset);
                      if (mounted) setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка-миниатюра в пикере: картинка на белом листе + бейдж уровня +
/// сердечко избранного. Тап по карточке — выбрать, по сердечку — переключить.
class _PicturePickerCard extends StatelessWidget {
  const _PicturePickerCard({
    required this.pick,
    required this.selected,
    required this.favorite,
    required this.colors,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final ColoringPick pick;
  final bool selected;
  final bool favorite;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 124,
        child: Stack(
          children: <Widget>[
            Container(
              width: 124,
              height: 150,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.12),
                  width: selected ? 3 : 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colors.onBackground.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.asset(pick.asset, fit: BoxFit.contain),
            ),
            // Бейдж уровня.
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pick.level}',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Сердечко (избранное): полное при выборе, бледное иначе.
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                onTap: onToggleFavorite,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Opacity(
                    opacity: favorite ? 1.0 : 0.3,
                    child: Image.asset('assets/ui/favorite.png',
                        width: 26, height: 26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
