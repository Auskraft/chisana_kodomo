import 'dart:async';

import 'package:flutter/services.dart';

/// Мягкая тактильная отдача на события — отклик «в руке».
///
/// Для детского приложения вибрация **деликатная**: лёгкие импульсы на касания
/// и нежный «успех», без резких тяжёлых ударов. Единый флаг [enabled]
/// (синхронизируется с настройкой в `GameStorage`).
class Haptics {
  const Haptics._();

  static bool enabled = true;

  /// Лёгкое касание (тап по объекту/кнопке).
  static void tap() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Выбор/переключение.
  static void select() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Нежный «успех»: два лёгких импульса («тук-тук») — без тяжёлого удара,
  /// чтобы поощрение ощущалось мягко.
  static void success() {
    if (!enabled) return;
    unawaited(_successPattern());
  }

  static Future<void> _successPattern() async {
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    HapticFeedback.mediumImpact();
  }
}
