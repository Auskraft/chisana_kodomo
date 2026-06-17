// Базовый smoke-тест: приложение бутит в лобби-заглушку без ошибок.

import 'package:flutter_test/flutter_test.dart';

import 'package:chisana_kodomo/main.dart';

void main() {
  testWidgets('Лобби бутится и показывает бренд + тизеры игр',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ChisanaKodomoApp());

    // Бренд на месте.
    expect(find.text('Chisana kodomo'), findsOneWidget);
    expect(find.text('ちいさなこども'), findsOneWidget);

    // Тизеры будущих игр отрисованы.
    expect(find.text('Счёт'), findsOneWidget);
    expect(find.text('Музыка'), findsOneWidget);
  });
}
