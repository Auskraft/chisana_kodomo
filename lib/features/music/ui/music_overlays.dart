import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/music_logic.dart';

/// HUD «Музыки»: сегментированный таб-бар инструментов (как в раскраске — одна
/// «пилюля», активный сегмент на заливке primary) + кнопка паузы. Пилюля
/// горизонтально прокручивается (5 названий не влезают в строку в читаемом
/// размере); SingleChildScrollView по высоте не тянется — HUD держится в шапке.
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
                child: _InstrumentTabs(
                  instruments: instruments,
                  currentId: currentId,
                  colors: colors,
                  onTap: onInstrument,
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

/// Сегментированный таб-бар: одна «пилюля» с сегментами-названиями инструментов
/// (как `_ModeTabs` в раскраске).
class _InstrumentTabs extends StatelessWidget {
  const _InstrumentTabs({
    required this.instruments,
    required this.currentId,
    required this.colors,
    required this.onTap,
  });

  final List<Instrument> instruments;
  final String currentId;
  final AppColors colors;
  final ValueChanged<Instrument> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
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
          for (final inst in instruments)
            _InstrumentSegment(
              label: inst.name,
              selected: inst.id == currentId,
              colors: colors,
              onTap: () => onTap(inst),
            ),
        ],
      ),
    );
  }
}

/// Один сегмент таб-бара: активный — на заливке [primary], неактивный прозрачный.
class _InstrumentSegment extends StatelessWidget {
  const _InstrumentSegment({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
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
