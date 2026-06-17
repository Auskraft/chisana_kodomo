import 'package:flutter/material.dart';

import '../../../core/components/overlay_kit.dart';

/// HUD «Музыки»: только кнопка паузы (свободная игра — без набора/раунда).
class MusicHud extends StatelessWidget {
  const MusicHud({super.key, required this.onPause});

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
