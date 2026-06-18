import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/praise/praise.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/colors_shapes_flame_game.dart';
import 'logic/colors_shapes_logic.dart';
import 'ui/colors_shapes_overlays.dart';

/// id игры для прогресса в GameStorage (= папка/feature).
const String kColorsShapesGameId = 'colors_shapes';

/// Экран-хост «Цвета и формы»: Flame-канвас + оверлеи по фазе/паузе, голос и
/// запись прогресса (звёзды/наборы).
class ColorsShapesGameScreen extends StatefulWidget {
  const ColorsShapesGameScreen({super.key, required this.set, this.autoStart = false});

  final CSSet set;

  /// Стартовать сразу (переход «Дальше» на след. уровень — без панели «Играть»).
  final bool autoStart;

  @override
  State<ColorsShapesGameScreen> createState() => _ColorsShapesGameScreenState();
}

class _ColorsShapesGameScreenState extends State<ColorsShapesGameScreen> {
  late final ColorsShapesGame _game;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = ColorsShapesGame(
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
    if (_game.phase.value != CSPhase.setDone) return;
    final storage = GameStorage.instance;
    storage.recordSetStars(kColorsShapesGameId, widget.set.index, _game.earnedStars.value);
    storage.unlockSets(kColorsShapesGameId, widget.set.index + 2);
  }

  bool get _hasNext => widget.set.index + 1 < CSSet.all.length;

  void _next() {
    Voice.instance.stop();
    if (_hasNext) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ColorsShapesGameScreen(
              set: CSSet.all[widget.set.index + 1], autoStart: true),
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

  String _subtitle() {
    switch (widget.set.mode) {
      case MatchMode.color:
        return 'Найди такой же цвет!';
      case MatchMode.shape:
        return 'Найди такую же фигуру!';
      case MatchMode.both:
        return 'Найди точно такой же!';
    }
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
          ValueListenableBuilder<CSPhase>(
            valueListenable: _game.phase,
            builder: (context, phase, _) {
              switch (phase) {
                case CSPhase.ready:
                  if (widget.autoStart) return const SizedBox.shrink();
                  return ReadyPanel(
                    emoji: '🎨',
                    iconAsset: 'assets/games/colors_shapes.png',
                    title: 'Угадай-ка',
                    subtitle: _subtitle(),
                    onStart: _game.start,
                  );
                case CSPhase.setDone:
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
                case CSPhase.playing:
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
                        builder: (context, round, _) => ColorsShapesHud(
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
