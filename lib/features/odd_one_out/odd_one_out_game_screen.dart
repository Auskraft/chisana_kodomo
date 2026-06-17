import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/praise/praise.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/odd_one_out_flame_game.dart';
import 'logic/odd_one_out_logic.dart';
import 'ui/odd_one_out_overlays.dart';

/// id игры для прогресса в GameStorage (= папка/feature).
const String kOddOneOutGameId = 'odd_one_out';

/// Экран-хост «Что лишнее?»: Flame-канвас + оверлеи по фазе/паузе, голос и
/// запись прогресса (звёзды/наборы).
class OddOneOutGameScreen extends StatefulWidget {
  const OddOneOutGameScreen({super.key, required this.set});

  final OddSet set;

  @override
  State<OddOneOutGameScreen> createState() => _OddOneOutGameScreenState();
}

class _OddOneOutGameScreenState extends State<OddOneOutGameScreen> {
  late final OddOneOutGame _game;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = OddOneOutGame(
      set: widget.set,
      colors: context.appColors,
      onSay: (String text, {bool flush = false}) =>
          Voice.instance.say(text, flush: flush),
      setDonePhrase: Praise.setDone(Gender.fromId(GameStorage.instance.childGender)),
    );
    _game.phase.addListener(_onPhase);
  }

  void _onPhase() {
    if (_game.phase.value != OddPhase.setDone) return;
    final storage = GameStorage.instance;
    storage.recordSetStars(kOddOneOutGameId, widget.set.index, _game.earnedStars.value);
    storage.unlockSets(kOddOneOutGameId, widget.set.index + 2);
  }

  bool get _hasNext => widget.set.index + 1 < OddSet.all.length;

  void _next() {
    Voice.instance.stop();
    if (_hasNext) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OddOneOutGameScreen(set: OddSet.all[widget.set.index + 1]),
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
    Voice.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GameWidget(game: _game),
          ValueListenableBuilder<OddPhase>(
            valueListenable: _game.phase,
            builder: (context, phase, _) {
              switch (phase) {
                case OddPhase.ready:
                  return ReadyPanel(
                    emoji: '🧩',
                    title: 'Что лишнее?',
                    subtitle: 'Найди лишний предмет!',
                    onStart: _game.start,
                  );
                case OddPhase.setDone:
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
                case OddPhase.playing:
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
                        builder: (context, round, _) => OddOneOutHud(
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
