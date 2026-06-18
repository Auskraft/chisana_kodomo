import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';

/// HUD игры «Пазлы»: номер уровня + кнопка паузы. Тонкая полоса сверху,
/// чтобы не перекрывать доску.
class PuzzlesHud extends StatelessWidget {
  const PuzzlesHud({
    super.key,
    required this.levelNumber,
    required this.totalLevels,
    required this.onPause,
  });

  final int levelNumber;
  final int totalLevels;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            StatChip(label: 'Уровень', value: '$levelNumber / $totalLevels'),
            const Spacer(),
            PauseButton(onTap: onPause),
          ],
        ),
      ),
    );
  }
}
