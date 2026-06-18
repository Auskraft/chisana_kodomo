import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../logic/music_logic.dart';

/// HUD «Музыки»: сегментированный таб-бар инструментов (как в раскраске — одна
/// «пилюля», сегменты — иконки, активный на заливке primary) + кнопка «домой».
/// Свободная игрушка — без пауз/наборов/раундов; выход кнопкой «домой».
/// FittedBox (а не скролл): тень пилюли не режется и по высоте не тянется.
class MusicHud extends StatelessWidget {
  const MusicHud({
    super.key,
    required this.onHome,
    required this.instruments,
    required this.currentId,
    required this.onInstrument,
  });

  final VoidCallback onHome;
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
                alignment: Alignment.center,
                child: _InstrumentTabs(
                  instruments: instruments,
                  currentId: currentId,
                  colors: colors,
                  onTap: onInstrument,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _HomeButton(onTap: onHome),
          ],
        ),
      ),
    );
  }
}

/// Кнопка «домой» (выход в лобби) — клеевидная иконка `assets/ui/home.png`.
class _HomeButton extends StatelessWidget {
  const _HomeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset('assets/ui/home.png', width: 48, height: 48),
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
              iconAsset: inst.iconAsset,
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

/// Один сегмент: арт-иконка инструмента (эмодзи — фолбэк, если файла нет);
/// активный — на заливке [primary]. Название — в Semantics (доступность).
class _InstrumentSegment extends StatelessWidget {
  const _InstrumentSegment({
    required this.iconAsset,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String iconAsset;
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
          width: 54,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Image.asset(
            iconAsset,
            width: 36,
            height: 36,
            cacheWidth: 108,
            errorBuilder: (_, _, _) =>
                Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}
