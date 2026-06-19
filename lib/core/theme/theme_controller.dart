import 'package:flutter/foundation.dart';

import '../storage/game_storage.dart';

/// Контроллер активной темы оформления.
///
/// Держит id выбранной темы в [ValueNotifier], чтобы корень приложения
/// пересобирал `MaterialApp` при смене (живой реколор), и персистит выбор в
/// [GameStorage]. Цвета берутся через `context.appColors`, поэтому весь UI
/// перекрашивается автоматически (с анимацией через `AppColors.lerp`).
class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  /// id активной темы — для корневого `ValueListenableBuilder`.
  final ValueNotifier<String> themeId = ValueNotifier<String>('daylight');

  /// Подтянуть сохранённый выбор (вызывать в `main` после `GameStorage.init`).
  void load() => themeId.value = GameStorage.instance.themeId;

  /// Выбрать тему: применить (нотифаер) + сохранить. Повтор — без эффекта.
  void select(String id) {
    if (themeId.value == id) return;
    themeId.value = id;
    GameStorage.instance.setThemeId(id);
  }
}
