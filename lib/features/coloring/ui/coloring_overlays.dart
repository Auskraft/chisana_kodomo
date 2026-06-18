import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../game/coloring_pictures.dart';
import '../logic/coloring_logic.dart';

String _modeLabel(ColoringMode m) {
  switch (m) {
    case ColoringMode.fill:
      return 'Раскрасить';
    case ColoringMode.byNumber:
      return 'По номерам';
    case ColoringMode.freeDraw:
      return 'Рисовать';
  }
}

/// Арт-иконка режима для таб-бара (подпись — в Semantics, визуально без текста).
/// Клеевидные PNG в общем стиле нав-иконок (`assets/ui/`).
String _modeAsset(ColoringMode m) {
  switch (m) {
    case ColoringMode.fill:
      return 'assets/ui/mode_paint.png';
    case ColoringMode.byNumber:
      return 'assets/ui/mode_numbers.png';
    case ColoringMode.freeDraw:
      return 'assets/ui/mode_draw.png';
  }
}

/// Верхняя панель: «домой» + переключатель режима + замок. При включённом
/// «детском замке» прячем всё, кроме «держи, чтобы открыть» (малыш не выйдет).
class ColoringTopBar extends StatelessWidget {
  const ColoringTopBar({
    super.key,
    required this.mode,
    required this.onMode,
    required this.onHome,
    required this.locked,
    required this.onLock,
    required this.onUnlock,
  });

  final ColoringMode mode;
  final ValueChanged<ColoringMode> onMode;
  final VoidCallback onHome;
  final bool locked;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (locked) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _HoldToUnlock(colors: colors, onUnlock: onUnlock),
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            _NavIconBtn(asset: 'assets/ui/home.png', onTap: onHome),
            // Центр: таб-бар режимов (выбор тематики переехал в пикер картинок).
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _ModeTabs(mode: mode, colors: colors, onMode: onMode),
                ],
              ),
            ),
            _NavIconBtn(asset: 'assets/ui/lock.png', onTap: onLock),
          ],
        ),
      ),
    );
  }
}

/// «Держи, чтобы открыть»: удержание ~1.8 с снимает детский замок (родителю
/// легко, малышу — трудно). Кольцо-прогресс рисуется вокруг замочка. Слушаем
/// сырые pointer-события (Listener), чтобы лёгкое смещение пальца не сбрасывало.
class _HoldToUnlock extends StatefulWidget {
  const _HoldToUnlock({required this.colors, required this.onUnlock});

  final AppColors colors;
  final VoidCallback onUnlock;

  @override
  State<_HoldToUnlock> createState() => _HoldToUnlockState();
}

