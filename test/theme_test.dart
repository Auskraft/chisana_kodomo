import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chisana_kodomo/core/storage/game_storage.dart';
import 'package:chisana_kodomo/core/theme/app_theme.dart';
import 'package:chisana_kodomo/core/theme/theme_controller.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppThemes', () {
    test('базовые + портированные; id уникальны', () {
      expect(AppThemes.all.length, greaterThan(3)); // 3 базовых + портированные
      final ids = AppThemes.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'дубли id тем');
    });

    test('byId: известный id, неизвестный/null → дефолт', () {
      expect(AppThemes.byId('daylight').id, 'daylight');
      expect(AppThemes.byId('meadow').id, 'meadow');
      expect(AppThemes.byId('нет такой').id, 'daylight');
      expect(AppThemes.byId(null).id, 'daylight');
    });

    test('каждая тема — светлая и с читаемым текстом', () {
      for (final t in AppThemes.all) {
        final c = t.colors;
        expect(c.background.computeLuminance(), greaterThan(0.7),
            reason: 'тема ${t.id}: фон не светлый');
        // Текст на фоне и на карточке — уверенно читаемый.
        expect(_contrast(c.onBackground, c.background), greaterThan(3.0),
            reason: 'тема ${t.id}: слабый контраст текст/фон');
        expect(_contrast(c.onSurface, c.surface), greaterThan(3.0),
            reason: 'тема ${t.id}: слабый контраст текст/карточка');
      }
    });

    test('производные поверхности card/chip: текст уверенно читается', () {
      for (final t in AppThemes.all) {
        final c = t.colors;
        expect(_contrast(c.onSurface, c.card), greaterThan(3.0),
            reason: 'card ${t.id}');
        expect(_contrast(c.onSurface, c.chip), greaterThan(3.0),
            reason: 'chip ${t.id}');
      }
    });

    test('byCategory: суммарно = все темы, первая группа — Базовые', () {
      final groups = AppThemes.byCategory;
      final total = groups.values.fold<int>(0, (a, g) => a + g.length);
      expect(total, AppThemes.all.length);
      expect(groups.keys.first, 'Базовые');
    });
  });

  group('ThemeController', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{'theme_id': 'meadow'});
      GameStorage.debugReset();
      await GameStorage.init();
    });

    test('load берёт сохранённую тему; select меняет и персистит', () {
      final ctrl = ThemeController.instance;
      ctrl.load();
      expect(ctrl.themeId.value, 'meadow');

      ctrl.select('bubblegum');
      expect(ctrl.themeId.value, 'bubblegum');
      expect(GameStorage.instance.themeId, 'bubblegum');
    });
  });
}
