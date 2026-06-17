import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/coloring_flame_game.dart';
import 'logic/coloring_logic.dart';
import 'ui/coloring_overlays.dart';

/// Экран-хост «Раскраска»: Flame-холст + контролы (режим/палитра/действия) и
/// похвала по завершению. Творческая студия — без наборов/звёзд/прогресса.
class ColoringGameScreen extends StatefulWidget {
  const ColoringGameScreen({super.key});

  @override
  State<ColoringGameScreen> createState() => _ColoringGameScreenState();
}

class _ColoringGameScreenState extends State<ColoringGameScreen> {
  late final ColoringGame _game;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    _game = ColoringGame(colors: context.appColors);
    _game.completed.addListener(_onCompleted);
  }

  void _onCompleted() {
    if (_game.completed.value) {
      Voice.instance.say('Готово! Красиво!', flush: true);
    }
  }

  void _exit() {
    Voice.instance.stop();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _game.completed.removeListener(_onCompleted);
    Voice.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GameWidget(game: _game),
          // Верхняя панель — режимы.
          Align(
            alignment: Alignment.topCenter,
            child: ValueListenableBuilder<ColoringMode>(
              valueListenable: _game.mode,
              builder: (context, mode, _) => ColoringTopBar(
                mode: mode,
                onMode: _game.setMode,
                onHome: _exit,
              ),
            ),
          ),
          // Нижняя панель — палитра и действия.
          Align(
            alignment: Alignment.bottomCenter,
            child: ValueListenableBuilder<ColoringMode>(
              valueListenable: _game.mode,
              builder: (context, mode, _) => ValueListenableBuilder<int>(
                valueListenable: _game.selectedColor,
                builder: (context, sel, _) => ColoringBottomBar(
                  mode: mode,
                  selectedColor: sel,
                  onColor: _game.setColor,
                  onClear: _game.clearArt,
                  onNextPicture: _game.nextPicture,
                ),
              ),
            ),
          ),
          // Похвала по завершению (заливка / по номерам).
          ValueListenableBuilder<bool>(
            valueListenable: _game.completed,
            builder: (context, done, _) {
              if (!done) return const SizedBox.shrink();
              return PraisePanel(
                emoji: '🎨',
                title: 'Красиво!',
                stars: 3,
                nextLabel: 'Ещё',
                onNext: _game.nextPicture,
                onAgain: _game.clearArt,
                onExit: _exit,
              );
            },
          ),
        ],
      ),
    );
  }
}