class _HoldToUnlockState extends State<_HoldToUnlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) {
        widget.onUnlock();
        _c.reset();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Listener(
      onPointerDown: (_) => _c.forward(),
      onPointerUp: (_) => _c.reverse(),
      onPointerCancel: (_) => _c.reverse(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 26,
              height: 26,
              child: AnimatedBuilder(
                animation: _c,
                builder: (BuildContext context, Widget? child) => Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (_c.value > 0)
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          value: _c.value,
                          strokeWidth: 3,
                          color: colors.primary,
                          backgroundColor:
                              colors.onSurface.withValues(alpha: 0.12),
                        ),
                      ),
                    Icon(Icons.lock_rounded,
                        size: 16, color: colors.onSurface.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Держи, чтобы открыть',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Выбор уровня сложности временно скрыт (по просьбе владельца) — поставь
/// `true`, чтобы вернуть. Намеренно `final`, а не `const`: при `const false`
/// анализатор счёл бы ветку мёртвым кодом, а `_LevelChip` — неиспользуемым.
final bool _showLevelSelector = false;

/// Нижняя панель: палитра + действия (заново / следующая картинка).
class ColoringBottomBar extends StatelessWidget {
  const ColoringBottomBar({
    super.key,
    required this.mode,
    required this.selectedColor,
    required this.pickedColor,
    required this.level,
    required this.availableLevels,
    required this.onColor,
    required this.onPick,
    required this.onLevel,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onPicture,
    required this.paintTool,
    required this.onTool,
    required this.brushSize,
    required this.onBrushSize,
    required this.showTools,
    required this.locked,
  });

  final ColoringMode mode;
  final int selectedColor;
  final Color? pickedColor;
  final int level;
  final List<int> availableLevels;
  final ValueChanged<int> onColor;
  final VoidCallback onPick;
  final ValueChanged<int> onLevel;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  /// Действие кнопки «Картинка»: открыть пикер (растровые) или следующая (вектор).
  final VoidCallback onPicture;

  /// Активный инструмент и толщина мазка (режим «Раскрасить»).
  final PaintTool paintTool;
  final ValueChanged<PaintTool> onTool;
  final int brushSize;
  final ValueChanged<int> onBrushSize;

  /// Показывать ряд инструментов (есть растровая картинка для рисования).
  final bool showTools;

  /// «Детский замок»: прячем навигацию/деструктив (инструменты/темы/уровни/Заново/
  /// Картинка), оставляем палитру и отмену/возврат — малыш продолжает раскрашивать.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Видимость действий: при замке прячем «Заново»/«Картинка», «Картинку» —
    // ещё и в свободном рисовании (там картинки нет). Разделитель — если есть
    // хоть одно действие после стрелок.
    final showClear = !locked;
    final showPicture = !locked && mode != ColoringMode.freeDraw;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 14),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(26),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // Компоновка в две колонки (по макету владельца): слева — инструменты
        // и цвета, справа — стрелки (отмена/возврат) и действия (Заново/Картинка)
        // круглыми кнопками.
        child: Row(
          children: <Widget>[
            // ── Левая колонка: инструменты + палитра ─────────────────────────
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (!locked && mode == ColoringMode.fill) ...<Widget>[
                    // Инструменты (Заливка/Маркер/Акварель/Карандашик) — без
                    // подписей (иконки); кастомные владелец даст позже.
                    if (showTools) ...<Widget>[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final t in _toolOrder)
                            _ToolIconBtn(
                              tool: t,
                              selected: t == paintTool,
                              colors: colors,
                              onTap: () => onTool(t),
                            ),
                        ],
                      ),
                      if (paintTool != PaintTool.fill) ...<Widget>[
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Text(
                                'Толщина',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: colors.onSurface.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            for (var i = 0; i < 3; i++)
                              _ThickDot(
                                dot: 8.0 + i * 6,
                                selected: i == brushSize,
                                colors: colors,
                                onTap: () => onBrushSize(i),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],
                    // Тема ушла в шапку (капсула «Тематика»).
                    // Уровень сложности временно скрыт (флаг _showLevelSelector выше).
                    if (_showLevelSelector && availableLevels.length >= 2) ...<Widget>[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              'Уровень',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: colors.onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          for (var l = 1; l <= 5; l++)
                            _LevelChip(
                              n: l,
                              selected: l == level,
                              enabled: availableLevels.contains(l),
                              colors: colors,
                              onTap: () => onLevel(l),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                  // Палитра + колор-пикер (последним в ряду).
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (var i = 0; i < kColoringPalette.length; i++)
                        _Swatch(
                          index: i,
                          color: kColoringPalette[i],
                          selected: pickedColor == null && i == selectedColor,
                          showNumber: mode == ColoringMode.byNumber,
                          colors: colors,
                          onTap: () => onColor(i),
                        ),
                      if (mode != ColoringMode.byNumber)
                        _PickerSwatch(
                          active: pickedColor != null,
                          color: pickedColor,
                          colors: colors,
                          onTap: onPick,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Правая колонка: стрелки (сверху) + действия (снизу) ──────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _NavIconBtn(asset: 'assets/ui/back.png', onTap: onUndo),
                    const SizedBox(width: 8),
                    _NavIconBtn(asset: 'assets/ui/forward.png', onTap: onRedo),
                  ],
                ),
                if (showClear || showPicture) ...<Widget>[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (showClear)
                        _NavIconBtn(asset: 'assets/ui/restart.png', onTap: onClear),
                      if (showClear && showPicture) const SizedBox(width: 8),
                      if (showPicture)
                        _NavIconBtn(asset: 'assets/ui/pictures.png', onTap: onPicture),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Переключатель режимов раскраски — сегментированный таб-бар: три иконки без
/// подписей в одной «пилюле», активная на заливке [primary]. Названия режимов
/// уходят в Semantics (доступность сохранена), визуально — только иконки.
class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.mode,
    required this.colors,
    required this.onMode,
  });

  final ColoringMode mode;
  final AppColors colors;
  final ValueChanged<ColoringMode> onMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.onBackground.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final m in ColoringMode.values)
            _ModeTab(
              mode: m,
              selected: m == mode,
              colors: colors,
              onTap: () => onMode(m),
            ),
        ],
      ),
    );
  }
}

