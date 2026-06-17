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

/// Верхняя панель: «домой» + переключатель режима.
class ColoringTopBar extends StatelessWidget {
  const ColoringTopBar({
    super.key,
    required this.mode,
    required this.onMode,
    required this.onHome,
  });

  final ColoringMode mode;
  final ValueChanged<ColoringMode> onMode;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                        padding: const EdgeInsets.symmetric(horizontal: 3),
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
    required this.onColor,
    required this.onPick,
    required this.onUndo,
    required this.onClear,
    required this.onNextPicture,
  });

  final ColoringMode mode;
  final int selectedColor;
  final Color? pickedColor;
  final ValueChanged<int> onColor;
  final VoidCallback onPick;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onNextPicture;

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
              spacing: 4,
              children: <Widget>[
                _ActionBtn(icon: Icons.undo_rounded, label: 'Отменить', colors: colors, onTap: onUndo),
                _ActionBtn(icon: Icons.refresh_rounded, label: 'Заново', colors: colors, onTap: onClear),
                if (mode != ColoringMode.freeDraw)
                  _ActionBtn(
                    icon: Icons.image_rounded,
                    label: 'Картинка',
                    colors: colors,
                    onTap: onNextPicture,
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
