// Базовый smoke-тест: приложение бутится в лобби-витрину без ошибок.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chisana_kodomo/core/storage/game_storage.dart';
import 'package:chisana_kodomo/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameStorage.debugReset();
    await GameStorage.init();
  });

  testWidgets('Лобби бутится: бренд + витрина игр', (WidgetTester tester) async {
    // Портретный экран (приложение залочено в портрет).
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChisanaKodomoApp());

    // Бренд и тизеры игр на месте.
    expect(find.textContaining('Chisana'), findsOneWidget);
    expect(find.text('Счёт'), findsOneWidget);
    expect(find.text('Музыка'), findsOneWidget);
  });
}
