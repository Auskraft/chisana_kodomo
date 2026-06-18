import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/praise/praise.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/puzzles_flame_game.dart';
import 'logic/puzzles_logic.dart';
import 'ui/puzzles_overlays.dart';

/// id игры для прогресса в GameStorage (= папка/feature).
const String kPuzzlesGameId = 'puzzles';

/// Экран-хост игры «Пазлы»: Flame-канвас + оверлеи по фазе/паузе, голосовые
/// подсказки и запись прогресса (звёзды/наборы).
class PuzzlesGameScreen extends StatefulWidget {
  const PuzzlesGameScreen({super.key, required this.set, this.autoStart = false});

  final PuzzleSet set;

  /// Стартовать сразу (переход «Дальше» на след. уровень — без панели «Играть»).
  final bool autoStart;

  @override
  State<PuzzlesGameScreen> createState() => _PuzzlesGameScreenState();
}

class _PuzzlesGameScreenState extends State<PuzzlesGameScreen> {
  late final PuzzlesGame _game;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = PuzzlesGame(
      set: widget.set,
      colors: context.appColors,
      onSay: (String text, {bool flush = false}) =>
          Voice.instance.say(text, flush: flush),
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

  void _onPhase() {
    if (_game.phase.value != PuzzlePhase.setDone) return;
    final storage = GameStorage.instance;
    storage.recordSetStars(kPuzzlesGameId, widget.set.index, _game.earnedStars.value);
    // Открыть следующий набор (unlockedSets — это КОЛИЧЕСТВО доступных).
    storage.unlockSets(kPuzzlesGameId, widget.set.index + 2);
  }

  bool get _hasNext => widget.set.index + 1 < PuzzleSet.all.length;

  void _next() {
    Voice.instance.stop();
    if (_hasNext) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PuzzlesGameScreen(
              set: PuzzleSet.all[widget.set.index + 1], autoStart: true),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _again() {
    _game.start(); // тот же набор заново
  }

  void _exit() {
    Voice.instance.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _game.phase.removeListener(_onPhase);
    Voice.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GameWidget(game: _game),
          ValueListenableBuilder<PuzzlePhase>(
            valueListenable: _game.phase,
            builder: (context, phase, _) {
              switch (phase) {
                case PuzzlePhase.ready:
                  if (widget.autoStart) return const SizedBox.shrink();
                  return ReadyPanel(
                    emoji: '🧩',
                    iconAsset: 'assets/games/puzzles.png',
                    title: 'Пазлы',
                    subtitle: 'Собери картинку из кусочков!',
                    onStart: _game.start,
                  );
                case PuzzlePhase.setDone:
                  return ValueListenableBuilder<int>(
                    valueListenable: _game.earnedStars,
                    builder: (context, stars, _) => PraisePanel(
                      title: 'Молодец!',
                      stars: stars,
                      totalStars: 1,
                      nextLabel: _hasNext ? 'Дальше' : 'В лобби',
                      onNext: _next,
                      onAgain: _again,
                      onExit: _exit,
                    ),
                  );
                case PuzzlePhase.playing:
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
                      return PuzzlesHud(
                        levelNumber: widget.set.index + 1,
                        totalLevels: PuzzleSet.all.length,
                        onPause: _game.togglePause,
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
