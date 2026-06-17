import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Сборка [ThemeData] из палитры [AppColors].
///
/// Вынесено отдельно, чтобы реколор сводился к подмене [AppColors] —
/// см. [AppColors.daylight] и `copyWith`. Тема **светлая** и крупная:
/// большие скруглённые элементы, крупный кегль — под пальцы малышей.
class AppTheme {
  const AppTheme._();

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
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.onBackground,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: Typography.blackMountainView.apply(
        bodyColor: c.onBackground,
        displayColor: c.onBackground,
      ),
    );
  }

  /// Тема по умолчанию — «дневная» (тёплая, яркая).
  static ThemeData get daylight => fromColors(AppColors.daylight);
}
