import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/audio/sound_pool.dart';
import '../../core/components/overlay_kit.dart';
import '../../core/praise/praise.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import '../animals/logic/animals_logic.dart';
import 'game/farm_flame_game.dart';
import 'ui/farm_overlays.dart';

/// id игры для прогресса в GameStorage (= папка/feature).
const String kFarmGameId = 'farm';

/// Экран-хост «Ферма» (квиз «угадай звук»): Flame-канвас + оверлеи по фазе/паузе,
/// проигрывание звука-загадки (реальный CC0 или имя голосом) и запись прогресса.
class FarmGameScreen extends StatefulWidget {
  const FarmGameScreen({super.key, required this.set, this.autoStart = false});

  final AnimalSet set;

  /// Стартовать сразу (переход «Дальше» на след. уровень — без панели «Играть»).
  final bool autoStart;

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
      set: widget.set,
      colors: context.appColors,
      onSay: (String text, {bool flush = false}) =>
          Voice.instance.say(text, flush: flush),
      onCue: _playCue,
      onStopCue: _sounds.stopAll,
      setDonePhrase: Praise.setDone(Gender.fromId(GameStorage.instance.childGender)),
    );
    _game.phase.addListener(_onPhase);
    // «Дальше» на следующий уровень — стартуем сразу, без панели «Играть».
    if (widget.autoStart) {
      _game.loaded.then((_) {
        if (mounted) _game.start();
      });
    }
  }

  /// Загадка-звук: реальный CC0-`.wav`, а пока файла нет — имя зверя голосом.
  Future<void> _playCue(Animal a) async {
    final asset = 'animals/${a.soundKey}.wav';
    if (await _sounds.has(asset)) {
      // Глушим голос (остаток имени/похвалы прошлого раунда), чтобы он не
      // наложился на звук зверя — звук и реплика взаимоисключаемы.
      await Voice.instance.stop();
      await _sounds.play(asset);
    } else {
      Voice.instance.say('${animalNameCap(a)}!', flush: true);
    }
  }

  void _onPhase() {
    if (_game.phase.value != FarmPhase.setDone) return;
    final storage = GameStorage.instance;
    storage.recordSetStars(kFarmGameId, widget.set.index, _game.earnedStars.value);
    storage.unlockSets(kFarmGameId, widget.set.index + 2);
  }

  bool get _hasNext => widget.set.index + 1 < AnimalSet.all.length;

  void _next() {
    Voice.instance.stop();
    if (_hasNext) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => FarmGameScreen(
              set: AnimalSet.all[widget.set.index + 1], autoStart: true),
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
          ValueListenableBuilder<FarmPhase>(
            valueListenable: _game.phase,
            builder: (context, phase, _) {
              switch (phase) {
                case FarmPhase.ready:
                  if (widget.autoStart) return const SizedBox.shrink();
                  return ReadyPanel(
                    emoji: '🔊',
                    iconAsset: 'assets/games/farm.png',
                    title: 'Угадай, кто это',
                    subtitle: 'Послушай звук и выбери зверя!',
                    onStart: _game.start,
                  );
                case FarmPhase.setDone:
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
                      return ValueListenableBuilder<int>(
                        valueListenable: _game.roundNumber,
                        builder: (context, round, _) => FarmHud(
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
