// Smoke-тесты: первый запуск показывает экран согласия; после согласия —
// лобби-витрина. Оба без ошибок.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chisana_kodomo/core/storage/game_storage.dart';
import 'package:chisana_kodomo/main.dart';

Future<void> _initStorage(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  GameStorage.debugReset();
  await GameStorage.init();
}

void _portrait(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Первый запуск: экран согласия', (WidgetTester tester) async {
    _portrait(tester);
    await _initStorage(<String, Object>{}); // согласия ещё нет
    await tester.pumpWidget(const ChisanaKodomoApp());

    expect(find.text('Хорошо!'), findsOneWidget);
    expect(find.text('Счёт'), findsNothing);
  });

  testWidgets('После согласия — лобби: бренд + витрина игр',
      (WidgetTester tester) async {
    _portrait(tester);
    await _initStorage(<String, Object>{'consent_accepted_v1': true});
    await tester.pumpWidget(const ChisanaKodomoApp());

    expect(find.textContaining('Chisana'), findsOneWidget);
    expect(find.text('Счёт'), findsOneWidget);
    expect(find.text('Музыка'), findsOneWidget);
  });
}
