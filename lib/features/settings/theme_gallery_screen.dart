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
            const pad = 16.0;
            const gap = 12.0;
            final tile = (c.maxWidth - pad * 2 - gap * 2) / 3; // 3 в ряд
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

/// Мини-превью темы: фон + карточка + «кнопка» + точки-акценты, имя снизу.
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
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: width * 1.2,
              padding: EdgeInsets.all(width * 0.1),
              decoration: BoxDecoration(
                color: c.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? outer.primary
                      : outer.onBackground.withValues(alpha: 0.1),
                  width: selected ? 3 : 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: outer.onBackground.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Мини-карточка (surface).
                  Container(
                    height: width * 0.17,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const Spacer(),
                  // «Кнопка» (primary) с текстом onPrimary.
                  Container(
                    height: width * 0.21,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'Аа',
                      style: TextStyle(
                        color: c.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: width * 0.11,
                      ),
                    ),
                  ),
                  SizedBox(height: width * 0.08),
                  // Точки-акценты + галочка выбранного.
                  Row(
                    children: <Widget>[
                      _dot(c.secondary, width),
                      SizedBox(width: width * 0.05),
                      _dot(c.accent, width),
                      SizedBox(width: width * 0.05),
                      _dot(c.success, width),
                      const Spacer(),
                      if (selected)
                        Icon(Icons.check_circle_rounded,
                            size: width * 0.17, color: c.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: outer.onBackground.withValues(alpha: selected ? 1 : 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color, double w) => Container(
        width: w * 0.11,
        height: w * 0.11,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
