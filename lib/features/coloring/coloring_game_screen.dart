import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/components/overlay_kit.dart';
import '../../core/feedback/haptics.dart';
import '../../core/storage/game_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/voice/voice.dart';
import 'game/coloring_flame_game.dart';
import 'logic/coloring_logic.dart';
import 'ui/coloring_overlays.dart';

/// Окно ожидания второго пальца перед покраской: если второй палец ложится в
/// этот срок — это зум (без случайной заливки/мазка), иначе красим. Подобрано так,
/// чтобы одиночный тап оставался отзывчивым (быстрый тап красит сразу по отпусканию).
const Duration _kPaintHoldOff = Duration(milliseconds: 100);

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
  bool _zooming = false;
  double _zoomStartDist = 0;
  // Отложенный (ещё не применённый) одиночный тап — ждём, не пойдёт ли зум.
  Offset? _pendingDownPos;
  Timer? _paintDelay;

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

  // ── Ввод холста: 1 палец рисует/заливает, 2 пальца — зум/панорама ────────────
  // Покраску НЕ применяем сразу по касанию: ждём окно [_kPaintHoldOff]. Лёг второй
  // палец за это время → зум, краски нет (иначе при зуме срабатывала заливка/мазок).
  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_game.mode.value != ColoringMode.fill || !_game.canPaintRaster) return;
    if (_pointers.length >= 2) {
      _cancelPendingPaint(); // второй палец — отменяем отложенный тап
      if (_painting) {
        _painting = false;
        _game.canvasCancel(); // начатый мазок отменяем, идём в зум
      }
      _beginZoom();
    } else if (_pointers.length == 1) {
      _pendingDownPos = e.localPosition;
      _paintDelay?.cancel();
      _paintDelay = Timer(_kPaintHoldOff, _startPendingPaint);
    }
  }

  /// Окно истекло, второй палец не лёг — начинаем покраску с точки касания.
  void _startPendingPaint() {
    _paintDelay = null;
    final pos = _pendingDownPos;
    _pendingDownPos = null;
    if (pos == null || _zooming || _pointers.length != 1) return;
    _painting = true;
    _game.canvasDown(pos);
  }

  /// Сбросить отложенный (ещё не применённый) тап.
  void _cancelPendingPaint() {
    _paintDelay?.cancel();
    _paintDelay = null;
    _pendingDownPos = null;
  }

  void _beginZoom() {
    final pts = _pointers.values.toList();
    if (pts.length < 2) return;
    _zooming = true;
    _zoomStartDist = (pts[0] - pts[1]).distance;
    _game.zoomBegin((pts[0] + pts[1]) / 2);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    if (_zooming && _pointers.length >= 2) {
      final pts = _pointers.values.toList();
      final dist = (pts[0] - pts[1]).distance;
      final focal = (pts[0] + pts[1]) / 2;
      if (_zoomStartDist > 0) _game.zoomUpdate(dist / _zoomStartDist, focal);
    } else if (_painting && _pointers.length == 1) {
      _game.canvasMove(e.localPosition);
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    if (_zooming && _pointers.length < 2) _zooming = false;
    if (_pointers.isEmpty) {
      if (_pendingDownPos != null) {
        // Палец поднят до истечения окна — одиночный тап: красим сейчас.
        final pos = _pendingDownPos!;
        _cancelPendingPaint();
        _game.canvasDown(pos);
        _game.canvasUp();
      } else if (_painting) {
        _painting = false;
        _game.canvasUp();
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (_zooming && _pointers.length < 2) _zooming = false;
    if (_pointers.isEmpty) {
      _cancelPendingPaint(); // отменённый жест — отложенный тап отбрасываем
      if (_painting) {
        _painting = false;
        _game.canvasUp();
      }
    }
  }

  /// Круговой колор-пикер: кольцо оттенков + недавние цвета (последние 10).
  Future<void> _openPicker() async {
    final storage = GameStorage.instance;
    final recent =
        storage.coloringRecentColors.map((int v) => Color(v)).toList();
    final result = await showColoringColorPicker(
      context,
      initial: _game.brushColor,
      recent: recent,
    );
    if (result != null) {
      _game.setPickedColor(result);
      await storage.addColoringRecentColor(result.toARGB32());
    }
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
      picks: _game.allPicks(),
      categories: _game.coloringCategories,
      currentAsset: _game.currentAsset,
      isFavorite: storage.isColoringFavorite,
      onToggleFavorite: storage.toggleColoringFavorite,
      onSelect: (pick) =>
          _game.selectRasterPicture(pick.category, pick.level, pick.asset),
    );
  }

  @override
  void dispose() {
    _paintDelay?.cancel();
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
            // Холст + ввод: 1 палец рисует/заливает, 2 пальца — зум/панорама.
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
                  level: _game.level.value,
                  availableLevels: _game.coloringLevels,
                  onColor: _game.setColor,
                  onPick: _openPicker,
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
