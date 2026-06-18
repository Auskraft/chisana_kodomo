import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';

/// HUD игры «Пазлы»: набор + номер картинки + кнопка паузы. Тонкая полоса сверху,
/// чтобы не перекрывать доску.
class PuzzlesHud extends StatelessWidget {
  const PuzzlesHud({
    super.key,
    required this.setNumber,
    required this.pictureNumber,
    required this.picturesPerSet,
    required this.onPause,
  });

  final int setNumber;
  final int pictureNumber;
  final int picturesPerSet;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            StatChip(label: 'Набор', value: '$setNumber'),
            const SizedBox(width: 10),
            StatChip(label: 'Картинка', value: '$pictureNumber / $picturesPerSet'),
            const Spacer(),
            PauseButton(onTap: onPause),
          ],
        ),
      ),
    );
  }
}
