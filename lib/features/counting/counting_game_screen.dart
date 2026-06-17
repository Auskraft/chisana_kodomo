import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/praise/praise.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/counting_flame_game.dart';
import 'logic/counting_logic.dart';
import 'ui/counting_overlays.dart';

/// id игры для прогресса в GameStorage (= папка/feature).
const String kCountingGameId = 'counting';

/// Экран-хост игры «Счёт»: Flame-канвас + оверлеи по фазе/паузе, голосовые
/// подсказки и запись прогресса (звёзды/наборы).
class CountingGameScreen extends StatefulWidget {
  const CountingGameScreen({super.key, required this.set});

  final CountSet set;

  @override
  State<CountingGameScreen> createState() => _CountingGameScreenState();
}

class _CountingGameScreenState extends State<CountingGameScreen> {
  late final CountingGame _game;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = CountingGame(
      set: widget.set,
      colors: context.appColors,
      onSay: (String text, {bool flush = false}) =>
          Voice.instance.say(text, flush: flush),
      setDonePhrase: Praise.setDone(Gender.fromId(GameStorage.instance.childGender)),
    );
    _game.phase.addListener(_onPhase);
  }

  void _onPhase() {
    if (_game.phase.value != CountPhase.setDone) return;
    final storage = GameStorage.instance;
    storage.recordSetStars(kCountingGameId, widget.set.index, _game.earnedStars.value);
    // Открыть следующий набор (unlockedSets — это КОЛИЧЕСТВО доступных).
    storage.unlockSets(kCountingGameId, widget.set.index + 2);
  }

  bool get _hasNext => widget.set.index + 1 < CountSet.all.length;

  void _next() {
    Voice.instance.stop();
    if (_hasNext) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CountingGameScreen(set: CountSet.all[widget.set.index + 1]),
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

  String _subtitle() => widget.set.mode == CountMode.tapCount
      ? 'Нажимай на каждый и считай!'
      : 'Сколько тут? Выбери цифру!';

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
          ValueListenableBuilder<CountPhase>(
            valueListenable: _game.phase,
            builder: (context, phase, _) {
              switch (phase) {
                case CountPhase.ready:
                  return ReadyPanel(
                    emoji: '🔢',
                    title: 'Счёт',
                    subtitle: _subtitle(),
                    onStart: _game.start,
                  );
                case CountPhase.setDone:
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
                case CountPhase.playing:
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
                        builder: (context, round, _) => CountingHud(
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
