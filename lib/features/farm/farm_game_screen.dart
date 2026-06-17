import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/audio/sound_pool.dart';
import '../../core/components/overlay_kit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import '../animals/logic/animals_logic.dart';
import 'game/farm_flame_game.dart';
import 'ui/farm_overlays.dart';

/// Экран-хост «Ферма»: Flame-канвас + оверлеи (старт/пауза). Свободная игра —
/// без наборов/звёзд/прогресса.
class FarmGameScreen extends StatefulWidget {
  const FarmGameScreen({super.key});

  @override
  State<FarmGameScreen> createState() => _FarmGameScreenState();
}

class _FarmGameScreenState extends State<FarmGameScreen> {
  late final FarmGame _game;
  bool _created = false;

  /// Пул для звуков зверей (`assets/animals/<key>.wav`; CC0-файлы — Фаза 5).
  final SoundPool _sounds = SoundPool(size: 3);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = FarmGame(
      colors: context.appColors,
      onAnimal: _playAnimal,
    );
  }

  /// Реальный звук зверя (CC0 `assets/animals/<key>.wav`), а пока файла нет —
  /// имя зверя голосом («Собачка!»), без мультяшного «хрю-хрю».
  Future<void> _playAnimal(Animal a) async {
    final asset = 'animals/${a.soundKey}.wav';
    if (await _sounds.has(asset)) {
      await _sounds.play(asset);
    } else {
      Voice.instance.say('${animalNameCap(a)}!', flush: true);
    }
  }

  void _exit() {
    Voice.instance.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sounds.dispose();
    Voice.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GameWidget(game: _game),
          ValueListenableBuilder<FarmPhase>(
            valueListenable: _game.phase,
            builder: (context, phase, _) {
              switch (phase) {
                case FarmPhase.ready:
                  return ReadyPanel(
                    emoji: '🐮',
                    title: 'Ферма',
                    subtitle: 'Нажми на зверя — послушай, как он говорит!',
                    onStart: _game.start,
                  );
                case FarmPhase.playing:
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
                      return FarmHud(onPause: _game.togglePause);
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