/// Один сегмент таб-бара: крупная иконка-кнопка (тап-цель 56×44 для малыша),
/// активный режим — на заливке [primary], смена подсвечивается анимацией.
class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.mode,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final ColoringMode mode;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _modeLabel(mode),
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque, // вся плитка тапается, не только иконка
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 56,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: selected ? 1.0 : 0.45,
            child: Image.asset(_modeAsset(mode), width: 34, height: 34),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.index,
    required this.color,
    required this.selected,
    required this.showNumber,
    required this.colors,
    required this.onTap,
  });

  final int index;
  final Color color;
  final bool selected;
  final bool showNumber;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? colors.onSurface : Colors.white.withValues(alpha: 0.8),
            width: selected ? 4 : 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.18),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: showNumber
            ? Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  shadows: <Shadow>[Shadow(color: Colors.black38, blurRadius: 2)],
                ),
              )
            : null,
      ),
    );
  }
}

class _PickerSwatch extends StatelessWidget {
  const _PickerSwatch({
    required this.active,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  final bool active;
  final Color? color;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          gradient: color == null
              ? const SweepGradient(colors: <Color>[
                  Color(0xFFE53935),
                  Color(0xFFFFEB3B),
                  Color(0xFF66BB6A),
                  Color(0xFF42A5F5),
                  Color(0xFFAB47BC),
                  Color(0xFFE53935),
                ])
              : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? colors.onSurface : Colors.white.withValues(alpha: 0.8),
            width: active ? 4 : 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.onBackground.withValues(alpha: 0.18),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(Icons.colorize_rounded, size: 18, color: Colors.white.withValues(alpha: 0.95)),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.n,
    required this.selected,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  final int n;
  final bool selected;
  final bool enabled;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.primary : colors.onSurface.withValues(alpha: 0.15),
              width: 2,
            ),
          ),
          child: Text(
            '$n',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? colors.onPrimary : colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

/// Набор и порядок инструментов в панели (по просьбе владельца). Гуашь
/// временно убрана — вернуть = добавить `PaintTool.gouache` в список. Сам enum
/// `PaintTool` и логика мазков во Flame не тронуты.
const List<PaintTool> _toolOrder = <PaintTool>[
  PaintTool.fill,
  PaintTool.marker,
  PaintTool.watercolor,
  PaintTool.pencil,
];

/// Иконка + подпись инструмента раскрашивания.
({IconData icon, String label}) _toolMeta(PaintTool t) {
  switch (t) {
    case PaintTool.fill:
      return (icon: Icons.format_color_fill_rounded, label: 'Заливка');
    case PaintTool.pencil:
      return (icon: Icons.edit_rounded, label: 'Карандашик');
    case PaintTool.marker:
      return (icon: Icons.brush_rounded, label: 'Маркер');
    case PaintTool.watercolor:
      return (icon: Icons.water_drop_rounded, label: 'Акварель');
    case PaintTool.gouache:
      return (icon: Icons.format_paint_rounded, label: 'Гуашь');
  }
}

/// Иконка-кнопка инструмента (без подписи): белая плитка, активный — на заливке
/// [primary]. Название уходит в Semantics (доступность). Кастомные иконки —
/// позже, меняются в [_toolMeta].
class _ToolIconBtn extends StatelessWidget {
  const _ToolIconBtn({
    required this.tool,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final PaintTool tool;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _toolMeta(tool);
    final fg =
        selected ? colors.onPrimary : colors.onSurface.withValues(alpha: 0.65);
    return Semantics(
      label: meta.label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Icon(meta.icon, size: 22, color: fg),
        ),
      ),
    );
  }
}

/// Кружок выбора толщины: точка растёт с размером.
class _ThickDot extends StatelessWidget {
  const _ThickDot({
    required this.dot,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final double dot;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.18) : colors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        child: Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            color: colors.onSurface.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Круглая нав-кнопка из картинки (назад/вперёд) — без Material-подложки.
class _NavIconBtn extends StatelessWidget {
  const _NavIconBtn({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Image.asset(asset, width: 44, height: 44),
      ),
    );
  }
}

// (Круглые кнопки `_RoundBtn`/`_RoundActionBtn` заменены на `_NavIconBtn` с
// самодостаточными клеевидными PNG-иконками `assets/ui/`.)

/// Открыть пикер картинок по кнопке «Картинка»: bottom sheet с сеткой миниатюр,
/// сгруппированных по сложности (заголовки «Сложность №N»). Тап по карточке —
/// выбрать, сердечко — в избранное; [currentAsset] подсвечивается рамкой.
Future<void> showColoringPicturePicker(
  BuildContext context, {
  required List<ColoringPick> picks,
  required List<String> categories,
  required String? currentAsset,
  required bool Function(String asset) isFavorite,
  required Future<void> Function(String asset) onToggleFavorite,
  required void Function(ColoringPick pick) onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PicturePickerSheet(
      picks: picks,
      categories: categories,
      currentAsset: currentAsset,
      isFavorite: isFavorite,
      onToggleFavorite: onToggleFavorite,
      onSelect: (pick) {
        Navigator.of(ctx).pop();
        onSelect(pick);
      },
    ),
  );
}

class _PicturePickerSheet extends StatefulWidget {
  const _PicturePickerSheet({
    required this.picks,
    required this.categories,
    required this.currentAsset,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onSelect,
  });

