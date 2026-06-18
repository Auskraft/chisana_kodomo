import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/praise/praise.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/pairs_flame_game.dart';
import 'logic/pairs_logic.dart';
import 'ui/pairs_overlays.dart';

/// id игры для прогресса в GameStorage (= папка/feature).
const String kPairsGameId = 'pairs';

/// Экран-хост «Парочки»: Flame-канвас + оверлеи по фазе/паузе, голос и запись
/// прогресса (звёзды/наборы).
class PairsGameScreen extends StatefulWidget {
  const PairsGameScreen({super.key, required this.set});

  final PairsSet set;

  @override
  State<PairsGameScreen> createState() => _PairsGameScreenState();
}

class _PairsGameScreenState extends State<PairsGameScreen> {
  late final PairsGame _game;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = PairsGame(
      set: widget.set,
      colors: context.appColors,
      onSay: (String text, {bool flush = false}) =>
          Voice.instance.say(text, flush: flush),
      setDonePhrase: Praise.setDone(Gender.fromId(GameStorage.instance.childGender)),
    );
    _game.phase.addListener(_onPhase);
  }

  void _onPhase() {
    if (_game.phase.value != PairsPhase.setDone) return;
    final storage = GameStorage.instance;
    storage.recordSetStars(kPairsGameId, widget.set.index, _game.earnedStars.value);
    storage.unlockSets(kPairsGameId, widget.set.index + 2);
  }

  bool get _hasNext => widget.set.index + 1 < PairsSet.all.length;

  void _next() {
    Voice.instance.stop();
    if (_hasNext) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PairsGameScreen(set: PairsSet.all[widget.set.index + 1]),
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
          ValueListenableBuilder<PairsPhase>(
            valueListenable: _game.phase,
            builder: (context, phase, _) {
              switch (phase) {
                case PairsPhase.ready:
                  return ReadyPanel(
                    emoji: '🃏',
                    iconAsset: 'assets/games/pairs.png',
                    title: 'Парочки',
                    subtitle: 'Открой две одинаковые карточки!',
                    onStart: _game.start,
                  );
                case PairsPhase.setDone:
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
                case PairsPhase.playing:
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
                        valueListenable: _game.matchedPairs,
                        builder: (context, matched, _) => PairsHud(
                          setNumber: widget.set.index + 1,
                          matched: matched,
                          total: widget.set.pairs,
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
