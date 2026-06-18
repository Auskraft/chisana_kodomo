import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';

/// HUD игры «Цвета и формы»: набор + раунд + пауза.
class ColorsShapesHud extends StatelessWidget {
  const ColorsShapesHud({
    super.key,
    required this.setNumber,
    required this.roundNumber,
    required this.roundsPerSet,
    required this.onPause,
  });

  final int setNumber;
  final int roundNumber;
  final int roundsPerSet;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            StatChip(label: 'Уровень', value: '$setNumber'),
            const SizedBox(width: 10),
            StatChip(label: 'Раунд', value: '$roundNumber / $roundsPerSet'),
            const Spacer(),
            PauseButton(onTap: onPause),
          ],
        ),
      ),
    );
  }
}
