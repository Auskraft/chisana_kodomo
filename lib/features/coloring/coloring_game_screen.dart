import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/feedback/haptics.dart';
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
  bool _locked = false; // детский замок: прячет навигацию, блокирует «Назад»
  final Map<int, Offset> _pointers = <int, Offset>{};
  bool _painting = false;

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

  void _lock() {
    Haptics.select();
    setState(() => _locked = true);
  }

  void _unlock() {
    Haptics.success();
    setState(() => _locked = false);
  }

  // ── Ввод холста: 1 палец рисует (зум 2 пальцами — следующий коммит) ──────────
  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_game.mode.value != ColoringMode.fill || !_game.canPaintRaster) return;
    if (_pointers.length == 1) {
      _painting = true;
      _game.canvasDown(e.localPosition);
    } else if (_painting) {
      _painting = false;
      _game.canvasCancel(); // лёг второй палец — мазок отменяем
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    if (_painting && _pointers.length == 1) {
      _game.canvasMove(e.localPosition);
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    if (_painting && _pointers.isEmpty) {
      _painting = false;
      _game.canvasUp();
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (_painting && _pointers.isEmpty) {
      _painting = false;
      _game.canvasUp();
    }
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
    return PopScope(
      // При детском замке системная «Назад» не закрывает экран (выход — удержанием).
      canPop: !_locked,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            // Холст + ввод: 1 палец рисует/заливает, 2 пальца — зум (коммит 2).
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: GameWidget(game: _game),
            ),
            // Верхняя панель — режимы + замок.
            Align(
              alignment: Alignment.topCenter,
              child: ValueListenableBuilder<ColoringMode>(
                valueListenable: _game.mode,
                builder: (context, mode, _) => ColoringTopBar(
                  mode: mode,
                  onMode: _game.setMode,
                  onHome: _exit,
                  locked: _locked,
                  onLock: _lock,
                  onUnlock: _unlock,
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
                  _game.tool,
                  _game.brushSize,
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
                  paintTool: _game.tool.value,
                  onTool: _game.setTool,
                  brushSize: _game.brushSize.value,
                  onBrushSize: _game.setBrushSize,
                  showTools: _game.mode.value == ColoringMode.fill &&
                      _game.canPaintRaster,
                  locked: _locked,
                ),
              ),
            ),
            // Похвала по завершению (заливка / по номерам). При замке не
            // показываем (в ней есть выход); у раскраски-заливки завершения нет.
            ValueListenableBuilder<bool>(
              valueListenable: _game.completed,
              builder: (context, done, _) {
                if (!done || _locked) return const SizedBox.shrink();
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
      ),
    );
  }
}
