import 'package:flutter/material.dart';

/// Палитра приложения «Chisana kodomo».
///
/// Все цвета собраны в одном месте, чтобы при необходимости поддержать «реколор»
/// (тема/сезонный скин). Бренд — **тёплый и яркий**, дружелюбный для малышей
/// 3–6 лет: кремовый фон, коралл/небо/солнце как акценты, мягкий тёмно-коричневый
/// текст вместо чёрного. Светлая тема ([Brightness.light]).
class AppColors {
  const AppColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.onBackground,
    required this.onSurface,
    required this.onPrimary,
  });

  /// Тёплый кремовый фон.
  final Color background;

  /// Белые карточки/панели поверх фона.
  final Color surface;

  /// Основной акцент — тёплый коралл.
  final Color primary;

  /// Вторичный акцент — небесно-голубой.
  final Color secondary;

  /// Дополнительный акцент — солнечный янтарь.
  final Color accent;

  /// «Правильно/получилось» — мягкий зелёный (поощрение).
  final Color success;

  /// Текст/иконки на фоне (мягкий тёмно-коричневый, не чёрный).
  final Color onBackground;

  /// Текст/иконки на карточках.
  final Color onSurface;

  /// Текст/иконки на ярких акцентах.
  final Color onPrimary;

  /// Базовая «дневная» палитра — тёплая и яркая.
  static const AppColors daylight = AppColors(
    background: Color(0xFFFFF6EC),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFF8A5B),
    secondary: Color(0xFF4FC3F7),
    accent: Color(0xFFFFCA28),
    success: Color(0xFF7AC74F),
    onBackground: Color(0xFF4E342E),
    onSurface: Color(0xFF4E342E),
    onPrimary: Color(0xFFFFFFFF),
  );

  /// Заготовка под реколор: копия палитры с заменёнными цветами.
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? success,
    Color? onBackground,
    Color? onSurface,
    Color? onPrimary,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      onBackground: onBackground ?? this.onBackground,
      onSurface: onSurface ?? this.onSurface,
      onPrimary: onPrimary ?? this.onPrimary,
    );
  }
}
