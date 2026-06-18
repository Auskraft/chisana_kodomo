import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/music_logic.dart';

/// HUD «Музыки»: горизонтально-прокручиваемые чипы инструментов + кнопка паузы.
/// Свободная игра — без набора/раунда. Прокрутка (а не сжатие): чипы остаются
/// читаемыми и крупными при любом числе инструментов; SingleChildScrollView не
/// растягивается по высоте — HUD держится в шапке.
class MusicHud extends StatelessWidget {
  const MusicHud({
    super.key,
    required this.onPause,
    required this.instruments,
    required this.currentId,
    required this.onInstrument,
  });

  final VoidCallback onPause;
  final List<Instrument> instruments;
  final String currentId;
  final ValueChanged<Instrument> onInstrument;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final inst in instruments)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _InstrumentChip(
                          label: inst.name,
                          selected: inst.id == currentId,
                          colors: colors,
                          onTap: () => onInstrument(inst),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            PauseButton(onTap: onPause),
          ],
        ),
      ),
    );
  }
}

/// Чип-таб инструмента: активный — на заливке [primary].
class _InstrumentChip extends StatelessWidget {
  const _InstrumentChip({
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? colors.onPrimary
                    : colors.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
