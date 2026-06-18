import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/audio/sound_pool.dart';
import '../../core/components/overlay_kit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/music_flame_game.dart';
import 'logic/music_logic.dart';
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

  /// Полифонический пул для тонов ксилофона (`assets/notes/note_N.wav`).
  final SoundPool _notes = SoundPool(size: 8);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = MusicGame(
      colors: context.appColors,
      onNote: (XyloNote note) => _notes.play(
          'notes/${_game.instrument.value.soundPrefix}_${Xylophone.cMajor.indexOf(note)}.wav'),
    );
  }

  void _exit() {
    Voice.instance.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
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
                    iconAsset: 'assets/games/music.png',
                    title: 'Музыка',
                    subtitle: 'Нажимай на пластинки!',
                    onStart: _game.start,
                  );
                case MusicPhase.playing:
                  // Свободная игрушка — без пауз; выход кнопкой «домой».
                  return ValueListenableBuilder<Instrument>(
                    valueListenable: _game.instrument,
                    builder: (context, inst, _) => MusicHud(
                      onHome: _exit,
                      instruments: Instrument.all,
                      currentId: inst.id,
                      onInstrument: _game.setInstrument,
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }
}
