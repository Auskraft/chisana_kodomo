import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';
import '../../../core/theme/app_colors.dart';
import '../logic/music_logic.dart';

/// HUD «Музыки»: сегментированный таб-бар инструментов (как в раскраске — одна
/// «пилюля», сегменты — иконки-эмодзи, активный на заливке primary) + пауза.
/// FittedBox (а не скролл): тень пилюли не режется, и на узких экранах группа
/// чуть ужимается; по высоте не тянется — HUD держится в шапке.
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
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

/// Сегментированный таб-бар: одна «пилюля» с иконками-сегментами (как `_ModeTabs`
/// в раскраске).
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
        borderRadius: BorderRadius.circular(24),
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
              emoji: inst.emoji,
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

/// Один сегмент: иконка-эмодзи инструмента; активный — на заливке [primary].
/// Название — в Semantics (доступность), визуально только иконка.
class _InstrumentSegment extends StatelessWidget {
  const _InstrumentSegment({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 52,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
