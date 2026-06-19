import 'package:flutter/material.dart';

import '../../core/feedback/haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';

/// Галерея тем оформления: превью-карточки, сгруппированные по категориям.
/// Тап применяет тему сразу (живой реколор всего приложения — экран сам
/// перекрашивается через `context.appColors`), выбранная отмечена галочкой.
class ThemeGalleryScreen extends StatelessWidget {
  const ThemeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final groups = AppThemes.byCategory;

    return Scaffold(
      appBar: AppBar(title: const Text('Тема оформления')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, c) {
            const pad = 14.0;
            const gap = 9.0;
            final tile = (c.maxWidth - pad * 2 - gap * 4) / 5; // 5 в ряд
            return ValueListenableBuilder<String>(
              valueListenable: ThemeController.instance.themeId,
              builder: (context, currentId, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(pad, 8, pad, 28),
                  children: <Widget>[
                    for (final entry in groups.entries) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 16, 2, 10),
                        child: Text(
                          entry.key,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onBackground.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: <Widget>[
                          for (final opt in entry.value)
                            _ThemeCard(
                              option: opt,
                              width: tile,
                              selected: opt.id == currentId,
                              outer: colors,
                              onTap: () {
                                Haptics.select();
                                ThemeController.instance.select(opt.id);
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Компактное превью темы (квадрат, без названия): мазок primary + полоска
/// акцентов (secondary/accent/success) на фоне темы; галочка у выбранной.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.option,
    required this.width,
    required this.selected,
    required this.outer,
    required this.onTap,
  });

  final AppThemeOption option;
  final double width;
  final bool selected;
  final AppColors outer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = option.colors;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: <Widget>[
          Container(
            width: width,
            height: width,
            padding: EdgeInsets.all(width * 0.13),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(width * 0.26),
              border: Border.all(
                color: selected
                    ? outer.primary
                    : outer.onBackground.withValues(alpha: 0.1),
                width: selected ? 3 : 1.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: outer.onBackground.withValues(alpha: 0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                // Крупный мазок основного цвета.
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(width * 0.14),
                    ),
                  ),
                ),
                SizedBox(height: width * 0.09),
                // Полоска акцентов.
                SizedBox(
                  height: width * 0.13,
                  child: Row(
                    children: <Widget>[
                      _bar(c.secondary, width),
                      SizedBox(width: width * 0.06),
                      _bar(c.accent, width),
                      SizedBox(width: width * 0.06),
                      _bar(c.success, width),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: width * 0.05,
              right: width * 0.05,
              child: Container(
                width: width * 0.3,
                height: width * 0.3,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.onPrimary, width: width * 0.025),
                ),
                child: Icon(Icons.check_rounded,
                    size: width * 0.18, color: c.onPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(Color color, double w) => Expanded(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(w * 0.06),
          ),
        ),
      );
}
