import 'package:flutter/material.dart';

/// Семантическая палитра приложения «Chisana kodomo».
///
/// Реализована как [ThemeExtension], поэтому живёт прямо в [ThemeData] и
/// меняется вместе с темой (с анимацией через [lerp]). Цель — **5–10 визуальных
/// тем**: каждая тема = один экземпляр [AppColors], смена темы = подмена
/// расширения. Виджеты берут цвета через `context.appColors` и **не хардкодят**
/// конкретные значения — поэтому любая тема применяется автоматически.
///
/// Бренд **тёплый и яркий**, светлый ([Brightness.light]): кремовый фон,
/// коралл/небо/солнце как акценты, мягкий тёмно-коричневый текст вместо чёрного.
@immutable
class AppColors extends ThemeExtension<AppColors> {
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

  /// Тёплый фон под всем экраном.
  final Color background;

  /// Карточки/панели поверх фона.
  final Color surface;

  /// Основной акцент.
  final Color primary;

  /// Вторичный акцент.
  final Color secondary;

  /// Дополнительный акцент.
  final Color accent;

  /// «Правильно/получилось» — поощряющий цвет.
  final Color success;

  /// Текст/иконки на фоне.
  final Color onBackground;

  /// Текст/иконки на карточках.
  final Color onSurface;

  /// Текст/иконки на ярких акцентах.
  final Color onPrimary;

  // ── Палитры тем ─────────────────────────────────────────────────────────
  // Базовая «дневная» — дефолт бренда. Остальные добавляются сюда же; финальный
  // набор 5–10 тем — за дизайном владельца, ниже два образца для проверки смены.

  /// Базовая «дневная» — тёплая и яркая (дефолт).
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

  /// Образец темы «Лужайка» (зелёная). Цвета — черновые, под финализацию.
  static const AppColors meadow = AppColors(
    background: Color(0xFFEEFAE3),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF66BB6A),
    secondary: Color(0xFF4FC3F7),
    accent: Color(0xFFFFCA28),
    success: Color(0xFF43A047),
    onBackground: Color(0xFF33691E),
    onSurface: Color(0xFF33691E),
    onPrimary: Color(0xFFFFFFFF),
  );

  /// Образец темы «Жвачка» (розово-сиреневая). Цвета — черновые, под финализацию.
  static const AppColors bubblegum = AppColors(
    background: Color(0xFFFFF0F6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFF6FAE),
    secondary: Color(0xFF9C6ADE),
    accent: Color(0xFFFFD166),
    success: Color(0xFF7AC74F),
    onBackground: Color(0xFF6A1B4D),
    onSurface: Color(0xFF6A1B4D),
    onPrimary: Color(0xFFFFFFFF),
  );

  @override
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

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
    );
  }
}

/// Быстрый доступ к активной палитре: `context.appColors.primary`.
/// Виджеты используют это вместо хардкода цветов — так работает любая тема.
extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.daylight;
}
