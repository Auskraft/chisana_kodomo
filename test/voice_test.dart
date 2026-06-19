import 'package:flutter_test/flutter_test.dart';
import 'package:chisana_kodomo/core/voice/voice.dart';

void main() {
  group('Voice.clipKey (FNV-1a) — зеркало fnv1a в tool/gen_voice_pack.py', () {
    // Эталоны посчитаны Python-генератором. Если расходится — клипы
    // композиционных фраз («Где собачка?»…) не найдутся в приложении, и оно
    // молча уйдёт на TTS. Тест ловит рассинхрон Dart↔Python хешей.
    const cases = <String, String>{
      'Где собачка?': 'e596875149ee9495',
      'Это цифра три!': '9bd9d3cbc54c708b',
      'Где жёлтая звезда?': '6759aa057c1aa041',
      'Собачка!': 'd10e38c1363cc988',
      'Сколько получилось? Найди цифру десять!': '09ec565cb4622e9c',
    };
    cases.forEach((text, expected) {
      test('«$text» → $expected', () {
        expect(Voice.clipKey(text), expected);
      });
    });

    test('16 hex-символов, детерминирован', () {
      final k = Voice.clipKey('Где мишка?');
      expect(k, hasLength(16));
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(k), isTrue);
      expect(Voice.clipKey('Где мишка?'), k);
    });
  });
}
