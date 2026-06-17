import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/storage/game_storage.dart';
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

  /// Колор-пикер: выбрать произвольный цвет кисти.
  Future<void> _openPicker() async {
    var picked = _game.brushColor;
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выбери цвет'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: picked,
            onColorChanged: (Color c) => picked = c,
            enableAlpha: false,
            labelTypes: const <ColorLabelType>[],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(picked),
            child: const Text('Готово'),
          ),
        ],
      ),
    );
    if (result != null) _game.setPickedColor(result);
  }

  /// Кнопка «Картинка»: в растровом режиме — пикер-карусель (выбор по уровню);
  /// в векторном (Домик/Цветок) — просто следующая картинка.
  void _openPicture() {
    if (!_game.canPickRaster) {
      _game.nextPicture();
      return;
    }
    final storage = GameStorage.instance;
    showColoringPicturePicker(
      context,
      picks: _game.picksForCurrentCategory(),
      currentAsset: _game.currentAsset,
      isFavorite: storage.isColoringFavorite,
      onToggleFavorite: storage.toggleColoringFavorite,
      onSelect: (pick) => _game.selectRasterPicture(pick.level, pick.asset),
    );
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
            child: ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[
                _game.mode,
                _game.selectedColor,
                _game.pickedColor,
                _game.category,
                _game.level,
              ]),
              builder: (context, _) => ColoringBottomBar(
                mode: _game.mode.value,
                selectedColor: _game.selectedColor.value,
                pickedColor: _game.pickedColor.value,
                category: _game.category.value,
                categories: _game.coloringCategories,
                level: _game.level.value,
                availableLevels: _game.coloringLevels,
                onColor: _game.setColor,
                onPick: _openPicker,
                onCategory: _game.setCategory,
                onLevel: _game.setLevel,
                onUndo: _game.undo,
                onRedo: _game.redo,
                onClear: _game.clearArt,
                onPicture: _openPicture,
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
