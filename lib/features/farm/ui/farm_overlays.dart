import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';

/// HUD «Фермы»: только кнопка паузы (свободная игра — без набора/раунда).
class FarmHud extends StatelessWidget {
  const FarmHud({super.key, required this.onPause});

  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            const Spacer(),
            PauseButton(onTap: onPause),
          ],
        ),
      ),
    );
  }
}
