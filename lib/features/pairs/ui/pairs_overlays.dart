import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';

/// HUD игры «Парочки»: набор + найденные пары + кнопка паузы.
class PairsHud extends StatelessWidget {
  const PairsHud({
    super.key,
    required this.setNumber,
    required this.matched,
    required this.total,
    required this.onPause,
  });

  final int setNumber;
  final int matched;
  final int total;
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
            StatChip(label: 'Пары', value: '$matched / $total'),
            const Spacer(),
            PauseButton(onTap: onPause),
          ],
        ),
      ),
    );
  }
}
