import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/audio/sound_pool.dart';
import '../../core/components/overlay_kit.dart';
import '../../core/praise/praise.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/animals_flame_game.dart';
import 'logic/animals_logic.dart';
import 'ui/animals_overlays.dart';

/// id игры для прогресса в GameStorage (= папка/feature).
const String kAnimalsGameId = 'animals';

/// Экран-хост «Звуки животных»: Flame-канвас + оверлеи по фазе/паузе, голос и
/// запись прогресса (звёзды/наборы).
class AnimalsGameScreen extends StatefulWidget {
  const AnimalsGameScreen({super.key, required this.set});

  final AnimalSet set;

  @override
  State<AnimalsGameScreen> createState() => _AnimalsGameScreenState();
}

class _AnimalsGameScreenState extends State<AnimalsGameScreen> {
  late final AnimalsGame _game;
  bool _created = false;

  /// Пул для звуков зверей (`assets/animals/<key>.wav`; CC0-файлы — Фаза 5).
  final SoundPool _sounds = SoundPool(size: 3);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = AnimalsGame(
      set: widget.set,
      colors: context.appColors,
      onSay: (String text, {bool flush = false}) =>
          Voice.instance.say(text, flush: flush),
      onAnimalSound: (String key) => _sounds.play('animals/$key.wav'),
      setDonePhrase: Praise.setDone(Gender.fromId(GameStorage.instance.childGender)),
    );
    _game.phase.addListener(_onPhase);
  }

  void _onPhase() {
    if (_game.phase.value != AnimalsPhase.setDone) return;
    final storage = GameStorage.instance;
    storage.recordSetStars(kAnimalsGameId, widget.set.index, _game.earnedStars.value);
    storage.unlockSets(kAnimalsGameId, widget.set.index + 2);
  }

  bool get _hasNext => widget.set.index + 1 < AnimalSet.all.length;

  void _next() {
    Voice.instance.stop();
    if (_hasNext) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => AnimalsGameScreen(set: AnimalSet.all[widget.set.index + 1]),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _again() => _game.start();

  void _exit() {
    Voice.instance.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _game.phase.removeListener(_onPhase);
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
          ValueListenableBuilder<AnimalsPhase>(
            valueListenable: _game.phase,
            builder: (context, phase, _) {
              switch (phase) {
                case AnimalsPhase.ready:
                  return ReadyPanel(
                    emoji: '🐶',
                    title: 'Звуки',
                    subtitle: 'Слушай: где зверёк?',
                    onStart: _game.start,
                  );
                case AnimalsPhase.setDone:
                  return ValueListenableBuilder<int>(
                    valueListenable: _game.earnedStars,
                    builder: (context, stars, _) => PraisePanel(
                      title: 'Молодец!',
                      stars: stars,
                      nextLabel: _hasNext ? 'Дальше' : 'В лобби',
                      onNext: _next,
                      onAgain: _again,
                      onExit: _exit,
                    ),
                  );
                case AnimalsPhase.playing:
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
                      return ValueListenableBuilder<int>(
                        valueListenable: _game.roundNumber,
                        builder: (context, round, _) => AnimalsHud(
                          setNumber: widget.set.index + 1,
                          roundNumber: round,
                          roundsPerSet: _game.roundsPerSet,
                          onPause: _game.togglePause,
                        ),
                      );
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