  final List<ColoringPick> picks;
  final List<String> categories;
  final String? currentAsset;
  final bool Function(String asset) isFavorite;
  final Future<void> Function(String asset) onToggleFavorite;
  final void Function(ColoringPick pick) onSelect;

  @override
  State<_PicturePickerSheet> createState() => _PicturePickerSheetState();
}

class _PicturePickerSheetState extends State<_PicturePickerSheet> {
  // Выбранный таб тематики: null = «Все» (по умолчанию), иначе ключ темы.
  String? _tab;
  // Фильтр «только избранное»: показывает любимые из всех тем (взаимоисключающий
  // с табами тем).
  bool _favOnly = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final showTabs = widget.categories.length >= 2;
    final hasFav = widget.picks.any((p) => widget.isFavorite(p.asset));

    // Фильтр (избранное / тема / все), затем группировка по уровню сложности.
    final shown = _favOnly
        ? widget.picks.where((p) => widget.isFavorite(p.asset)).toList()
        : _tab == null
            ? widget.picks
            : widget.picks.where((p) => p.category == _tab).toList();
    final byLevel = <int, List<ColoringPick>>{};
    for (final p in shown) {
      (byLevel[p.level] ??= <ColoringPick>[]).add(p);
    }
    final levels = byLevel.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.onBackground.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                // ── Закреплённая шапка: хваталка, заголовок, табы тематик ──────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colors.onSurface.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Выбери картинку',
                        textAlign: TextAlign.center,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      if (showTabs || hasFav || _favOnly) ...<Widget>[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              _PickerThemeTab(
                                label: 'Все',
                                selected: !_favOnly && _tab == null,
                                colors: colors,
                                onTap: () => setState(() {
                                  _favOnly = false;
                                  _tab = null;
                                }),
                              ),
                              // ❤ — только избранное (из всех тем).
                              if (hasFav || _favOnly)
                                _PickerThemeTab(
                                  iconAsset: 'assets/ui/favorite.png',
                                  selected: _favOnly,
                                  colors: colors,
                                  onTap: () => setState(() => _favOnly = true),
                                ),
                              if (showTabs)
                                for (final c in widget.categories)
                                  _PickerThemeTab(
                                    emoji: coloringCategoryMeta(c).emoji,
                                    selected: !_favOnly && _tab == c,
                                    colors: colors,
                                    onTap: () => setState(() {
                                      _favOnly = false;
                                      _tab = c;
                                    }),
                                  ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                // ── Сетка превью по уровням сложности (скролл) ────────────────
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    children: <Widget>[
                      // Пусто (обычно — пустой таб «избранное»): подсказка.
                      if (levels.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 36),
                          child: Column(
                            children: <Widget>[
                              Opacity(
                                opacity: 0.4,
                                child: Image.asset('assets/ui/favorite.png',
                                    width: 48, height: 48),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Пока нет любимых раскрасок.\nНажми сердечко на картинке, чтобы добавить.',
                                textAlign: TextAlign.center,
                                style: text.titleSmall?.copyWith(
                                  color: colors.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final level in levels) ...<Widget>[
                        _LevelHeader(
                          level: level,
                          count: byLevel[level]!.length,
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        GridView.extent(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          maxCrossAxisExtent: 118,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.86,
                          children: <Widget>[
                            for (final pick in byLevel[level]!)
                              _PicturePickerCard(
                                pick: pick,
                                selected: pick.asset == widget.currentAsset,
                                favorite: widget.isFavorite(pick.asset),
                                colors: colors,
                                onTap: () => widget.onSelect(pick),
                                onToggleFavorite: () async {
                                  await widget.onToggleFavorite(pick.asset);
                                  if (mounted) setState(() {});
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Таб тематики в пикере: «Все» (текст) или иконка-эмодзи темы. Стиль — именно
/// таб (а не чип): без рамки/заливки, активный отмечен подчёркиванием-индикатором
/// [primary], неактивный приглушён. Содержимое центрировано по высоте; список
/// горизонтально скроллится (тем может быть больше). Эмодзи — из [coloringCategoryMeta].
class _PickerThemeTab extends StatelessWidget {
  const _PickerThemeTab({
    this.label,
    this.emoji,
    this.iconAsset,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String? label;
  final String? emoji;
  final String? iconAsset;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Контент в фиксированной высоте → все табы вровень, центрированы.
            SizedBox(
              height: 30,
              child: Center(
                child: iconAsset != null
                    ? Opacity(
                        opacity: selected ? 1.0 : 0.45,
                        child: Image.asset(iconAsset!, width: 24, height: 24),
                      )
                    : emoji != null
                        ? Opacity(
                            opacity: selected ? 1.0 : 0.45,
                            child: Text(emoji!,
                                style: const TextStyle(fontSize: 24)),
                          )
                        : Text(
                            label ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: selected
                                      ? colors.primary
                                      : colors.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
              ),
            ),
            const SizedBox(height: 5),
            // Индикатор-подчёркивание активного таба.
            Container(
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: selected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Заголовок секции уровня в пикере: бейдж-номер + «Сложность №N» + счётчик.
class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.level,
    required this.count,
    required this.colors,
  });

  final int level;
  final int count;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$level',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Сложность №$level',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

/// Карточка-миниатюра в пикере (заполняет ячейку сетки): картинка на белом
/// листе + сердечко избранного. Уровень — в заголовке секции, поэтому бейджа
/// уровня тут нет. Тап по карточке — выбрать, по сердечку — переключить.
class _PicturePickerCard extends StatelessWidget {
  const _PicturePickerCard({
    required this.pick,
    required this.selected,
    required this.favorite,
    required this.colors,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final ColoringPick pick;
  final bool selected;
  final bool favorite;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.12),
                  width: selected ? 3 : 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colors.onBackground.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(pick.asset, fit: BoxFit.contain, cacheWidth: 300),
            ),
          ),
          // Сердечко (избранное): полное при выборе, бледное иначе.
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: onToggleFavorite,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Opacity(
                  opacity: favorite ? 1.0 : 0.3,
                  child: Image.asset('assets/ui/favorite.png',
                      width: 24, height: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
