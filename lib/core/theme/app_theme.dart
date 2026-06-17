import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Сборка [ThemeData] из палитры [AppColors] + реестр визуальных тем.
///
/// Реколор сводится к подмене [AppColors]: палитра кладётся в `extensions`,
/// и виджеты читают её через `context.appColors`. Добавить новую тему =
/// добавить запись в [AppThemes.all].
class AppTheme {
  const AppTheme._();

  /// Брендовый шрифт (забандлен). Кириллица есть; для японского — системный
  /// фолбэк. Применяется ко всему тексту приложения.
  static const String _fontFamily = 'Unbounded';

  static ThemeData fromColors(AppColors c) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.secondary,
      onSecondary: c.onPrimary,
      tertiary: c.accent,
      onTertiary: c.onBackground,
      error: const Color(0xFFE57373),
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      fontFamily: _fontFamily,
      extensions: <ThemeExtension<dynamic>>[c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.onBackground,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: Typography.blackMountainView.apply(
        fontFamily: _fontFamily,
        bodyColor: c.onBackground,
        displayColor: c.onBackground,
      ),
    );
  }

  /// Тема по умолчанию — «дневная».
  static ThemeData get daylight => fromColors(AppColors.daylight);
}

/// Одна визуальная тема в реестре: id (для хранения), имя (для UI) и палитра.
@immutable
class AppThemeOption {
  const AppThemeOption({
    required this.id,
    required this.name,
    required this.colors,
  });

  /// Стабильный ключ для сохранения выбора в storage.
  final String id;

  /// Имя для экрана выбора темы.
  final String name;

  /// Палитра темы.
  final AppColors colors;

  /// Готовая [ThemeData] этой темы.
  ThemeData get theme => AppTheme.fromColors(colors);
}

/// Реестр визуальных тем (цель — 5–10). Финальный набор/цвета — за дизайном
/// владельца; пока дефолт + два образца, чтобы смена тем была проверяема.
abstract final class AppThemes {
  static const AppThemeOption daylight = AppThemeOption(
    id: 'daylight',
    name: 'Дневная',
    colors: AppColors.daylight,
  );
  static const AppThemeOption meadow = AppThemeOption(
    id: 'meadow',
    name: 'Лужайка',
    colors: AppColors.meadow,
  );
  static const AppThemeOption bubblegum = AppThemeOption(
    id: 'bubblegum',
    name: 'Жвачка',
    colors: AppColors.bubblegum,
  );

  /// Все темы по порядку (первая — дефолт).
  static const List<AppThemeOption> all = <AppThemeOption>[
    daylight,
    meadow,
    bubblegum,
  ];

  /// Тема по id (или дефолт, если id неизвестен/`null`).
  static AppThemeOption byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => daylight);
}
