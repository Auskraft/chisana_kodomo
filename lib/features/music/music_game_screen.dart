import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/music_flame_game.dart';
import 'ui/music_overlays.dart';

/// Экран-хост «Музыка»: Flame-ксилофон + оверлеи (старт/пауза). Свободная игра —
/// без наборов, звёзд и записи прогресса.
class MusicGameScreen extends StatefulWidget {
  const MusicGameScreen({super.key});

  @override
  State<MusicGameScreen> createState() => _MusicGameScreenState();
}

class _MusicGameScreenState extends State<MusicGameScreen> {
  late final MusicGame _game;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = MusicGame(colors: context.appColors);
  }

  void _exit() {
    Voice.instance.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GameWidget(game: _game),
          ValueListenableBuilder<MusicPhase>(
            valueListenable: _game.phase,
            builder: (context, phase, _) {
              switch (phase) {
                case MusicPhase.ready:
                  return ReadyPanel(
                    emoji: '🎹',
                    title: 'Музыка',
                    subtitle: 'Нажимай на пластинки!',
                    onStart: _game.start,
                  );
                case MusicPhase.playing:
                  return ValueListenableBuilder<bool>(
                    valueListenable: _game.isPaused,
                    builder: (context, paused, _) {
                      if (paused) {
                        return PausePanel(
                          onResume: _game.resume,
                          onRestart: _game.start,
                          onExit: _exit,
                        );
                      }
                      return MusicHud(onPause: _game.togglePause);
                    },
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}
